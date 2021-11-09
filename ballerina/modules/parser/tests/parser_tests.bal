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
    Selection[] selections = operationNode.getSelections();
    test:assertEquals(selections.length(), 1);
    test:assertTrue(selections[0] is FieldNode);
    FieldNode fieldNode = <FieldNode>selections[0];
    selections = fieldNode.getSelections();
    test:assertEquals(selections.length(), 1);
    test:assertTrue(selections[0] is FragmentNode);
    string fragmentName = (<FragmentNode>selections[0]).getName();
    test:assertEquals(fragmentName, "profileFields");
    map<FragmentNode> fragmentsMap = documentNode.getFragments();
    FragmentNode? result = fragmentsMap[fragmentName];
    test:assertTrue(result is FragmentNode);
    FragmentNode fragmentNode = <FragmentNode>result;
    test:assertEquals(fragmentNode.getSelections().length(), 2);
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
    string document = check getGraphQLDocumentFromFile("multiple_anonymous_operations.graphql");
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
    string document = check getGraphQLDocumentFromFile("named_operation_with_anonymous_operation.graphql");
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
    string document = check getGraphQLDocumentFromFile("named_operation_with_multiple_anonymous_operations.graphql");
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
    string document = check getGraphQLDocumentFromFile("three_anonymous_operations.graphql");
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
    string document = check getGraphQLDocumentFromFile("multiple_operations_with_same_name.graphql");
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
    test:assertEquals(operationNode.getKind(), OPERATION_MUTATION);
    test:assertEquals(operationNode.getName(), ANONYMOUS_OPERATION);
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "setAge");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "newAge");
    test:assertEquals((<ArgumentValue>argumentNode.getValue().get("newAge")).value, 24);
    test:assertEquals(fieldNode.getSelections().length(), 2);
    test:assertEquals((<FieldNode>fieldNode.getSelections()[0]).getName(), "name");
    test:assertEquals((<FieldNode>fieldNode.getSelections()[1]).getName(), "age");
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
    test:assertEquals(operationNode.getKind(), OPERATION_MUTATION);
    test:assertEquals(operationNode.getName(), "SetAge");
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "setAge");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "newAge");
    test:assertEquals((<ArgumentValue>argumentNode.getValue().get("newAge")).value, 24);
    test:assertEquals(fieldNode.getSelections().length(), 2);
    test:assertEquals((<FieldNode>fieldNode.getSelections()[0]).getName(), "name");
    test:assertEquals((<FieldNode>fieldNode.getSelections()[1]).getName(), "age");
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
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
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
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
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
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getSelections().length(), 1);
    selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode> selection;
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
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    string name = fieldNode.getName();
    test:assertEquals(name, "profile");
    string alias = fieldNode.getAlias();
    test:assertEquals(alias, "walt");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "id");
    test:assertEquals((<ArgumentValue>argumentNode.getValue().get("id")).value, 1);
}

@test:Config {
    groups: ["variables", "parser"]
}
isolated function testVariables() returns error? {
    string document = "query getName($profileId:Int = 3) { profile(id:$profileId) { name } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 1);
    VariableDefinitionNode variableDefinition = <VariableDefinitionNode> operationNode.getVaribleDefinitions()["profileId"];
    test:assertEquals(variableDefinition.getName(), "profileId");
    test:assertEquals(variableDefinition.getTypeName(), "Int");
    ArgumentNode argValueNode = <ArgumentNode> variableDefinition.getDefaultValue();
    ArgumentValue argValue = <ArgumentValue> argValueNode.getValue()[variableDefinition.getName()];
    test:assertEquals(argValue.value, 3);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "id");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    test:assertEquals(argumentNode.getVariableName(), "profileId");
}

