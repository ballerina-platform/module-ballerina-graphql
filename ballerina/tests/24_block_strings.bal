// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    groups: ["block_strings"]
}
isolated function testBlockStrings() returns error? {
    string document = check getGraphQLDocumentFromFile("block_strings.graphql");
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("block_strings.json");
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["block_strings"]
}
isolated function testBlockStringsWithVariableDefaultValue() returns error? {
    string document = check getGraphQLDocumentFromFile("block_strings_with_variable_default_value.graphql");
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("block_strings_with_variable_default_value.json");
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["block_strings"]
}
isolated function testInvalidBlockStrings() returns error? {
    string document = check getGraphQLDocumentFromFile("invalid_block_strings.graphql");
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromBadRequest(url, document);
    json expectedPayload = check getJsonContentFromFile("invalid_block_strings.json");
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["block_strings"]
}
isolated function testBlockStringsWithEscapedCharacter() returns error? {
    string document = check getGraphQLDocumentFromFile("block_strings_with_escaped_character.graphql");
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("block_strings_with_escaped_character.json");
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["block_strings"]
}
isolated function testBlockStringsWithDoubleQuotes() returns error? {
    string document = check getGraphQLDocumentFromFile("block_strings_with_double_quotes.graphql");
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = check getJsonContentFromFile("block_strings_with_double_quotes.json");
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["block_strings"]
}
isolated function testEmptyString() returns error? {
    string document = string`{ sendEmail(message: "") }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            sendEmail:""
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["block_strings"]
}
isolated function testEmptyBlockString() returns error? {
    string document = string`{ sendEmail(message: """""") }`;
    string url = "http://localhost:9091/inputs";
    json actualPayload = check getJsonPayloadFromService(url, document);
    json expectedPayload = {
        data:{
            sendEmail:""
        }
    };
    test:assertEquals(actualPayload, expectedPayload);
}
