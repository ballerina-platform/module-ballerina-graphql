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

public class ValidatorVisitor {
    *parser:Visitor;

    private ErrorDetail[] errors;

    public isolated function init() {
        self.errors = [];
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
            if (operationNode.name == parser:ANONYMOUS_OPERATION) {
                anonymousOperations.push(operationNode);
            }
            self.visitOperation(operationNode);
        }
        self.checkAnonymousOperations(anonymousOperations);
    }

    public isolated function visitOperation(parser:OperationNode operationNode) {

    }

    public isolated function visitField(parser:FieldNode fieldNode, parser:ParentType? parent = ()) {

    }

    public isolated function visitArgument(parser:ArgumentNode argumentNode) {

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
                    locations: [operation.location]
                };
                self.errors.push(err);
            }
        }
    }
}