@test:Config {
    groups: ["variables", "parser"]
}
isolated function testNonNullTypeVariables() returns error? {
    string document = "query getId($name: String!, $age: Int!) { profile(userName:$name, userAge:$age) { id } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);
    VariableDefinitionNode variableDefinition = <VariableDefinitionNode> operationNode.getVaribleDefinitions()["name"];
    test:assertEquals(variableDefinition.getName(), "name");
    test:assertEquals(variableDefinition.getTypeName(), "String!");
    variableDefinition = <VariableDefinitionNode> operationNode.getVaribleDefinitions()["age"];
    test:assertEquals(variableDefinition.getName(), "age");
    test:assertEquals(variableDefinition.getTypeName(), "Int!");
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "userName");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    test:assertEquals(argumentNode.getVariableName(), "name");
    argumentNode = fieldNode.getArguments()[1];
    test:assertEquals(argumentNode.getName(), "userAge");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    test:assertEquals(argumentNode.getVariableName(), "age");
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testListTypeVariables() returns error? {
    string document = "query getId($name: [String!]!) { profile(userName:$name) { id } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 1);
    VariableDefinitionNode variableDefinition = <VariableDefinitionNode> operationNode.getVaribleDefinitions()["name"];
    test:assertEquals(variableDefinition.getName(), "name");
    test:assertEquals(variableDefinition.getTypeName(), "[String!]!");
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "userName");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    test:assertEquals(argumentNode.getVariableName(), "name");
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testInvalidListTypeVariableMissingOpenBracket() returns error? {
    string document = "query getId($name: String!]!) { profile(userName:$name) { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected "$", found "]".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 27);
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testInvalidListTypeVariableMissingCloseBracket() returns error? {
    string document = "query getId($name: [String![) { profile(userName:$name) { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected "]", found "[".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 28);
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testEmptyListTypeVariable() returns error? {
    string document = "query getId($name: []) { profile(userName:$name) { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected Name, found "]".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 21);
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testVariablesWithInvalidDefaultValue() returns error? {
    string document = "query getId($name: String = $name) { profile(userName:$name) { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 29);
}

@test:Config {
    groups: ["variables", "input_objects", "parser"]
}
isolated function testInputObjectWithInvalidVariableDefaultValue() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_invalid_variable_default_value.graphql");
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 91);
}

