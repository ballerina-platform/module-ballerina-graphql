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

isolated class ExecutorVisitor {
    *parser:Visitor;

    private final readonly & __Schema schema;
    private final Engine engine; // This field needed to be accessed from the native code
    private final Context context;
    private any|error result; // The value of this field is set using setResult method

    isolated function init(Engine engine, readonly & __Schema schema, Context context, any|error result = ()) {
        self.engine = engine;
        self.schema = schema;
        self.context = context;
        self.result = ();
        self.setResult(result);
        self.initializeDataMap();
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {}

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        string[] path = [];
        if operationNode.getName() != parser:ANONYMOUS_OPERATION {
            path.push(operationNode.getName());
        }
        service object {} serviceObject;
        lock {
            serviceObject = self.engine.getService();
        }
        if operationNode.getKind() != parser:OPERATION_MUTATION && serviceObject is isolated service object {} {
            map<anydata> dataMap = {[OPERATION_TYPE] : operationNode.getKind(), [PATH] : path};
            return self.visitSelectionsParallelly(operationNode, dataMap.cloneReadOnly());
        }
        foreach parser:SelectionNode selection in operationNode.getSelections() {
            if selection is parser:FieldNode {
                path.push(selection.getName());
            }
            map<anydata> dataMap = {[OPERATION_TYPE] : operationNode.getKind(), [PATH] : path};
            selection.accept(self, dataMap);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        parser:RootOperationType operationType = self.getOperationTypeFromData(data);
        boolean isIntrospection = true;
        if fieldNode.getName() == SCHEMA_FIELD {
            IntrospectionExecutor introspectionExecutor = new (self.schema);
            self.addData(fieldNode.getAlias(), introspectionExecutor.getSchemaIntrospection(fieldNode));
        } else if fieldNode.getName() == TYPE_FIELD {
            IntrospectionExecutor introspectionExecutor = new (self.schema);
            self.addData(fieldNode.getAlias(), introspectionExecutor.getTypeIntrospection(fieldNode));
        } else if fieldNode.getName() == TYPE_NAME_FIELD {
            if operationType == parser:OPERATION_QUERY {
                self.addData(fieldNode.getAlias(), QUERY_TYPE_NAME);
            } else if operationType == parser:OPERATION_MUTATION {
                self.addData(fieldNode.getAlias(), MUTATION_TYPE_NAME);
            } else {
                self.addData(fieldNode.getAlias(), SUBSCRIPTION_TYPE_NAME);
            }
        } else {
            isIntrospection = false;
        }

        if !isIntrospection {
            self.execute(fieldNode, operationType);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:RootOperationType operationType = self.getOperationTypeFromData(data);
        string[] path = self.getSelectionPathFromData(data);
        if operationType != parser:OPERATION_MUTATION {
            map<anydata> dataMap = {[OPERATION_TYPE] : operationType, [PATH] : path};
            return self.visitSelectionsParallelly(fragmentNode, dataMap.cloneReadOnly());
        }
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            if selection is parser:FieldNode {
                path.push(selection.getName());
            }
            map<anydata> dataMap = {[OPERATION_TYPE] : operationType, [PATH] : path};
            selection.accept(self, dataMap);
        }
    }
    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {
    }

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {
    }

    isolated function execute(parser:FieldNode fieldNode, parser:RootOperationType operationType) {
        any|error result;
        __Schema schema = self.schema;
        Engine engine;
        Context context;
        lock {
            result = self.getResult();
            engine = self.engine;
            context = self.context;
        }
        Field 'field = getFieldObject(fieldNode, operationType, schema, engine, result);
        anydata resolvedResult = engine.resolve(context, 'field);
        self.addData(fieldNode.getAlias(), resolvedResult is ErrorDetail ? () : resolvedResult);
    }

    isolated function getOutput() returns OutputObject {
        Context context;
        lock {
            context = self.context;
        }
        Data data = self.getDataMap();
        ErrorDetail[] errors = context.getErrors();
        if !self.context.hasPlaceholders() {
            // Avoid rebuilding the value tree if there are no place holders
            return getOutputObject(data, errors);
        }
        ValueTreeBuilder valueTreeBuilder = new ();
        data = valueTreeBuilder.build(context, data);
        errors = context.getErrors();
        return getOutputObject(data, errors);
    }

    private isolated function visitSelectionsParallelly(parser:SelectionParentNode selectionParentNode,
            readonly & anydata data = ()) {
        parser:RootOperationType operationType = self.getOperationTypeFromData(data);
        [parser:SelectionNode, future<()>][] selectionFutures = [];
        string[] path = self.getSelectionPathFromData(data);
        foreach parser:SelectionNode selection in selectionParentNode.getSelections() {
            if selection is parser:FieldNode {
                path.push(selection.getName());
            }
            map<anydata> dataMap = {[OPERATION_TYPE] : operationType, [PATH] : path};
            future<()> 'future = start selection.accept(self, dataMap.cloneReadOnly());
            selectionFutures.push([selection, 'future]);
        }
        foreach [parser:SelectionNode, future<()>] [selection, 'future] in selectionFutures {
            error? err = wait 'future;
            if err is () {
                continue;
            }
            if selection is parser:FieldNode {
                path.push(selection.getName());
                self.addData(selection.getAlias(), ());
                ErrorDetail errorDetail = {
                    message: err.message(),
                    locations: [selection.getLocation()],
                    path: path
                };
                lock {
                    self.context.addError(errorDetail);
                }
            }
        }
    }

    private isolated function getSelectionPathFromData(anydata data) returns string[] {
        map<anydata> dataMap = <map<anydata>>data;
        string[] path = <string[]>dataMap[PATH];
        return [...path];
    }

    private isolated function getOperationTypeFromData(anydata data) returns parser:RootOperationType {
        map<anydata> dataMap = <map<anydata>>data;
        return <parser:RootOperationType>dataMap[OPERATION_TYPE];
    }

    private isolated function setResult(any|error result) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    isolated function initializeDataMap() = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.ExecutorVisitor"
    } external;

    private isolated function addData(string key, anydata value) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.ExecutorVisitor"
    } external;

    private isolated function getResult() returns any|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    private isolated function getDataMap() returns Data = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.ExecutorVisitor"
    } external;
}
