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

import ballerina/test;

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testInvalidFragmentNoSelections() returns error? {
    string document = string`fragment friendFields on User`;
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected "{", found <EOF>.`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testInvalidFragmentMissingOnKeyword() returns error? {
    string document = string`fragment friendFields o User`;
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected "on", found Name "o".`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testInvalidFragmentInvalidTypeType() returns error? {
    string document = string`fragment friendFields on "User"`;
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected Name, found String "User".`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testDocumentWithFragment() returns error? {
    string document = string
`{
    profile {
        ...profileFields
    }
}

fragment profileFields on Profile {
    name
    age
}`;
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    OperationNode[] operations = documentNode.getOperations();
    test:assertEquals(operations.length(), 1);
    OperationNode operationNode = operations[0];
    FieldNode[] fieldNodes = operationNode.getFields();
    test:assertEquals(fieldNodes.length(), 1);
    FieldNode fieldNode = fieldNodes[0];
    string[] fragments = fieldNode.getFragments();
    test:assertEquals(fragments.length(), 1);
    string fragmentName = fragments[0];
    test:assertEquals(fragmentName, "profileFields");
    map<FragmentNode> fragmentsMap = documentNode.getFragments();
    FragmentNode? result = fragmentsMap[fragmentName];
    test:assertTrue(result is FragmentNode);
    FragmentNode fragmentNode = <FragmentNode>result;
    test:assertEquals(fragmentNode.getFields().length(), 2);
    test:assertEquals(fragmentNode.getOnType(), "Profile");
}

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testInvalidFragmentName() returns error? {
    string document = string
`{
    profile {
        name
    }
}

fragment on on Profile {
    name
    age
}`;
    Parser parser = new(document);
    var result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Unexpected Name "on".`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["operations", "parser"]
}
isolated function testMultipleAnonymousOperations() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_anonymous_operations.txt");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    ErrorDetail[] errors = documentNode.getErrors();
    test:assertEquals(errors.length(), 2);
    ErrorDetail e1 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 1,
                column: 1
            }
        ]
    };
    ErrorDetail e2 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 7,
                column: 1
            }
        ]
    };
    test:assertEquals(errors[0], e1);
    test:assertEquals(errors[1], e2);
}

@test:Config {
    groups: ["operations", "parser"]
}
isolated function testAnonymousOperationWithNamedOperation() returns error? {
    string document = string
`{
    profile {
        name
    }
}

query getData {
    profile {
        age
    }
}`;
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    ErrorDetail[] errors = documentNode.getErrors();
    test:assertEquals(errors.length(), 1);
    ErrorDetail e1 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 1,
                column: 1
            }
        ]
    };
    test:assertEquals(errors[0], e1);
}

@test:Config {
    groups: ["operations", "parser"]
}
isolated function testNamedOperationWithAnonymousOperation() returns error? {
    string document = check getGraphQLDocumentFromFile("named_operation_with_anonymous_operation.txt");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    ErrorDetail[] errors = documentNode.getErrors();
    test:assertEquals(errors.length(), 1);
    ErrorDetail e1 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 7,
                column: 1
            }
        ]
    };
    test:assertEquals(errors[0], e1);
}


@test:Config {
    groups: ["operations", "parser"]
}
isolated function testNamedOperationWithMultipleAnonymousOperations() returns error? {
    string document = check getGraphQLDocumentFromFile("named_operation_with_multiple_anonymous_operations.txt");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    ErrorDetail[] errors = documentNode.getErrors();
    test:assertEquals(errors.length(), 2);
    ErrorDetail e1 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 1,
                column: 1
            }
        ]
    };
    ErrorDetail e2 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 13,
                column: 1
            }
        ]
    };
    test:assertEquals(errors[0], e1);
    test:assertEquals(errors[1], e2);
}

@test:Config {
    groups: ["operations", "parser"]
}
isolated function testThreeAnonymousOperations() returns error? {
    string document = check getGraphQLDocumentFromFile("three_anonymous_operations.txt");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    ErrorDetail[] errors = documentNode.getErrors();
    test:assertEquals(errors.length(), 3);
    ErrorDetail e1 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 1,
                column: 1
            }
        ]
    };
    ErrorDetail e2 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 7,
                column: 1
            }
        ]
    };
    ErrorDetail e3 = {
        message: "This anonymous operation must be the only defined operation.",
        locations: [
            {
                line: 13,
                column: 1
            }
        ]
    };
    test:assertEquals(errors[0], e1);
    test:assertEquals(errors[1], e2);
    test:assertEquals(errors[2], e3);
}

@test:Config {
    groups: ["operations", "parser"]
}
isolated function testMultipleOperationsWithSameName() returns error? {
    string document = check getGraphQLDocumentFromFile("multiple_operations_with_same_name.txt");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    ErrorDetail[] errors = documentNode.getErrors();
    test:assertEquals(errors.length(), 2);
    ErrorDetail e1 = {
        message: string`There can be only one operation named "getData".`,
        locations: [
            {
                line: 1,
                column: 1
            },
            {
                line: 7,
                column: 1
            }
        ]
    };
    ErrorDetail e2 = {
        message: string`There can be only one operation named "getData".`,
        locations: [
            {
                line: 1,
                column: 1
            },
            {
                line: 13,
                column: 1
            }
        ]
    };
    test:assertEquals(errors[0], e1);
    test:assertEquals(errors[1], e2);
}

