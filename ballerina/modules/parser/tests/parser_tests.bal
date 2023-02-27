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
    string document = string `fragment friendFields on User`;
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected "{", found <EOF>.`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testInvalidFragmentMissingOnKeyword() returns error? {
    string document = string `fragment friendFields o User`;
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected "on", found Name "o".`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["fragments", "parser"]
}
isolated function testInvalidFragmentInvalidTypeType() returns error? {
    string document = string `fragment friendFields on "User"`;
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected Name, found String "User".`;
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
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    OperationNode[] operations = documentNode.getOperations();
    test:assertEquals(operations.length(), 1);
    OperationNode operationNode = operations[0];
    SelectionNode[] selections = operationNode.getSelections();
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
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected Name "on".`;
    test:assertEquals(err.message(), expectedMessage);
}

@test:Config {
    groups: ["operations", "parser"]
}
isolated function testMultipleAnonymousOperations() returns error? {
    string document = check getGraphqlDocumentFromFile("multiple_anonymous_operations");
    Parser parser = new (document);
    _ = check parser.parse();
    ErrorDetail[] errors = parser.getErrors();
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
    Parser parser = new (document);
    _ = check parser.parse();
    ErrorDetail[] errors = parser.getErrors();
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
    string document = check getGraphqlDocumentFromFile("named_operation_with_anonymous_operation");
    Parser parser = new (document);
    _ = check parser.parse();
    ErrorDetail[] errors = parser.getErrors();
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
    string document = check getGraphqlDocumentFromFile("named_operation_with_multiple_anonymous_operations");
    Parser parser = new (document);
    _ = check parser.parse();
    ErrorDetail[] errors = parser.getErrors();
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
    string document = check getGraphqlDocumentFromFile("three_anonymous_operations");
    Parser parser = new (document);
    _ = check parser.parse();
    ErrorDetail[] errors = parser.getErrors();
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
    string document = check getGraphqlDocumentFromFile("multiple_operations_with_same_name");
    Parser parser = new (document);
    _ = check parser.parse();
    ErrorDetail[] errors = parser.getErrors();
    test:assertEquals(errors.length(), 2);
    ErrorDetail e1 = {
        message: string `There can be only one operation named "getData".`,
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
        message: string `There can be only one operation named "getData".`,
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
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    OperationNode[] operations = documentNode.getOperations();
    test:assertEquals(operations.length(), 1);
    OperationNode operationNode = operations[0];
    test:assertEquals(operationNode.getKind(), OPERATION_MUTATION);
    test:assertEquals(operationNode.getName(), ANONYMOUS_OPERATION);
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "setAge");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "newAge");
    test:assertEquals(<Scalar>argumentNode.getValue(), 24);
    test:assertEquals(fieldNode.getSelections().length(), 2);
    test:assertEquals((<FieldNode>fieldNode.getSelections()[0]).getName(), "name");
    test:assertEquals((<FieldNode>fieldNode.getSelections()[1]).getName(), "age");
}

@test:Config {
    groups: ["operations", "parser", "mutation"]
}
isolated function testParseNamedMutation() returns error? {
    string document = "mutation SetAge { setAge(newAge: 24) { name, age } }";
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    OperationNode[] operations = documentNode.getOperations();
    test:assertEquals(operations.length(), 1);
    OperationNode operationNode = operations[0];
    test:assertEquals(operationNode.getKind(), OPERATION_MUTATION);
    test:assertEquals(operationNode.getName(), "SetAge");
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "setAge");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "newAge");
    test:assertEquals(<Scalar>argumentNode.getValue(), 24);
    test:assertEquals(fieldNode.getSelections().length(), 2);
    test:assertEquals((<FieldNode>fieldNode.getSelections()[0]).getName(), "name");
    test:assertEquals((<FieldNode>fieldNode.getSelections()[1]).getName(), "age");
}

@test:Config {
    groups: ["validation", "parser"]
}
isolated function testMissingArgumentValue() returns error? {
    string document = "{ profile(id: ) { name age }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string `Syntax Error: Unexpected ")".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 15);
}

