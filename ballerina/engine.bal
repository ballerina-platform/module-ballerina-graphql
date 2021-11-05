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

isolated class Engine {
    private final readonly & __Schema schema;
    private final int? maxQueryDepth;

    isolated function init(__Schema schema, int? maxQueryDepth) returns Error? {
        self.schema = schema.cloneReadOnly();
        if maxQueryDepth is int && maxQueryDepth < 1 {
            return error Error("Max query depth value must be a positive integer");
        }
        self.maxQueryDepth = maxQueryDepth;
    }

    isolated function validate(string documentString, string? operationName, map<json>? variables) returns parser:OperationNode|OutputObject {
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

    isolated function execute(parser:OperationNode operationNode, Context context) returns OutputObject {
        ExecutorVisitor executor = new(self, self.schema, context);
        OutputObject outputObject = executor.getExecutorResult(operationNode);
        ResponseFormatter responseFormatter = new(self.schema);
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

        FragmentVisitor fragmentVisitor = new(document);
        ErrorDetail[]? errors = fragmentVisitor.validate();
        if errors is ErrorDetail[] {
            return getOutputObjectFromErrorDetail(errors);
        }

        if self.maxQueryDepth is int {
            int queryDepth = <int> self.maxQueryDepth;
            QueryDepthValidator queryDepthValidator = new QueryDepthValidator(document, queryDepth);
            errors = queryDepthValidator.validate();
            if errors is ErrorDetail[] {
                return getOutputObjectFromErrorDetail(errors);
            }
        }

        VariableValidator variableValidator = new(self.schema, document, variables);
        errors = variableValidator.validate();
        if errors is ErrorDetail[] {
            return getOutputObjectFromErrorDetail(errors);
        }

        ValidatorVisitor validator = new(self.schema, document);
        errors = validator.validate();
        if errors is ErrorDetail[] {
            return getOutputObjectFromErrorDetail(errors);
        }

        DirectiveVisitor directiveVisitor = new(self.schema, document);
        errors = directiveVisitor.validate();
        if errors is ErrorDetail[] {
            return getOutputObjectFromErrorDetail(errors);
        }

        DuplicateFieldRemover duplicateFieldRemover = new(document);
        duplicateFieldRemover.remove();
        return;
    }

    isolated function getOperation(parser:DocumentNode document, string? operationName)
    returns parser:OperationNode|OutputObject {
        if operationName == () {
            if document.getOperations().length() == 1 {
                return document.getOperations()[0];
            } else {
                string message = string`Must provide operation name if query contains multiple operations.`;
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
            string message = string`Unknown operation named "${operationName}".`;
            ErrorDetail errorDetail = {
                message: message,
                locations: []
            };
            return getOutputObjectFromErrorDetail(errorDetail);
        }
    }
}
