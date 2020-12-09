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
//import ballerina/io;

public class ValidatorVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;
    private __Schema schema;

    public isolated function init(__Schema schema) {
        self.errors = [];
        self.schema = schema;
    }

    public isolated function validate(parser:DocumentNode documentNode) {
        self.visitDocument(documentNode);
    }

    // TODO: Check for definitions other than Operations and Fragments, and if they exists, invalidate.
    // Parser doesn't support it yet.
    public isolated function visitDocument(parser:DocumentNode documentNode) {
        parser:OperationNode[] operations = documentNode.getOperations();
        parser:OperationNode[] anonymousOperations = [];

        foreach parser:OperationNode operationNode in operations {
            if (operationNode.getName() == parser:ANONYMOUS_OPERATION) {
                anonymousOperations.push(operationNode);
            }
            self.visitOperation(operationNode);
        }
        self.checkAnonymousOperations(anonymousOperations);
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {
        __Type queryType = self.schema.queryType;
        parser:FieldNode[] selections = operationNode.getSelections();
        foreach parser:FieldNode selection in selections {
            self.visitField(selection, queryType);
        }
    }

    public isolated function visitField(parser:FieldNode fieldNode, anydata data = ()) {
        string requiredFieldName = fieldNode.getName();
        __Type parentType = <__Type>data;
        map<__Field>? result = parentType?.fields;
        if (result == ()) {
            string message = getNoSubFieldsErrorMessage(parentType);
            ErrorDetail errorDetail = {
                message: message,
                locations: [fieldNode.getLocation()]
            };
            self.errors.push(errorDetail);
        }
        map<__Field> fields = <map<__Field>>result;
        var schemaField = fields[requiredFieldName];
        if (schemaField is ()) {
            string message = getFieldNotFoundErrorMessage(requiredFieldName, parentType.name);
            ErrorDetail errorDetail = {
                message: message,
                locations: [fieldNode.getLocation()]
            };
            self.errors.push(errorDetail);
        }
    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode, anydata data = ()) {

    }

    public isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
        //return self.errors.sort(key = isolated function (Error err) returns int {
        //    ErrorRecord errorRecord = <ErrorRecord>err.detail()["errorRecord"];
        //    return errorRecord.locations[0].line;
        //});
    }

    isolated function checkAnonymousOperations(parser:OperationNode[] anonymousOperations) {
        if (anonymousOperations.length() > 1) {
            string message = "This anonymous operation must be the only defined operation.";
            foreach parser:OperationNode operation in anonymousOperations {
                ErrorDetail err = {
                    message: message,
                    locations: [operation.getLocation()]
                };
                self.errors.push(err);
            }
        }
    }
}
