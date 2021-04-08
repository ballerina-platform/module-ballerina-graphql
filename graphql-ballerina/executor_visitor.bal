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

class ExecutorVisitor {
    *parser:Visitor;

    private Service serviceType;
    private OutputObject outputObject;
    private map<anydata> data;
    private ErrorDetail[] errors;
    private __Schema schema;

    isolated function init(Service serviceType, __Schema schema) {
        self.serviceType = serviceType;
        self.outputObject = {
            data: {},
            errors: []
        };
        self.schema = schema;
        self.data = {};
        self.errors = [];
    }

    public isolated function getExecutorResult(parser:OperationNode operationNode) returns OutputObject {
        self.visitOperation(operationNode);
        return getOutputObject(self.data, self.errors);
    }

    public isolated function visitDocument(parser:DocumentNode documentNode) {
        // Do nothing
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        parser:FieldNode[] selections = operationNode.getFields();
        foreach parser:FieldNode fieldNode in selections {
            if (fieldNode.getName() == SCHEMA_FIELD) {
                map<anydata> subData = {};
                foreach parser:FieldNode selection in fieldNode.getFields() {
                    if (selection.getName() == TYPES_FIELD) {
                        __Type[] types = self.schema.types.toArray();
                        subData[selection.getName()] = getDataFromBalType(selection, types);
                    } else {
                        __Type schemaType = <__Type>self.schema[selection.getName()];
                        var fields = schemaType?.fields;
                        if (fields is __Field[]) {
                            map<anydata> typeMap = checkpanic schemaType.cloneWithType(AnydataMap);
                            typeMap[FIELDS_FIELD] = fields;
                            subData[selection.getName()] = getDataFromBalType(selection, typeMap);
                        }
                    }
                    self.data[fieldNode.getName()] = subData;
                }
            } else {
                var fieldResult = self.visitField(fieldNode, self.data);
                if (fieldResult is anydata) {
                    self.data[fieldNode.getName()] = fieldResult;
                }
            }
        }
    }

    public isolated function visitSelection(parser:Selection selection, anydata data = ()) {

    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) returns anydata|error {
        return executeResource(self.serviceType, self, fieldNode);
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {
        // Do nothing
    }

    public isolated function visitFragment(parser:FragmentNode fragmentNode, anydata data = ()) {
        // TODO;
    }
}
