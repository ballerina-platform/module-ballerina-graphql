// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/websocket;

@test:Config {
    groups: ["constraints"],
    dataProvider: dataProviderConstraintValidation
}
function testConstraintValidation(string url, string documentFileName, string jsonFileName, json variables = (), string? operationName = ()) returns error? {
    string document = check getGraphqlDocumentFromFile(documentFileName);
    json actualPayload = check getJsonPayloadFromService(url, document, variables = variables, operationName = operationName);
    json expectedPayload = check getJsonContentFromFile(jsonFileName);
    assertJsonValuesWithOrder(actualPayload, expectedPayload);
}

function dataProviderConstraintValidation() returns map<[string, string, string, json, string?]> {

    string url1 = "localhost:9091/constraints";
    string url2 = "localhost:9091/constraints_config";

    json var1 = {
        movie: {
            name: "The Green Mile",
            downloads: 12,
            imdb: 1.0,
            reviews: []
        }
    };

    json var2 = {
        movies: [
            {name: "", downloads: 1, imdb: 0.5, reviews:[]},
            {name: "The Shawshank Redemption", downloads: 22, imdb: 9.2, reviews:[null]},
            {name: "Inception", downloads: 3, imdb: 8.7, reviews:[null]}
        ]
    };

    map<[string, string, string, json, string?]> dataSet =
    {
        "1": [url1, "constraints", "constraints", (), "A"],
        "2": [url1, "constraints", "constraints_with_mutation", (), "B"],
        "3": [url1, "constraints", "constraints_with_intersection_types", (), "C"],
        "4": [url1, "constraints", "constraints_with_list_type_inputs", (), "D"],
        "5": [url1, "constraints", "constraints_with_variables_1", var1, "E"],
        "6": [url1, "constraints", "constraints_with_variables_2", var2, "F"],
        "7": [url2, "constraints", "constraints_configuration", (), "A"]
    };
    return dataSet;
}

@test:Config {
    groups: ["constraints", "subscriptions"],
    enable: false
}
isolated function testSubscriptionWithConstraints() returns error? {
    string document = check getGraphqlDocumentFromFile("constraints");
    string url = "ws://localhost:9091/constraints";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient = check new (url, config);
    check initiateGraphqlWsConnection(wsClient);
    check sendSubscriptionMessage(wsClient, document, operationName = "Sub");
    json expectedMsgPayload = check getJsonContentFromFile("constraints_with_subscription");
    check validateErrorMessage(wsClient, expectedMsgPayload);
}

@test:Config {
    groups: ["constraints", "subscriptions"],
    enable: false
}
isolated function testMultipleSubscriptionClientsWithConstraints() returns error? {
    string document = check getGraphqlDocumentFromFile("constraints");
    string url = "ws://localhost:9091/constraints";
    websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
    websocket:Client wsClient1 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient1);
    check sendSubscriptionMessage(wsClient1, document, "1", operationName = "Sub");

    websocket:Client wsClient2 = check new (url, config);
    check initiateGraphqlWsConnection(wsClient2);
    check sendSubscriptionMessage(wsClient2, document, "2", operationName = "Sub");

    json expectedMsgPayload = check getJsonContentFromFile("constraints_with_subscription");
    check validateErrorMessage(wsClient1, expectedMsgPayload, "1");
    check validateErrorMessage(wsClient2, expectedMsgPayload, "2");
}