@test:Config {
    groups: ["validation", "parser"]
}
isolated function testEmptyDocument() returns error? {
    string document = "{ }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string `Syntax Error: Expected Name, found "}".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 3);
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testFieldAlias() returns error? {
    string document = "{ firstName: name }";
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
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
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
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
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string `Syntax Error: Expected Name, found "}".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 28);
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testInvalidFieldAliasWithoutAlias() returns error? {
    string document = "query getName { : name }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is Error);
    Error err = <Error>result;
    test:assertEquals(err.message(), string `Syntax Error: Expected Name, found ":".`);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 17);
}

@test:Config {
    groups: ["alias", "parser"]
}
isolated function testFieldAliasInsideField() returns error? {
    string document = "query getName { profile { firstName: name } }";
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getSelections().length(), 1);
    selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode>selection;
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
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = <OperationNode>documentNode.getOperations()[0];
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    string name = fieldNode.getName();
    test:assertEquals(name, "profile");
    string alias = fieldNode.getAlias();
    test:assertEquals(alias, "walt");
    test:assertEquals(fieldNode.getArguments().length(), 1);
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "id");
    test:assertEquals(<Scalar>argumentNode.getValue(), 1);
}

@test:Config {
    groups: ["variables", "parser"]
}
isolated function testVariables() returns error? {
    string document = "query getName($profileId:Int = 3) { profile(id:$profileId) { name } }";
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 1);
    VariableNode variableNode = <VariableNode>operationNode.getVaribleDefinitions()["profileId"];
    test:assertEquals(variableNode.getName(), "profileId");
    test:assertEquals(variableNode.getTypeName(), "Int");
    ArgumentNode argValueNode = <ArgumentNode>variableNode.getDefaultValue();
    ArgumentValue argValue = <ArgumentValue>argValueNode.getValue();
    test:assertEquals(<Scalar>argValue, 3);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
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
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);
    VariableNode variableNode = <VariableNode>operationNode.getVaribleDefinitions()["name"];
    test:assertEquals(variableNode.getName(), "name");
    test:assertEquals(variableNode.getTypeName(), "String!");
    variableNode = <VariableNode>operationNode.getVaribleDefinitions()["age"];
    test:assertEquals(variableNode.getName(), "age");
    test:assertEquals(variableNode.getTypeName(), "Int!");
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
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
    string document = "query getId($name: [[[String!]]!]!) { profile(userName:$name) { id } }";
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 1);
    VariableNode variableNode = <VariableNode>operationNode.getVaribleDefinitions()["name"];
    test:assertEquals(variableNode.getName(), "name");
    test:assertEquals(variableNode.getTypeName(), "[[[String!]]!]!");
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
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
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected "$", found "]".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 27);
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testInvalidListTypeVariableMissingCloseBracket() returns error? {
    string document = "query getId($name: [String![) { profile(userName:$name) { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected "]", found "[".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 28);
}

@test:Config {
    groups: ["variables", "list", "parser"]
}
isolated function testEmptyListTypeVariable() returns error? {
    string document = "query getId($name: []) { profile(userName:$name) { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected Name, found "]".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 21);
}

@test:Config {
    groups: ["list", "parser"]
}
isolated function testInvalidListTypeArgument() returns error? {
    string document = string `query { profile(userNames:["Sherlock", "Walter") { id } }`;
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected ")".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 48);
}

@test:Config {
    groups: ["list", "variables", "parser"]
}

isolated function testListWithInvalidDefaultValue() returns error? {
    string document = string `query ($detail:Data = [$name, "Sherlock"]) { getId(data: $detail) { id } }`;
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 24);
}

@test:Config {
    groups: ["list", "parser"]
}
isolated function testListTypeArgument() returns error? {
    string document = string `query { profile(userNames:["Sherlock", 1, true, 3.4]) { id } }`;
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "userNames");
    test:assertEquals(argumentNode.getKind(), T_LIST);
    ArgumentValue[] argumentValue = <ArgumentValue[]>argumentNode.getValue();
    test:assertEquals((argumentValue).length(), 4);

    ArgumentNode listItem = <ArgumentNode>argumentValue[0];
    test:assertEquals(listItem.getKind(), T_STRING);
    ArgumentValue listItemValue = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>listItemValue, "Sherlock");

    listItem = <ArgumentNode>argumentValue[1];
    test:assertEquals(listItem.getKind(), T_INT);
    listItemValue = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>listItemValue, 1);

    listItem = <ArgumentNode>argumentValue[2];
    test:assertEquals(listItem.getKind(), T_BOOLEAN);
    listItemValue = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>listItemValue, true);

    listItem = <ArgumentNode>argumentValue[3];
    test:assertEquals(listItem.getKind(), T_FLOAT);
    listItemValue = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>listItemValue, 3.4);
}

@test:Config {
    groups: ["list", "parser"]
}
isolated function testListTypeArgumentWithNestedLists() returns error? {
    string document = string `query { profile(userNames:[["Sherlock"], [1], [[false]]]) { id } }`;
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "userNames");
    test:assertEquals(argumentNode.getKind(), T_LIST);
    ArgumentValue[] argumentValue = <ArgumentValue[]>argumentNode.getValue();
    test:assertEquals(argumentValue.length(), 3);

    ArgumentNode listItem = <ArgumentNode>argumentValue[0];
    test:assertEquals(argumentNode.getKind(), T_LIST);
    ArgumentValue[] listItemValue = <ArgumentValue[]>listItem.getValue();
    ArgumentNode innerListItem = <ArgumentNode>listItemValue[0];
    test:assertEquals(innerListItem.getKind(), T_STRING);
    ArgumentValue innerListItemValue = <ArgumentValue>innerListItem.getValue();
    test:assertEquals(<Scalar>innerListItemValue, "Sherlock");

    listItem = <ArgumentNode>argumentValue[1];
    test:assertEquals(argumentNode.getKind(), T_LIST);
    listItemValue = <ArgumentValue[]>listItem.getValue();
    test:assertEquals(listItemValue.length(), 1);
    innerListItem = <ArgumentNode>listItemValue[0];
    test:assertEquals(innerListItem.getKind(), T_INT);
    innerListItemValue = <ArgumentValue>innerListItem.getValue();
    test:assertEquals(<Scalar>innerListItemValue, 1);

    listItem = <ArgumentNode>argumentValue[2];
    test:assertEquals(argumentNode.getKind(), T_LIST);
    listItemValue = <ArgumentValue[]>listItem.getValue();
    test:assertEquals(listItemValue.length(), 1);
    innerListItem = <ArgumentNode>listItemValue[0];
    test:assertEquals(innerListItem.getKind(), T_LIST);
    listItemValue = <ArgumentValue[]>innerListItem.getValue();
    test:assertEquals(listItemValue.length(), 1);
    innerListItem = <ArgumentNode>listItemValue[0];
    test:assertEquals(innerListItem.getKind(), T_BOOLEAN);
    innerListItemValue = <ArgumentValue>innerListItem.getValue();
    test:assertEquals(<Scalar>innerListItemValue, false);
}

@test:Config {
    groups: ["list", "variables", "parser"]
}

isolated function testListTypeArgumentWithVariables() returns error? {
    string document = string `query { profile(userNames:["Sherlock", $name, $user]) { id } }`;
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "userNames");
    test:assertEquals(argumentNode.getKind(), T_LIST);
    ArgumentValue[] argumentValue = <ArgumentValue[]>argumentNode.getValue();
    test:assertEquals(argumentValue.length(), 3);

    ArgumentNode listItem = <ArgumentNode>argumentValue[0];
    ArgumentValue listItemValue = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>listItemValue, "Sherlock");

    ArgumentNode variableListItem = <ArgumentNode>argumentValue[1];
    test:assertTrue(variableListItem.isVariableDefinition());
    test:assertEquals(variableListItem.getVariableName(), "name");

    variableListItem = <ArgumentNode>argumentValue[2];
    test:assertTrue(variableListItem.isVariableDefinition());
    test:assertEquals(variableListItem.getVariableName(), "user");
}

@test:Config {
    groups: ["list", "input_objects", "variables", "parser"]
}

isolated function testListTypeWithinInputObjectVariableDefualtValue() returns error? {
    string document = string `query ($userDetails: UserDetails = {name: "Jessie", friends: ["walter", null]}){ profile(details: $userDetails) { id } }`;
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];

    VariableNode variableNode = <VariableNode>operationNode.getVaribleDefinitions()["userDetails"];
    test:assertEquals(variableNode.getName(), "userDetails");
    test:assertEquals(variableNode.getTypeName(), "UserDetails");
    ArgumentNode argValue = <ArgumentNode>variableNode.getDefaultValue();
    test:assertEquals(argValue.getKind(), T_INPUT_OBJECT);
    test:assertEquals(argValue.getName(), "userDetails");
    ArgumentValue[] defaultValue = <ArgumentValue[]>argValue.getValue();
    test:assertEquals(defaultValue.length(), 2);

    ArgumentNode field1 = <ArgumentNode>defaultValue[0];
    test:assertEquals(field1.getKind(), T_STRING);
    ArgumentValue field1Value = <ArgumentValue>field1.getValue();
    test:assertEquals(<Scalar>field1Value, "Jessie");

    ArgumentNode field2 = <ArgumentNode>defaultValue[1];
    test:assertEquals(field2.getKind(), T_LIST);
    ArgumentValue[] field2Value = <ArgumentValue[]>field2.getValue();
    test:assertEquals(field2Value.length(), 2);
    ArgumentNode innerField = <ArgumentNode>field2Value[0];
    ArgumentValue innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<Scalar>innerFieldValue, "walter");
    innerField = <ArgumentNode>field2Value[1];
    innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<null>innerFieldValue, null);
}

@test:Config {
    groups: ["list", "variables", "parser"]
}

isolated function testListTypeVariablesWithDefualtValue() returns error? {
    string document = check getGraphqlDocumentFromFile("list_type_variables_with_default_value");
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);

    VariableNode variableNode = <VariableNode>operationNode.getVaribleDefinitions()["bName"];
    test:assertEquals(variableNode.getName(), "bName");
    test:assertEquals(variableNode.getTypeName(), "[[String]!]");
    ArgumentNode argValue = <ArgumentNode>variableNode.getDefaultValue();
    test:assertEquals(argValue.getKind(), T_LIST);
    test:assertEquals(argValue.getName(), "bName");
    ArgumentValue[] defaultValue = <ArgumentValue[]>argValue.getValue();
    test:assertEquals(defaultValue.length(), 2);

    ArgumentNode field1 = <ArgumentNode>defaultValue[0];
    test:assertEquals(field1.getKind(), T_LIST);
    ArgumentValue[] field1Value = <ArgumentValue[]>field1.getValue();
    ArgumentNode innerField = <ArgumentNode>field1Value[0];
    ArgumentValue innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<Scalar>innerFieldValue, "Harry");

    ArgumentNode field2 = <ArgumentNode>defaultValue[1];
    test:assertEquals(field2.getKind(), T_LIST);
    ArgumentValue[] field2Value = <ArgumentValue[]>field2.getValue();
    test:assertEquals(field2Value.length(), 3);
    innerField = <ArgumentNode>field2Value[0];
    innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<Scalar>innerFieldValue, "SUNDAY");
    innerField = <ArgumentNode>field2Value[1];
    innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<null>innerFieldValue, null);
    innerField = <ArgumentNode>field2Value[2];
    innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<Scalar>innerFieldValue, false);

    variableNode = <VariableNode>operationNode.getVaribleDefinitions()["bAuthor"];
    test:assertEquals(variableNode.getName(), "bAuthor");
    test:assertEquals(variableNode.getTypeName(), "[ProfileDetail!]");
    argValue = <ArgumentNode>variableNode.getDefaultValue();
    test:assertEquals(argValue.getKind(), T_LIST);
    test:assertEquals(argValue.getName(), "bAuthor");
    defaultValue = <ArgumentValue[]>argValue.getValue();
    test:assertEquals(defaultValue.length(), 1);

    ArgumentNode 'field = <ArgumentNode>defaultValue[0];
    test:assertEquals('field.getKind(), T_INPUT_OBJECT);
    ArgumentValue[] fieldValue = <ArgumentValue[]>'field.getValue();
    innerField = <ArgumentNode>fieldValue[0];
    innerFieldValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<Scalar>innerFieldValue, "J.K Rowling");
}

@test:Config {
    groups: ["list", "input_objects", "parser"]
}

isolated function testListTypeArgumentWithInputObjects() returns error? {
    string document = string `query { profile(userNames:[{age: $age, name: "Jessie" }, {}]) { id } }`;
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "profile");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "userNames");
    test:assertEquals(argumentNode.getKind(), T_LIST);
    ArgumentValue[] argumentValue = <ArgumentValue[]>argumentNode.getValue();
    test:assertEquals(argumentValue.length(), 2);

    ArgumentNode inputObjectListItem = <ArgumentNode>argumentValue[0];
    test:assertEquals(inputObjectListItem.getKind(), T_INPUT_OBJECT);
    ArgumentValue[] fields = <ArgumentValue[]>inputObjectListItem.getValue();
    test:assertEquals(fields.length(), 2);
    ArgumentNode field1 = <ArgumentNode>fields[0];
    test:assertEquals(field1.isVariableDefinition(), true);
    test:assertEquals(field1.getVariableName(), "age");
    ArgumentNode field2 = <ArgumentNode>fields[1];
    ArgumentValue field2Value = <ArgumentValue>field2.getValue();
    test:assertEquals(<Scalar>field2Value, "Jessie");

    inputObjectListItem = <ArgumentNode>argumentValue[1];
    test:assertEquals(inputObjectListItem.getKind(), T_INPUT_OBJECT);
    fields = <ArgumentValue[]>inputObjectListItem.getValue();
    test:assertEquals(fields.length(), 0);
}

@test:Config {
    groups: ["list", "directives", "parser"]
}
isolated function testListTypeArgumentsInDirecitves() returns error? {
    string document = string `query { user @skip(if:["Sherlock", { name: $name}, SUNDAY]){ name, age } }`;
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "user");
    DirectiveNode[] directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getArguments().length(), 1);
    ArgumentNode directiveArgument = directive.getArguments()[0];
    test:assertEquals(directiveArgument.getName(), "if");
    test:assertEquals(directiveArgument.getKind(), T_LIST);
    ArgumentValue[] argumentValues = <ArgumentValue[]>directiveArgument.getValue();
    test:assertEquals(argumentValues.length(), 3);

    ArgumentNode listItem = <ArgumentNode>argumentValues[0];
    ArgumentValue listItemValue = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>listItemValue, "Sherlock");

    listItem = <ArgumentNode>argumentValues[1];
    test:assertEquals(listItem.getKind(), T_INPUT_OBJECT);
    ArgumentValue[] inputObjectFields = <ArgumentValue[]>listItem.getValue();
    test:assertEquals(inputObjectFields.length(), 1);
    ArgumentNode inputObjectFieldValue = <ArgumentNode>inputObjectFields[0];
    test:assertEquals(inputObjectFieldValue.getName(), "name");
    test:assertTrue(inputObjectFieldValue.isVariableDefinition());
    test:assertEquals(inputObjectFieldValue.getVariableName(), "name");

    listItem = <ArgumentNode>argumentValues[2];
    test:assertEquals(listItem.getKind(), T_IDENTIFIER);
    ArgumentValue value = <ArgumentValue>listItem.getValue();
    test:assertEquals(<Scalar>value, "SUNDAY");
}

@test:Config {
    groups: ["variables", "parser"]
}
isolated function testVariablesWithInvalidDefaultValue() returns error? {
    string document = "query getId($name: String = $name) { profile(userName:$name) { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 29);
}

@test:Config {
    groups: ["variables", "input_objects", "parser"]
}
isolated function testInputObjectWithInvalidVariableDefaultValue() returns error? {
    string document = check getGraphqlDocumentFromFile("input_object_with_invalid_variable_default_value");
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 91);
}

@test:Config {
    groups: ["input_objects", "parser"]
}
isolated function testInputObjects() returns error? {
    string document = check getGraphqlDocumentFromFile("input_object_with_default_value");
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);
    VariableNode variableNode = <VariableNode>operationNode.getVaribleDefinitions()["bAuthor"];
    test:assertEquals(variableNode.getName(), "bAuthor");
    test:assertEquals(variableNode.getTypeName(), "ProfileDetail");
    ArgumentNode argValue = <ArgumentNode>variableNode.getDefaultValue();
    test:assertEquals(argValue.getKind(), T_INPUT_OBJECT);
    test:assertEquals(argValue.getName(), "bAuthor");
    ArgumentValue[] defaultValue = <ArgumentValue[]>argValue.getValue();
    test:assertEquals(defaultValue.length(), 1);
    ArgumentNode argField = <ArgumentNode>defaultValue[0];
    ArgumentValue defaultValueField = <ArgumentValue>argField.getValue();
    test:assertEquals(<Scalar>defaultValueField, "J.K Rowling");
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "book");
    ArgumentNode argumentNode = fieldNode.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "info");
    ArgumentValue[] inputObjectFields = <ArgumentValue[]>argumentNode.getValue();
    ArgumentNode field1 = <ArgumentNode>inputObjectFields[2];
    test:assertEquals(field1.isVariableDefinition(), true);
    test:assertEquals(field1.getVariableName(), "bAuthor");
    ArgumentNode field2 = <ArgumentNode>inputObjectFields[3];
    ArgumentValue[] nestedFields = <ArgumentValue[]>field2.getValue();
    test:assertEquals(nestedFields.length(), 1);
    ArgumentNode innerField = <ArgumentNode>nestedFields[0];
    ArgumentValue nestedValue = <ArgumentValue>innerField.getValue();
    test:assertEquals(<Scalar>nestedValue, "End Game");
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testInvalidDirectives1() returns error? {
    string document = "query getId { profile @skip(if:true { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected Name, found "{".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 37);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testInvalidDirectives2() returns error? {
    string document = "query getId { profile @skip(if true) { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Expected ":", found "true".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 32);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testInvalidDirectives3() returns error? {
    string document = "query getId { profile @skip(if:) { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected ")".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 32);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesWithoutInvalidVariableUsage() returns error? {
    string document = "query getId($skip:Boolean = true ) @skip(if: $skip) { profile { id } }";
    Parser parser = new (document);
    DocumentNode|Error result = parser.parse();
    test:assertTrue(result is InvalidTokenError);
    InvalidTokenError err = <InvalidTokenError>result;
    string expectedMessage = string `Syntax Error: Unexpected "$".`;
    test:assertEquals(err.message(), expectedMessage);
    test:assertEquals(err.detail()["line"], 1);
    test:assertEquals(err.detail()["column"], 46);
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesWithoutVariables() returns error? {
    string document = "query getId{ profile @skip { id } }";
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getSelections().length(), 1);
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>operationNode.getSelections()[0];
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
    string document = check getGraphqlDocumentFromFile("query_type_directives_in_undefined_location");
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    DirectiveNode[] directives = operationNode.getDirectives();
    test:assertEquals(directives.length(), 2);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocation(), QUERY);
    ArgumentNode argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    directive = directives[1];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocation(), QUERY);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");

    map<FragmentNode> fragments = documentNode.getFragments();
    FragmentNode? fragment = fragments.get("p1");
    test:assertTrue(fragment is FragmentNode);
    directives = (<FragmentNode>fragment).getDirectives();
    test:assertEquals(directives.length(), 2);
    directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocation(), FRAGMENT_DEFINITION);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    directive = directives[1];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocation(), FRAGMENT_DEFINITION);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectivesWithMutation() returns error? {
    string document = check getGraphqlDocumentFromFile("query_type_directives_with_mutation");
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    DirectiveNode[] directives = operationNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocation(), MUTATION);
    ArgumentNode argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    SelectionNode selection = operationNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    FieldNode fieldNode = <FieldNode>selection;

    test:assertEquals(fieldNode.getName(), "setName");
    directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    directive = directives[0];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocation(), FIELD);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
}

@test:Config {
    groups: ["directives", "parser"]
}
isolated function testDirectives() returns error? {
    string document = check getGraphqlDocumentFromFile("query_type_directives");
    Parser parser = new (document);
    DocumentNode documentNode = check parser.parse();
    test:assertEquals(documentNode.getOperations().length(), 1);
    OperationNode operationNode = documentNode.getOperations()[0];
    test:assertEquals(operationNode.getVaribleDefinitions().length(), 2);
    FieldNode fieldNode = <FieldNode>operationNode.getSelections()[0];
    SelectionNode selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode>selection;

    test:assertEquals(fieldNode.getName(), "profile");
    DirectiveNode[] directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    DirectiveNode directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocation(), FIELD);
    ArgumentNode argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    test:assertEquals(argumentNode.isVariableDefinition(), true);
    selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FragmentNode);
    FragmentNode fragmentNode = <FragmentNode>selection;

    test:assertEquals(fragmentNode.getName(), "profile_Person");
    test:assertEquals(fragmentNode.isInlineFragment(), true);
    directives = fragmentNode.getDirectives();
    test:assertEquals(directives.length(), 1);
    directive = directives[0];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocation(), INLINE_FRAGMENT);
    test:assertEquals(directive.getArguments().length(), 1);
    argumentNode = directive.getArguments()[0];
    test:assertEquals(argumentNode.getName(), "if");
    selection = fragmentNode.getSelections()[1];
    test:assertTrue(selection is FieldNode);
    fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "address");
    selection = fieldNode.getSelections()[0];
    test:assertTrue(selection is FragmentNode);
    fragmentNode = <FragmentNode>selection;

    test:assertEquals(fragmentNode.getName(), "personalAddress");
    test:assertEquals(fragmentNode.isInlineFragment(), false);
    directives = fragmentNode.getDirectives();
    test:assertEquals(directives.length(), 2);
    directive = directives[0];
    test:assertEquals(directive.getName(), "include");
    test:assertEquals(directive.getDirectiveLocation(), FRAGMENT_SPREAD);
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
    fieldNode = <FieldNode>selection;
    test:assertEquals(fieldNode.getName(), "street");
    directives = fieldNode.getDirectives();
    test:assertEquals(directives.length(), 2);
    directive = directives[0];
    test:assertEquals(directive.getName(), "skip");
    test:assertEquals(directive.getDirectiveLocation(), FIELD);
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
