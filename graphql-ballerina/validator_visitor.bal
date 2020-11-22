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

public class ValidatorVisitor {
    *Visitor;

    private ErrorDetail[] errors;

    public isolated function init() {
        self.errors = [];
    }

    public isolated function validate(DocumentNode documentNode) {
        self.visitDocument(documentNode);
    }

    // TODO: Check for definitions other than Operations and Fragments, and if they exists, invalidate.
    // Parser doesn't support it yet.
    public isolated function visitDocument(DocumentNode documentNode) {
        OperationNode[] operations = documentNode.getOperations();
        if (operations.length() == 1) {
            return;
        }
        self.checkAnonymousOperations(operations);
    }

    public isolated function visitOperation(OperationNode operationNode) {

    }

    public isolated function visitField(FieldNode fieldNode, ParentType? parent = ()) {

    }

    public isolated function visitArgument(ArgumentNode argumentNode) {

    }

    public isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }

    isolated function checkAnonymousOperations(OperationNode[] operations) {
        OperationNode[] anonymousOperations = [];
        foreach OperationNode operation in operations {
            if (operation.name == ANONYMOUS_OPERATION) {
                anonymousOperations.push(operation);
            }
        }

        if (anonymousOperations.length() > 1 || (anonymousOperations.length() > 0 && operations.length() > 1)) {
            string message = "This anonymous operation must be the only defined operation.";
            foreach OperationNode operation in anonymousOperations {
                ErrorDetail err = {
                    message: message,
                    locations: [operation.location]
                };
                self.errors.push(err);
            }
        }
    }
}
