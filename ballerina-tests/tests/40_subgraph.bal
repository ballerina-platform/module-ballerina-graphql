// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/graphql;
import ballerina/test;

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testSubgrapWithValidQuery() returns error? {
    string document = string `{ greet }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = {data: {greet: "welcome"}};
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldOnSubgraph() returns error? {
    string document = check getGraphQLDocumentFromFile("quering_entity_field_on_subgrap.graphql");
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = {
        data: {
            _entities: [
                {name: "Acamar", constellation: "Acamar", designation: "θ1 Eridani A"},
                {name: "Earth", mass: 1}
            ]
        }
    };
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithNullArgument() returns error? {
    string document = string `{ _entities( representations: null ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json|error response = graphqlClient->execute(document);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `Expected value of type "[_Any!]!", found null.`;
    json locations = [{line: 1, column: 31}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithListOfNullValues() returns error? {
    string document = string `{ _entities( representations: [null] ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json|error response = graphqlClient->execute(document);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `_Any! cannot represent non _Any! value: null`;
    json locations = [{line: 1, column: 32}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithListOfNonAnyArgument() returns error? {
    string document = string `{ _entities( representations: [1, "string", 1.23] ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json|error response = graphqlClient->execute(document);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    json expectedErrorDetail = [
        {
            message: string `representations: In element #0: "_Any!" cannot represent non _Any! value: "1"`,
            locations: [{line: 1, column: 32}]
        },
        {
            message: string `representations: In element #1: "_Any!" cannot represent non _Any! value: "string"`,
            locations: [{line: 1, column: 35}]
        },
        {
            message: string `representations: In element #2: "_Any!" cannot represent non _Any! value: "1.23"`,
            locations: [{line: 1, column: 45}]
        }
    ];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithoutTypenameInArgument() returns error? {
    string document = string `{ _entities( representations: [ { name: "Acamar" } ] ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json|error response = graphqlClient->execute(document);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `representations: In element #0: "_Any!" cannot represent non _Any! value:` +
        string ` "__typename" field is absent`;
    json locations = [{line: 1, column: 35}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithObjectArgument() returns error? {
    string document = string `{ _entities( representations: { name: "Acamar" } ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json|error response = graphqlClient->execute(document);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `[_Any!]! cannot represent non [_Any!]! value: {name: "Acamar"}`;
    json locations = [{line: 1, column: 14}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithNullVariable() returns error? {
    string document = string `query ($rep: [_Any!]!) { _entities( representations: $rep ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {rep: null};
    json|error response = graphqlClient->execute(document, variables);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `Variable rep expected value of type "[_Any!]!", found null`;
    json locations = [{line: 1, column: 55}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithLisOfNullVariable() returns error? {
    string document = string `query ($rep: [_Any!]!) { _entities( representations: $rep ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {rep: [null]};
    json|error response = graphqlClient->execute(document, variables);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `representations: In element #0:Expected value of type "_Any!", found null.`;
    json locations = [{line: 1, column: 55}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithListOfNonAnyVariable() returns error? {
    string document = string `query ($rep: [_Any!]!) { _entities( representations: $rep ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {rep: [1, "string", 1.23]};
    json|error response = graphqlClient->execute(document, variables);
    test:assertTrue(response is graphql:InvalidDocumentError);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    json expectedErrorDetail = [
        {
            message: string `representations: In element #0: "_Any" cannot represent non _Any value: "1"`,
            locations: [{line: 1, column: 55}]
        },
        {
            message: string `representations: In element #1: "_Any" cannot represent non _Any value: "string"`,
            locations: [{line: 1, column: 55}]
        },
        {
            message: string `representations: In element #2: "_Any" cannot represent non _Any value: "1.23"`,
            locations: [{line: 1, column: 55}]
        }
    ];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithoutTypenameInVariable() returns error? {
    string document = string `query ($rep: [_Any!]!) { _entities( representations: $rep ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {rep: [{name: "Acamar"}]};
    json|error response = graphqlClient->execute(document, variables);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `representations: In element #0: "_Any" cannot represent non _Any value: ` +
                    string `"__typename" field is absent`;
    json locations = [{line: 1, column: 55}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithObjectVariable() returns error? {
    string document = string `query ($rep: [_Any!]!) { _entities( representations: $rep ) { ... on Star { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {rep: {name: "Acamar"}};
    json|error response = graphqlClient->execute(document, variables);
    graphql:InvalidDocumentError err = <graphql:InvalidDocumentError>response;
    string message = string `[_Any!]! cannot represent non [_Any!]! value: {"name":"Acamar"}`;
    json locations = [{line: 1, column: 55}];
    json expectedErrorDetail = [{message, locations}];
    test:assertEquals(err.detail().errors.toJson(), expectedErrorDetail);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testQueringEntityFieldWithVariableOnSubgraph() returns error? {
    string document = check getGraphQLDocumentFromFile("quering_entity_field_with_variable_on_subgrap.graphql");
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {
        representations: [
            {__typename: "Star", name: "Acamar"},
            {__typename: "Planet", name: "Earth"}
        ]
    };
    json response = check graphqlClient->execute(document, variables);
    json expectedPayload = {
        data: {
            _entities: [
                {name: "Acamar", constellation: "Acamar", designation: "θ1 Eridani A"},
                {name: "Earth", mass: 1}
            ]
        }
    };
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity", "introspection"]
}
isolated function testIntrospectionOnSubgraph() returns error? {
    string document = check getGraphQLDocumentFromFile("introspection_on_subgraph.graphql");
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    map<json> variables = {
        representations: [
            {__typename: "Star", name: "Acamar"},
            {__typename: "Star", name: "Absolutno*"}
        ]
    };
    json response = check graphqlClient->execute(document, variables);
    json expectedPayload = check getJsonContentFromFile("introspection_on_subgraph.json");
    test:assertEquals(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testEntitiesResolverReturnigNullValue() returns error? {
    string document = string `{ _entities( representations: [{__typename:"Planet"}] ) { ... on Planet { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = {data: {_entities: [null]}};
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity", "introspection"]
}
isolated function testQueringSdlOnSubgraph() returns error? {
    string document = string `{ _service { sdl } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("quering_sdl_on_subgraph.json");
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testResolverReturnigErrorForInvalidEntity() returns error? {
    string document = string `{ _entities( representations: [{__typename:"Invalid"}] ) { ... on Planet { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = check getJsonContentFromFile("resolver_returnig_error_for_invalid_entity.json");
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testResolverReturnigErrorForUnRsolvableEntity() returns error? {
    string document = string `{ _entities( representations: [{__typename:"Moon"}] ) { ... on Moon { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = {
        errors: [
            {
                message: "No resolvers defined for 'Moon' entity",
                locations: [{line: 1, column: 3}],
                path: ["_entities", 0]
            }
        ],
        data: {_entities: [null]}
    };
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
isolated function testResolverReturnigErrorForInvalidReturnType() returns error? {
    string document = string `{ _entities( representations: [{__typename:"Satellite"}] ) { ... on Satellite { name } } }`;
    string url = "localhost:9088/subgraph";
    graphql:Client graphqlClient = check new (url);
    json response = check graphqlClient->execute(document);
    json expectedPayload = {
        errors: [
            {
                message: "Incorrect return type specified for the 'Satellite' entity reference resolver.",
                locations: [{line: 1, column: 3}],
                "path": ["_entities", 0]
            }
        ],
        data: {_entities: [null]}
    };
    assertJsonValuesWithOrder(response, expectedPayload);
}

@test:Config {
    groups: ["federation", "subgraph", "entity"]
}
function testAttachingSubgraphServiceToDynamicListener() returns error? {
    check specialTypesTestListener.attach(subgraphServivce, "subgraph");
    string url = "http://localhost:9095/subgraph";
    graphql:Client graphqlClient = check new (url);
    string document = check getGraphQLDocumentFromFile("quering_entity_field_on_subgrap.graphql");
    json response = check graphqlClient->execute(document);
    json expectedPayload = {
        data: {
            _entities: [
                {name: "Acamar", constellation: "Acamar", designation: "θ1 Eridani A"},
                {name: "Earth", mass: 1}
            ]
        }
    };
    check specialTypesTestListener.detach(subgraphServivce);
    assertJsonValuesWithOrder(response, expectedPayload);
}