@test:Config {
    groups: ["operations", "parser", "mutation"]
}
isolated function testParseAnonymousMutation() returns error? {
    string document = "mutation { setAge(newAge: 24) { name, age } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    OperationNode[] operations = documentNode.getOperations();
    test:assertEquals(operations.length(), 1);
    OperationNode operationNode = operations[0];
    test:assertEquals(operationNode.getKind(), MUTATION);
    test:assertEquals(operationNode.getName(), ANONYMOUS_OPERATION);
    test:assertEquals(operationNode.getFields().length(), 1);
    FieldNode fieldNode = operationNode.getFields()[0];
    test:assertEquals(fieldNode.getName(), "setAge");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName().value, "newAge");
    test:assertEquals(argumentNode.getValue().value, 24);
    test:assertEquals(fieldNode.getFields().length(), 2);
    test:assertEquals(fieldNode.getFields()[0].getName(), "name");
    test:assertEquals(fieldNode.getFields()[1].getName(), "age");
}

@test:Config {
    groups: ["operations", "parser", "mutation"]
}
isolated function testParseNamedMutation() returns error? {
    string document = "mutation SetAge { setAge(newAge: 24) { name, age } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    OperationNode[] operations = documentNode.getOperations();
    test:assertEquals(operations.length(), 1);
    OperationNode operationNode = operations[0];
    test:assertEquals(operationNode.getKind(), MUTATION);
    test:assertEquals(operationNode.getName(), "SetAge");
    test:assertEquals(operationNode.getFields().length(), 1);
    FieldNode fieldNode = operationNode.getFields()[0];
    test:assertEquals(fieldNode.getName(), "setAge");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName().value, "newAge");
    test:assertEquals(argumentNode.getValue().value, 24);
    test:assertEquals(fieldNode.getFields().length(), 2);
    test:assertEquals(fieldNode.getFields()[0].getName(), "name");
    test:assertEquals(fieldNode.getFields()[1].getName(), "age");
}

@test:Config {
    groups: ["validation", "parser"]
}
isolated function testMissingArgumentValue() returns error? {
    string document = "{ profile(id: ) { name age }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string`Syntax Error: Unexpected ")".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 15);
}

@test:Config {
    groups: ["validation", "parser"]
}
isolated function testEmptyDocument() returns error? {
    string document = "{ }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string`Syntax Error: Expected Name, found "}".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 3);
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testFieldAlias() returns error? {
    string document = "{ firstName: name }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getFields().length(), 1);
    FieldNode fieldNode = <FieldNode>operationNode.getFields()[0];
    string name = fieldNode.getName();
    test:assertEquals(name, "name");
    string alias = fieldNode.getAlias();
    test:assertEquals(alias, "firstName");
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testFieldAliasWithNamedOperation() returns error? {
    string document = "query getName { firstName: name }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getFields().length(), 1);
    FieldNode fieldNode = <FieldNode>operationNode.getFields()[0];
    string name = fieldNode.getName();
    test:assertEquals(name, "name");
    string alias = fieldNode.getAlias();
    test:assertEquals(alias, "firstName");
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testInvalidFieldAliasWithoutFieldName() returns error? {
    string document = "query getName { firstName: }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string`Syntax Error: Expected Name, found "}".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 28);
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testInvalidFieldAliasWithoutAlias() returns error? {
    string document = "query getName { : name }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string`Syntax Error: Expected Name, found ":".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 17);
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testFieldAliasInsideField() returns error? {
    string document = "query getName { profile { firstName: name } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getFields().length(), 1);
    FieldNode fieldNode = <FieldNode>operationNode.getFields()[0];
    test:assertEquals(fieldNode.getFields().length(), 1);
    fieldNode = <FieldNode>fieldNode.getFields()[0];
    string name = fieldNode.getName();
    test:assertEquals(name, "name");
    string alias = fieldNode.getAlias();
    test:assertEquals(alias, "firstName");
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testFieldAliasWithArguments() returns error? {
    string document = "query getName { walt: profile(id: 1) }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getFields().length(), 1);
    FieldNode fieldNode = <FieldNode>operationNode.getFields()[0];
    string name = fieldNode.getName();
    test:assertEquals(name, "profile");
    string alias = fieldNode.getAlias();
    test:assertEquals(alias, "walt");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = <ArgumentNode>fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName().value, "id");
    test:assertEquals(argumentNode.getValue().value, 1);
}

@test:Config {
    groups: ["variables", "parser"]
}
isolated function testVariables() returns error? {
    string document = "query getName($profileId:Int = 3) { profile(id:$profileId) { name } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 1);
    VariableDefinition variableDefinition = <VariableDefinition> operationNode.getVaribleDefinitions()["profileId"];
    test:assertEquals(variableDefinition.name, "profileId");
    test:assertEquals(variableDefinition.kind, "Int");
    ArgumentValue argValue = <ArgumentValue> variableDefinition?.defaultValue;
    test:assertEquals(argValue.value, 3);
    FieldNode fieldNode = <FieldNode>operationNode.getFields()[0];
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = <ArgumentNode>fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName().value, "id");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    test:assertEquals(argumentNode.getVariableName(), "profileId");
}
