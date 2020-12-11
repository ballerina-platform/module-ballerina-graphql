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

public class ExecutorVisitor {
    *parser:Visitor;

    private Service serviceType;
    private OutputObject outputObject;
    private map<anydata> data;
    private ErrorDetail[] errors;

    public isolated function init(Service serviceType) {
        self.serviceType = serviceType;
        self.outputObject = {
            data: {},
            errors: []
        };
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
        parser:FieldNode[] selections = operationNode.getSelections();
        foreach parser:FieldNode fieldNode in selections {
            var fieldResult = self.visitField(fieldNode, self.data);
            if (fieldResult is error) { // TODO: Check proper error
                self.errors.push(getErrorDetailRecord(fieldResult.message(), fieldNode.getLocation()));
            } else {
                self.data[fieldNode.getName()] = fieldResult;
            }
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) returns anydata|error {
        map<Scalar> arguments = {};
        foreach parser:ArgumentNode argument in fieldNode.getArguments() {
            var argumentValues = self.visitArgument(argument);
            arguments[argumentValues.name] = argumentValues.value;
        }

        if (fieldNode.getFieldType() is parser:PRIMITIVE) {
            return wait executeSingleResource(self, fieldNode, arguments);
        } else if (fieldNode.getFieldType() is parser:RECORD) {

        } else {

        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ())
    returns record { string name; Scalar value; } {
        Scalar value = argumentNode.getValue().value;
        string name = argumentNode.getName().value;

        return {
            name: name,
            value: value
        };
    }
}
