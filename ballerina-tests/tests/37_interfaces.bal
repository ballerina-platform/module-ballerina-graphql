// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    groups: ["interfaces"]
}
isolated function testInterfaces() returns error? {
    string document = check getGraphQLDocumentFromFile("interfaces.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interfaces.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "introspection"]
}
isolated function testInterfaceIntrospection() returns error? {
    string document = check getGraphQLDocumentFromFile("interface_introspection.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interface_introspection.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces"]
}
isolated function testInterfaceField() returns error? {
    string document = check getGraphQLDocumentFromFile("interface_field.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interface_field.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces"],
    enable: false
}
isolated function testInterfacesWithNestedFragments() returns error? {
    string document = check getGraphQLDocumentFromFile("interfaces_with_nested_fragments.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interfaces_with_nested_fragments.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces"]
}
isolated function testInterfacesWithInvalidField() returns error? {
    string document = check getGraphQLDocumentFromFile("interfaces_with_invalid_field.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("interfaces_with_invalid_field.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces"],
    enable: false
}
isolated function testInterfacesWithTypeNameIntrospection() returns error? {
    string document = check getGraphQLDocumentFromFile("interfaces_with_type_name_introspection.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interfaces_with_type_name_introspection.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "fragments"]
}
isolated function testInterfacesWithInterfaceTypeArray() returns error? {
    string document = check getGraphQLDocumentFromFile("interfaces_with_interface_type_array.graphql");
    string url = "http://localhost:9098/interfaces";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interfaces_with_interface_type_array.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "fragments", "interface-implementing-interfaces"]
}
isolated function testQueryingOnInterface() returns error? {
    string document = check getGraphQLDocumentFromFile("test_quering_on_interface.graphql");
    string url = "http://localhost:9089/interfaces_implementing_interface";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("test_quering_on_interface.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "fragments", "interface-implementing-interfaces"]
}
isolated function testQueryingOnTransitiveType() returns error? {
    string document = check getGraphQLDocumentFromFile("test_querying_on_transitive_type.graphql");
    string url = "http://localhost:9089/interfaces_implementing_interface";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("test_querying_on_transitive_type.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "fragments", "interface-implementing-interfaces"]
}
isolated function testQueryingOnTransitiveTypeAndInterface() returns error? {
    string document = check getGraphQLDocumentFromFile("test_querying_on_transitive_type_and_interface.graphql");
    string url = "http://localhost:9089/interfaces_implementing_interface";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("test_querying_on_transitive_type_and_interface.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "fragments", "interface-implementing-interfaces"]
}
isolated function testQueryingFragmentOnInterface() returns error? {
    string document = check getGraphQLDocumentFromFile("test_querying_fragment_on_transitive_interface.graphql");
    string url = "http://localhost:9089/interfaces_implementing_interface";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("test_querying_fragment_on_transitive_interface.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["interfaces", "fragments", "interface-implementing-interfaces", "instrospection"]
}
isolated function testInterfaceImplementingInterfaceIntrospection() returns error? {
    string document = check getGraphQLDocumentFromFile("interfaces_implementing_interface_introsepction.graphql");
    string url = "http://localhost:9089/interfaces_implementing_interface";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("interfaces_implementing_interface_introsepction.json");
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}
