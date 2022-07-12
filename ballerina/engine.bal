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

import ballerina/jballerina.java;

import graphql.parser;

isolated class Engine {
    private final readonly & __Schema schema;
    private final int? maxQueryDepth;
    private final readonly & (readonly & Interceptor)[] interceptors;
    private int nextInterceptor;

    isolated function init(string schemaString, int? maxQueryDepth, Service s, (readonly & Interceptor)[] interceptors) returns Error? {
        if maxQueryDepth is int && maxQueryDepth < 1 {
            return error Error("Max query depth value must be a positive integer");
        }
        self.maxQueryDepth = maxQueryDepth;
        self.schema = check createSchema(schemaString);
        self.interceptors = interceptors.cloneReadOnly();
        self.nextInterceptor = 0;
        self.addService(s);
    }

    isolated function getSchema() returns readonly & __Schema {
        return self.schema;
    }

    isolated function getInterceptors() returns (readonly & Interceptor)[] {
        return self.interceptors;
    }

    isolated function getNextInterceptor() returns (readonly & Interceptor)? {
        lock {
            if self.interceptors.length() > self.nextInterceptor {
                readonly & Interceptor next = self.interceptors[self.nextInterceptor];
                self.nextInterceptor += 1;
                return next;
            }
            self.nextInterceptor = 0;
            return;
        }
    }

    isolated function validate(string documentString, string? operationName, map<json>? variables)
        returns parser:OperationNode|OutputObject {

        parser:DocumentNode|OutputObject result = self.parse(documentString);
        if result is OutputObject {
            return result;
        }
        parser:DocumentNode document = <parser:DocumentNode>result;
        OutputObject? validationResult = self.validateDocument(document, variables);
        if validationResult is OutputObject {
            return validationResult;
        } else {
            return self.getOperation(document, operationName);
        }
    }

    isolated function getResult(parser:OperationNode operationNode, Context context, any result = ())
    returns OutputObject {
        DefaultDirectiveProcessorVisitor defaultDirectiveProcessor = new (self.schema);
        DuplicateFieldRemoverVisitor duplicateFieldRemover = new;

        parser:Visitor[] updatingVisitors = [
            defaultDirectiveProcessor,
            duplicateFieldRemover
        ];

        foreach parser:Visitor visitor in updatingVisitors {
            operationNode.accept(visitor);
        }

        ExecutorVisitor executor = new (self, self.schema, context, result);
        operationNode.accept(executor);
        OutputObject outputObject = executor.getOutput();
        ResponseFormatter responseFormatter = new (self.schema);
        return responseFormatter.getCoercedOutputObject(outputObject, operationNode);
    }

    isolated function parse(string documentString) returns parser:DocumentNode|OutputObject {
        parser:Parser parser = new (documentString);
        parser:DocumentNode|parser:Error parseResult = parser.parse();
        if parseResult is parser:DocumentNode {
            return parseResult;
        }
        ErrorDetail errorDetail = getErrorDetailFromError(<parser:Error>parseResult);
        return getOutputObjectFromErrorDetail(errorDetail);
    }

    isolated function validateDocument(parser:DocumentNode document, map<json>? variables) returns OutputObject? {
        if document.getErrors().length() > 0 {
            return getOutputObjectFromErrorDetail(document.getErrors());
        }

        ValidatorVisitor[] validators = [
            new FragmentCycleFinderVisitor(document.getFragments()),
            new FragmentValidatorVisitor(document.getFragments()),
            new QueryDepthValidatorVisitor(self.maxQueryDepth),
            new VariableValidatorVisitor(self.schema, variables),
            new FieldValidatorVisitor(self.schema),
            new DirectiveValidatorVisitor(self.schema),
            new SubscriptionValidatorVisitor()
        ];

        foreach ValidatorVisitor validator in validators {
            document.accept(validator);
            ErrorDetail[]? errors = validator.getErrors();
            if errors is ErrorDetail[] {
                return getOutputObjectFromErrorDetail(errors);
            }
        }
        return;
    }

    isolated function getOperation(parser:DocumentNode document, string? operationName)
    returns parser:OperationNode|OutputObject {
        if operationName == () {
            if document.getOperations().length() == 1 {
                return document.getOperations()[0];
            } else {
                string message = string `Must provide operation name if query contains multiple operations.`;
                ErrorDetail errorDetail = {
                    message: message,
                    locations: []
                };
                return getOutputObjectFromErrorDetail(errorDetail);
            }
        } else {
            foreach parser:OperationNode operationNode in document.getOperations() {
                if operationName == operationNode.getName() {
                    return operationNode;
                }
            }
            string message = string `Unknown operation named "${operationName}".`;
            ErrorDetail errorDetail = {
                message: message,
                locations: []
            };
            return getOutputObjectFromErrorDetail(errorDetail);
        }
    }

    isolated function resolve(Context context, Field 'field) returns anydata {
        service object {} serviceObject = 'field.getServiceObject();
        parser:FieldNode fieldNode = 'field.getInternalNode();
        parser:RootOperationType operationType = 'field.getOperationType();
        (Interceptor & readonly)? interceptor = self.getNextInterceptor();
        __Type fieldType = 'field.getFieldType();
        any|error fieldValue;
        if operationType == parser:OPERATION_QUERY {
            handle? resourceMethod = self.getResourceMethod(serviceObject, fieldNode, [fieldNode.getName()]);
            if resourceMethod == () {
                fieldValue = (); // Hierarchical paths
            } else {
                if interceptor is () {
                    fieldValue = self.executeQueryResource(serviceObject, resourceMethod, fieldNode, context); 
                } else {
                    any|error result = executeInterceptor(interceptor, 'field, context);
                    anydata|error interceptValue = validateInterceptorReturnValue(fieldType, result, getInterceptorName(interceptor));
                    if interceptValue is error {
                        fieldValue = interceptValue;
                    } else {
                        return interceptValue;
                    }
                }
            }
        } else if operationType == parser:OPERATION_MUTATION {
            if interceptor is () {
                fieldValue = self.executeMutationMethod(serviceObject, fieldNode, context);
            } else {
                any|error result = executeInterceptor(interceptor, 'field, context);
                anydata|error interceptValue = validateInterceptorReturnValue(fieldType, result, getInterceptorName(interceptor));
                if interceptValue is error {
                    fieldValue = interceptValue;
                } else {
                    return interceptValue;
                }
            }
        } else {
            fieldValue = ();
        }
        ResponseGenerator responseGenerator = new(self, context, fieldType, 'field.getPath().clone());
        return responseGenerator.getResult(fieldValue, fieldNode);
    }

    isolated function addService(Service s) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    isolated function getService() returns Service = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    isolated function getResourceMethod(service object {} serviceObject, parser:FieldNode fieldNode, string[] path)
    returns handle? = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeQueryResource(service object {} serviceObject, handle resourceMethod,
                                           parser:FieldNode fieldNode, Context context)
    returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;

    isolated function executeMutationMethod(service object {} serviceObject, parser:FieldNode fieldNode,
                                            Context context) returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.Engine"
    } external;
}
