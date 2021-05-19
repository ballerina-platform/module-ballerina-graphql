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

class Engine {
    private final __Schema schema;
    private final Service graphqlService;
    private final int? maxQueryDepth;
    private final ListenerAuthConfig[]? auth;

    public isolated function init(Service s) returns Error? {
        self.schema = check createSchema(s);
        self.graphqlService = s;
        GraphqlServiceConfiguration? serviceConfig = getServiceConfiguration(s);
        self.maxQueryDepth = getMaxQueryDepth(s);
        self.auth = getListenerAuthConfig(s);
    }

    isolated function getOutputObjectForQuery(string documentString, string operationName) returns OutputObject {
        parser:DocumentNode|OutputObject result = self.parse(documentString);
        if (result is OutputObject) {
            return result;
        }
        parser:DocumentNode document = <parser:DocumentNode>result;
        OutputObject? validationResult = self.validateDocument(document);
        if (validationResult is OutputObject) {
            return validationResult;
        } else {
            if (document.getOperations().length() == 1) {
                return self.execute(document.getOperations()[0]);
            }
            foreach parser:OperationNode operationNode in document.getOperations() {
                if (operationName == operationNode.getName()) {
                    return self.execute(operationNode);
                }
            }
            string name = operationName == parser:ANONYMOUS_OPERATION ? "" : operationName;
            string message = "Operation \"" + name + "\" is not present in the provided GraphQL document.";
            ErrorDetail errorDetail = {
                message: message,
                locations: []
            };
            return getOutputObjectFromErrorDetail(errorDetail);
        }
    }

    isolated function parse(string documentString) returns parser:DocumentNode|OutputObject {
        parser:Parser parser = new (documentString);
        parser:DocumentNode|parser:Error parseResult = parser.parse();
        if (parseResult is parser:DocumentNode) {
            return parseResult;
        }
        ErrorDetail errorDetail = getErrorDetailFromError(<parser:Error>parseResult);
        return getOutputObjectFromErrorDetail(errorDetail);
    }

    isolated function validateDocument(parser:DocumentNode document) returns OutputObject? {
        if (self.maxQueryDepth is int) {
            QueryDepthValidator queryDepthValidator = new QueryDepthValidator(document, <int>self.maxQueryDepth);
            ErrorDetail[]? errors = queryDepthValidator.validate();
            if (errors is ErrorDetail[]) {
                return getOutputObjectFromErrorDetail(errors);
            }
        }
        ValidatorVisitor validator = new(self.schema, document);
        ErrorDetail[]? errors = validator.validate();
        if (errors is ErrorDetail[]) {
            return getOutputObjectFromErrorDetail(errors);
        }
    }

    isolated function execute(parser:OperationNode operationNode) returns OutputObject {
        ExecutorVisitor executor = new(self.graphqlService, self.schema);
        OutputObject outputObject = executor.getExecutorResult(operationNode);
        return outputObject;
    }

    isolated function getAuthConfigs() returns ListenerAuthConfig[]? {
        return self.auth;
    }
}
