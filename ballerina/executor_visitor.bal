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
    private Data data;
    private Context context;
    private any|error result; // The value of this field is set using setResult method

    isolated function init(Engine engine, readonly & __Schema schema, Context context, any|error result = ()) {
        self.engine = engine;
        self.schema = schema;
        self.context = context;
        self.data = {};
        self.result = ();
        self.setResult(result);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode, anydata data = ()) {}

    public isolated function visitOperation(parser:OperationNode operationNode, anydata data = ()) {
        string[] path = [];
        if operationNode.getName() != parser:ANONYMOUS_OPERATION {
            path.push(operationNode.getName());
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
        lock {
            if fieldNode.getName() == SCHEMA_FIELD {
            IntrospectionExecutor introspectionExecutor = new(self.schema);
            self.data[fieldNode.getAlias()] = introspectionExecutor.getSchemaIntrospection(fieldNode);
            } else if fieldNode.getName() == TYPE_FIELD {
                IntrospectionExecutor introspectionExecutor = new(self.schema);
                self.data[fieldNode.getAlias()] = introspectionExecutor.getTypeIntrospection(fieldNode);
            } else if fieldNode.getName() == TYPE_NAME_FIELD {
                if operationType == parser:OPERATION_QUERY {
                    self.data[fieldNode.getAlias()] = QUERY_TYPE_NAME;
                } else if operationType == parser:OPERATION_MUTATION {
                    self.data[fieldNode.getAlias()] = MUTATION_TYPE_NAME;
                } else {
                    self.data[fieldNode.getAlias()] = SUBSCRIPTION_TYPE_NAME;
                }
            } else {
                isIntrospection = false;
            }
        }
        isolated function (parser:FieldNode, parser:RootOperationType) execute;
        lock {
            execute = self.execute;
        }
        if !isIntrospection {
            execute(fieldNode, operationType);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {}

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        parser:RootOperationType operationType = self.getOperationTypeFromData(data);
        string[] path = self.getSelectionPathFromData(data);
        foreach parser:SelectionNode selection in fragmentNode.getSelections() {
            string[] clonedPath = path.clone();
            if selection is parser:FieldNode {
                clonedPath.push(selection.getName());
            }
            map<anydata> dataMap = {[OPERATION_TYPE] : operationType, [PATH] : clonedPath};
            selection.accept(self, dataMap);
        }
    }
    public isolated function visitDirective(parser:DirectiveNode directiveNode, anydata data = ()) {}

    public isolated function visitVariable(parser:VariableNode variableNode, anydata data = ()) {}

    isolated function execute(parser:FieldNode fieldNode, parser:RootOperationType operationType) {
        any|error result;
        __Schema schema;
        Engine engine;
        Context context;
        lock {
            result = self.getResult();
            schema = self.schema;
            engine = self.engine;
            context = self.context;
        }
        Field 'field = getFieldObject(fieldNode, operationType, schema, engine, result);
        'field.setMainService(true);
        context.resetInterceptorCount();
        anydata resolvedResult = engine.resolve(context, 'field);
        lock {
            self.data[fieldNode.getAlias()] = resolvedResult is ErrorDetail ? () : resolvedResult.cloneReadOnly();
        }
    }

    isolated function getOutput() returns OutputObject {
        lock {
            if !self.context.hasPlaceholders() {
                // Avoid rebuilding the value tree if there are no place holders
                return getOutputObject(self.data.clone(), self.context.getErrors().clone());
            }
            ValueTreeBuilder valueTreeBuilder = new (self.context, self.data);
            return getOutputObject(valueTreeBuilder.build(), self.context.getErrors().clone());
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

    private isolated function setResult(any|error result) =  @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    private isolated function getResult() returns any|error =  @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;
}
