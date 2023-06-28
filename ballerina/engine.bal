// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import graphql.parser;

import ballerina/jballerina.java;
import ballerina/uuid;

isolated class Engine {
    private final readonly & __Schema schema;
    private final int? maxQueryDepth;
    private final readonly & (readonly & Interceptor)[] interceptors;
    private final readonly & boolean introspection;
    private final readonly & boolean validation;

    isolated function init(string schemaString, int? maxQueryDepth, Service s,
                           readonly & (readonly & Interceptor)[] interceptors, boolean introspection,
                           boolean validation)
    returns Error? {
        if maxQueryDepth is int && maxQueryDepth < 1 {
            return error Error("Max query depth value must be a positive integer");
        }
        self.maxQueryDepth = maxQueryDepth;
        self.schema = check createSchema(schemaString);
        self.interceptors = interceptors;
        self.introspection = introspection;
        self.validation = validation;
        self.addService(s);
    }

    isolated function getSchema() returns readonly & __Schema {
        return self.schema;
    }

    isolated function getInterceptors() returns (readonly & Interceptor)[] {
        return self.interceptors;
    }

    isolated function getValidation() returns readonly & boolean {
        return self.validation;
    }

    isolated function validate(string documentString, string? operationName, map<json>? variables)
        returns parser:OperationNode|OutputObject {

        ParseResult|OutputObject result = self.parse(documentString);
        if result is OutputObject {
            return result;
        }

        OutputObject|parser:DocumentNode validationResult = self.validateDocument(result, operationName, variables);
        if validationResult is OutputObject {
            return validationResult;
        }
        // Since unused operation nodes are removed from the Document node, it includes only the operation node
        // related to the currently executing operation. Hence directly access that node from here.
        return validationResult.getOperations()[0];
    }

    isolated function getResult(parser:OperationNode operationNode, Context context, any|error result = ())
    returns OutputObject {
        map<()> removedNodes = {};
        map<parser:SelectionNode> modifiedSelections = {};
        DefaultDirectiveProcessorVisitor defaultDirectiveProcessor = new (self.schema, removedNodes);
        DuplicateFieldRemoverVisitor duplicateFieldRemover = new (removedNodes, modifiedSelections);

        parser:Visitor[] updatingVisitors = [
            defaultDirectiveProcessor,
            duplicateFieldRemover
        ];

        foreach parser:Visitor visitor in updatingVisitors {
            operationNode.accept(visitor);
        }

        ErrorDetail[]? errors = duplicateFieldRemover.getErrors();
        if errors is ErrorDetail[] {
            return getOutputObjectFromErrorDetail(errors);
        }

        OperationNodeModifierVisitor operationNodeModifier = new (modifiedSelections, removedNodes);
        operationNode.accept(operationNodeModifier);
        parser:OperationNode modifiedOperationNode = operationNodeModifier.getOperationNode();

        ExecutorVisitor executor = new (self, self.schema, context, result);
        modifiedOperationNode.accept(executor);
        OutputObject outputObject = executor.getOutput();
        ResponseFormatter responseFormatter = new (self.schema);
        return responseFormatter.getCoercedOutputObject(outputObject, modifiedOperationNode);
    }

    isolated function parse(string documentString) returns ParseResult|OutputObject {
        parser:Parser parser = new (documentString);
        parser:DocumentNode|parser:Error parseResult = parser.parse();
        if parseResult is parser:DocumentNode {
            return {document: parseResult, validationErrors: parser.getErrors()};
        }
        ErrorDetail errorDetail = getErrorDetailFromError(<parser:Error>parseResult);
        return getOutputObjectFromErrorDetail(errorDetail);
    }

    isolated function validateDocument(ParseResult parseResult, string? operationName, map<json>? variables)
    returns OutputObject|parser:DocumentNode {
        ErrorDetail[]|NodeModifierContext validationResult =
            self.parallellyValidateDocument(parseResult, operationName, variables);
        if validationResult is ErrorDetail[] {
            return getOutputObjectFromErrorDetail(validationResult);
        } else {
            DocumentNodeModifierVisitor documentNodeModifierVisitor = new (validationResult);
            parseResult.document.accept(documentNodeModifierVisitor);
            return documentNodeModifierVisitor.getDocumentNode();
        }
    }

    isolated function parallellyValidateDocument(ParseResult parseResult, string? operationName, map<json>? variables)
    returns ErrorDetail[]|NodeModifierContext {
        parser:DocumentNode document = parseResult.document;
        ErrorDetail[] validationErrors = [...parseResult.validationErrors];

        ErrorDetail|parser:OperationNode operationNode = self.getOperation(document, operationName);
        if operationNode is ErrorDetail {
            return [operationNode];
        }

        map<parser:FragmentNode> fragments = document.getFragments();
        final NodeModifierContext nodeModifierContext = new;
        ValidatorVisitor[] validators = [
            new FragmentCycleFinderVisitor(fragments, nodeModifierContext),
            new FragmentValidatorVisitor(fragments, nodeModifierContext)
        ];

        foreach ValidatorVisitor validator in validators {
            document.accept(validator);
            ErrorDetail[]? errors = validator.getErrors();
            if errors is ErrorDetail[] {
                validationErrors.push(...errors);
            }
        }

        final int? maxQueryDepth = self.maxQueryDepth;
        final readonly & __Schema schema = self.schema;
        final readonly & map<json>? vars = variables.cloneReadOnly();
        final boolean introspection = self.introspection;

        map<parser:OperationNode> operations = {};
        operations[operationNode.getName()] = operationNode;
        final parser:DocumentNode modifiedDocument = document.modifyWith(operations, document.getFragments());
        parseResult.document = modifiedDocument;

        worker queryDepthValidatorWorker returns ErrorDetail[] {
            QueryDepthValidatorVisitor validator = new (maxQueryDepth, nodeModifierContext);
            modifiedDocument.accept(validator);
            return validator.getErrors() ?: [];
        }

        worker subscriptionValidatorWorker returns ErrorDetail[] {
            SubscriptionValidatorVisitor validator = new (nodeModifierContext);
            modifiedDocument.accept(validator);
            return validator.getErrors() ?: [];
        }

        worker directiveValidatorWorker returns ErrorDetail[] {
            DirectiveValidatorVisitor validator = new (schema, nodeModifierContext);
            modifiedDocument.accept(validator);
            return validator.getErrors() ?: [];
        }

        worker fieldAndVariableValidatorWorker returns ErrorDetail[] {
            ErrorDetail[] errors = [];
             ValidatorVisitor[] validatorVisitors = [
                new VariableValidatorVisitor(schema, vars, nodeModifierContext),
                new FieldValidatorVisitor(schema, nodeModifierContext)
            ];
            foreach ValidatorVisitor validator in validatorVisitors {
                modifiedDocument.accept(validator);
                ErrorDetail[]? visitorErrors = validator.getErrors();
                if visitorErrors is ErrorDetail[] {
                    errors.push(...visitorErrors);
                }
            }
            return errors;
        }

        worker introspectionValidatorWorker returns ErrorDetail[] {
            if introspection {
                return [];
            }
            IntrospectionValidatorVisitor validator = new (introspection, nodeModifierContext);
            modifiedDocument.accept(validator);
            return validator.getErrors() ?: [];
        }

        ErrorDetail[] errors = wait queryDepthValidatorWorker;
        validationErrors.push(...errors);
        errors = wait subscriptionValidatorWorker;
        validationErrors.push(...errors);
        errors = wait directiveValidatorWorker;
        validationErrors.push(...errors);
        errors = wait fieldAndVariableValidatorWorker;
        validationErrors.push(...errors);
        errors = wait introspectionValidatorWorker;
        validationErrors.push(...errors);

        return validationErrors.length() > 0 ? validationErrors : nodeModifierContext;
    }

    isolated function getOperation(parser:DocumentNode document, string? operationName)
    returns ErrorDetail|parser:OperationNode {
        if operationName == () {
            if document.getOperations().length() == 1 {
                return document.getOperations()[0];
            } else {
                string message = string `Must provide operation name if query contains multiple operations.`;
                return {
                    message: message,
                    locations: []
                };
            }
        } else {
            foreach parser:OperationNode operationNode in document.getOperations() {
                if operationName == operationNode.getName() {
                    return operationNode;
                }
            }
            string message = string `Unknown operation named "${operationName}".`;
            return {
                message: message,
                locations: []
            };
        }
    }

    isolated function resolve(Context context, Field 'field, boolean executeLoadMethod = true) returns anydata {
        parser:FieldNode fieldNode = 'field.getInternalNode();

        if executeLoadMethod {
            string loadMethodName = getLoadMethodName(fieldNode.getName());
            service object {}? serviceObject = 'field.getServiceObject();
            if serviceObject is service object {} { 
                boolean isRemoteMethod = 'field.getOperationType() == parser:OPERATION_MUTATION && 'field.isRootField();
                if self.hasLoadMethod(serviceObject, loadMethodName, isRemoteMethod) {
                    return self.getResultFromLoadMethodExecution(context, 'field, serviceObject, loadMethodName, isRemoteMethod);
                }
            }
        }

        parser:RootOperationType operationType = 'field.getOperationType();
        (readonly & Interceptor)? interceptor = context.getNextInterceptor('field);
        __Type fieldType = 'field.getFieldType();
        ResponseGenerator responseGenerator = new (self, context, fieldType, 'field.getPath().clone());
        any|error fieldValue;
        if operationType == parser:OPERATION_QUERY {
            if interceptor is () {
                fieldValue = self.resolveResourceMethod(context, 'field, responseGenerator);
            } else {
                any|error result = self.executeInterceptor(interceptor, 'field, context);
                anydata|error interceptValue = validateInterceptorReturnValue(fieldType, result,
                                                                              self.getInterceptorName(interceptor));
                if interceptValue is error {
                    fieldValue = interceptValue;
                } else {
                    return interceptValue;
                }
            }
        } else if operationType == parser:OPERATION_MUTATION {
            if interceptor is () {
                fieldValue = self.resolveRemoteMethod(context, 'field, responseGenerator);
            } else {
                any|error result = self.executeInterceptor(interceptor, 'field, context);
                anydata|error interceptValue = validateInterceptorReturnValue(fieldType, result,
                                                                              self.getInterceptorName(interceptor));
                if interceptValue is error {
                    fieldValue = interceptValue;
                } else {
                    return interceptValue;
                }
            }
        } else {
            if interceptor is () {
                fieldValue = 'field.getFieldValue();
            } else {
                any|error result = self.executeInterceptor(interceptor, 'field, context);
                anydata|error interceptValue = validateInterceptorReturnValue(fieldType, result,
                                                                              self.getInterceptorName(interceptor));
                if interceptValue is error {
                    fieldValue = interceptValue;
                } else {
                    return interceptValue;
                }
            }
        }
        return responseGenerator.getResult(fieldValue, fieldNode);
    }

    private isolated function getResultFromLoadMethodExecution(Context context, Field 'field,
        service object {} serviceObject, string loadMethodName, boolean isRemoteMethod) returns PlaceHolderNode? {
        var batchFunctionMap = self.getBatchFunctionsMap(serviceObject, loadMethodName, isRemoteMethod);
        foreach var [batchFunctionId, batchFunction] in batchFunctionMap.entries() {
            context.addDataLoader(batchFunctionId, batchFunction);
        }
        handle? loadMethodHandle = ();
        if isRemoteMethod {
            loadMethodHandle = self.getRemoteMethod(serviceObject, loadMethodName);
        } else {
            loadMethodHandle = self.getResourceMethod(serviceObject, [loadMethodName]);
        }
        if loadMethodHandle is () {
            return ();
        }
        self.executeLoadMethod(context, serviceObject, loadMethodHandle, 'field);
        context.addNonDispatchedDataLoaderIds(batchFunctionMap.keys());
        string uuid = uuid:createType1AsString();
        PlaceHolder placeHolder = new ('field);
        context.addUnResolvedPlaceHolder(uuid, placeHolder);
        return {__uuid: uuid};
    }

    isolated function resolveResourceMethod(Context context, Field 'field, ResponseGenerator responseGenerator) returns any|error {
        service object {}? serviceObject = 'field.getServiceObject();
        if serviceObject is service object {} {
            handle? resourceMethod = self.getResourceMethod(serviceObject, 'field.getResourcePath());
            if resourceMethod == () {
                return self.resolveHierarchicalResource(context, 'field);
            }
            return self.executeQueryResource(context, serviceObject, resourceMethod, 'field, responseGenerator, self.validation);
        }
        return 'field.getFieldValue();
    }

    isolated function resolveRemoteMethod(Context context, Field 'field, ResponseGenerator responseGenerator) returns any|error {
        service object {}? serviceObject = 'field.getServiceObject();
        if serviceObject is service object {} {
           return self.executeMutationMethod(context, serviceObject, 'field, responseGenerator, self.validation);
        }
        return 'field.getFieldValue();
    }

    isolated function resolveHierarchicalResource(Context context, Field 'field) returns anydata {
        if 'field.getInternalNode().getSelections().length() == 0 {
            return;
        }
        map<anydata> result = {};
        foreach parser:SelectionNode selection in 'field.getInternalNode().getSelections() {
            if selection is parser:FieldNode {
                self.getHierarchicalResult(context, 'field, selection, result);
            } else if selection is parser:FragmentNode {
                self.resolveHierarchicalResourceFromFragment(context, 'field, selection, result);
            }
        }
        return result;
    }

    isolated function resolveHierarchicalResourceFromFragment(Context context, Field 'field,
                                                              parser:FragmentNode fragmentNode, map<anydata> result) {
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            if selection is parser:FieldNode {
                self.getHierarchicalResult(context, 'field, selection, result);
            } else if selection is parser:FragmentNode {
                self.resolveHierarchicalResourceFromFragment(context, 'field, selection, result);
            }
        }
    }

    isolated function getHierarchicalResult(Context context, Field 'field, parser:FieldNode fieldNode, map<anydata> result) {
        string[] resourcePath = 'field.getResourcePath();
        (string|int)[] path = 'field.getPath().clone();
        path.push(fieldNode.getName());
        __Type fieldType = getFieldTypeFromParentType('field.getFieldType(), self.schema.types, fieldNode);
        Field selectionField = new (fieldNode, fieldType, 'field.getServiceObject(), path = path, resourcePath = resourcePath);
        context.resetInterceptorCount();
        anydata fieldValue = self.resolve(context, selectionField);
        result[fieldNode.getAlias()] = fieldValue is ErrorDetail ? () : fieldValue;
        _ = resourcePath.pop();
    }

    isolated function addService(Service s) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    isolated function getService() returns Service = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    isolated function getResourceMethod(service object {} serviceObject, string[] path)
    returns handle? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function getRemoteMethod(service object {} serviceObject, string methodName)
    returns handle? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeQueryResource(Context context, service object {} serviceObject, handle resourceMethod,
                                           Field 'field, ResponseGenerator responseGenerator, boolean validation)
    returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeMutationMethod(Context context, service object {} serviceObject,
                                            Field 'field, ResponseGenerator responseGenerator, boolean validation) returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeSubscriptionResource(Context context, service object {} serviceObject,
                                                  Field 'field, ResponseGenerator responseGenerator, boolean validation) returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeInterceptor(readonly & Interceptor interceptor, Field fieldNode, Context context)
    returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function getInterceptorName(readonly & Interceptor interceptor) returns string = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function getBatchFunctionsMap(service object {} serviceObject, string loadMethodName, boolean isRemoteMethod)
    returns map<(isolated function (readonly & anydata[] keys) returns anydata[]|error)> = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function hasLoadMethod(service object {} serviceObject, string loadMethodName, boolean isRemoteMethod)
    returns boolean = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeLoadMethod(Context context, service object {} serviceObject, handle loadMethodHandle,
            Field 'field) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;
}