@test:Config {
    groups: ["input_objects", "parser"]
}
isolated function testInputObjects() returns error? {
    string document = check getGraphQLDocumentFromFile("input_object_with_default_value.graphql");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);
    VariableDefinitionNode variableDefinition = <VariableDefinitionNode> operationNode.getVaribleDefinitions()["bAuthor"];
    test:assertEquals(variableDefinition.getName(), "bAuthor");
    test:assertEquals(variableDefinition.getTypeName(), "ProfileDetail");
    ArgumentNode argValue = <ArgumentNode> variableDefinition.getDefaultValue();
    test:assertEquals(argValue.getKind(), T_INPUT_OBJECT);
    test:assertEquals(argValue.getName(), "bAuthor");
    map<ArgumentValue|ArgumentNode> defaultValue = argValue.getValue();
    test:assertEquals(defaultValue.hasKey("name"), true);
    ArgumentNode argField = <ArgumentNode> defaultValue.get("name");
    ArgumentValue defaultValueField = <ArgumentValue> argField.getValue().get("name");
    test:assertEquals(defaultValueField.value, "J.K Rowling");
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "book");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "info");
    map<ArgumentValue|ArgumentNode> inputObjectFields = <map<ArgumentValue|ArgumentNode>> argumentNode.getValue();
    test:assertEquals(inputObjectFields.hasKey("bookName"), true);
    test:assertEquals(inputObjectFields.hasKey("author"), true);
    test:assertEquals(inputObjectFields.hasKey("movie"), true);
    ArgumentNode fields1 = <ArgumentNode> inputObjectFields.get("author");
    test:assertEquals(fields1.isVariableDefinition(), true);
    test:assertEquals(fields1.getVariableName(), "bAuthor");
    ArgumentNode fields2 = <ArgumentNode> inputObjectFields.get("movie");
    map<ArgumentValue|ArgumentNode> nestedFields = <map<ArgumentValue|ArgumentNode>>fields2.getValue();
    test:assertEquals(nestedFields.hasKey("movieName"), true);
    ArgumentNode innerField = <ArgumentNode> fields2.getValue().get("movieName");
    ArgumentValue nestedValue = <ArgumentValue> innerField.getValue().get("movieName");
    test:assertEquals(nestedValue.value, "End Game");
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testInvalidDirectives1() returns error? {
    string document = "query getId { profile @skip(if:true { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected Name, found "{".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 37);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testInvalidDirectives2() returns error? {
    string document = "query getId { profile @skip(if true) { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Expected ":", found "true".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 32);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testInvalidDirectives3() returns error? {
    string document = "query getId { profile @skip(if:) { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Unexpected ")".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 32);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesWithoutInvalidVariableUsage() returns error? {
    string document = "query getId($skip:Boolean = true ) @skip(if: $skip) { profile { id } }";
    Parser parser = new(document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string`Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 46);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesWithoutVariables() returns error? {
    string document = "query getId{ profile @skip { id } }";
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getSelections().length(), 1);
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> operationNode.getSelections()[0];
    test:assertEquals(fieldNode.getName(), "profile");
    DirectiveNode[] directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getArguments().length(), 0);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesInUndefinedLocations() returns error? {
    string document = check getGraphQLDocumentFromFile("query_type_directives_in_undefined_location.graphql");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    DirectiveNode[] directives = operationNode.getDirectives();
    test:assertEquals(directives.length(), 2);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], QUERY);
    ArgumentNode argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    directive = directives[1];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], QUERY);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");

    map<FragmentNode> fragments = documentNode.getFragments();
    FragmentNode? fragment = fragments.get("p1");
    test:assertTrue(fragment is FragmentNode);
    directives = (<FragmentNode>fragment).getDirectives();
    test:assertEquals(directives.length(), 2);
    directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], FRAGMENT_DEFINITION);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    directive = directives[1];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], FRAGMENT_DEFINITION);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesWithMutation() returns error? {
    string document = check getGraphQLDocumentFromFile("query_type_directives_with_mutation.graphql");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    DirectiveNode[] directives = operationNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], MUTATION);
    ArgumentNode argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    Selection selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode> selection;

    test:assertEquals(fieldNode.getName(), "setName");
    directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    directive = directives[0];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], FIELD);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectives() returns error? {
    string document = check getGraphQLDocumentFromFile("query_type_directives.graphql");
    Parser parser = new(document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);
    FieldNode fieldNode = <FieldNode> operationNode.getSelections()[0];
    Selection selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode> selection;

    test:assertEquals(fieldNode.getName(), "profile");
    DirectiveNode[] directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], FIELD);
    ArgumentNode argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FragmentNode);
    FragmentNode fragmentNode = <FragmentNode> selection;

    test:assertEquals(fragmentNode.getName(), "profile_Person");
    test:assertEquals(fragmentNode.isInlineFragment(), true);
    directives = fragmentNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    directive = directives[0];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], INLINE_FRAGMENT);
    test:assertEquals(directive.getArguments().length(), 1);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    selection = fragmentNode.getSelections()[1];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "address");
    selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FragmentNode);
    fragmentNode = <FragmentNode> selection;

    test:assertEquals(fragmentNode.getName(), "personalAddress");
    test:assertEquals(fragmentNode.isInlineFragment(), false);
    directives = fragmentNode.getDirectives();
    test:assertEquals(directives.length(), 2);
    directive = directives[0];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], FRAGMENT_SPREAD);
    test:assertEquals(directive.getArguments().length(), 1);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    directive = directives[1];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getArguments().length(), 1);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    map<FragmentNode> fragmentsMap = documentNode.getFragments();
    FragmentNode? result = fragmentsMap[fragmentNode.getName()];
    test:assertTrue(result is FragmentNode);
    fragmentNode = <FragmentNode>result;

    selection = fragmentNode.getSelections()[1];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode> selection;
    test:assertEquals(fieldNode.getName(), "street");
    directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 2);
    directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocations().length(), 1);
    test:assertEquals(directive.getDirectiveLocations()[0], FIELD);
    test:assertEquals(directive.getArguments().length(), 1);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    directive = directives[1];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getArguments().length(), 1);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
}
