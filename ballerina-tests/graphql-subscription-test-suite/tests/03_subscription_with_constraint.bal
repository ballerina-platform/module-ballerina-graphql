// // Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
// //
// // WSO2 LLC. licenses this file to you under the Apache License,
// // Version 2.0 (the "License"); you may not use this file except
// // in compliance with the License.
// // You may obtain a copy of the License at
// //
// // http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing,
// // software distributed under the License is distributed on an
// // "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// // KIND, either express or implied.  See the License for the
// // specific language governing permissions and limitations
// // under the License.

// import ballerina/graphql_test_common as common;
// import ballerina/test;
// import ballerina/websocket;
// import ballerina/io;

// @test:Config {
//     groups: ["constraints", "subscriptions"]
// }
// isolated function testSubscriptionWithConstraints() returns error? {
//     io:println("start testSubscriptionWithConstraints");

//     string document = check common:getGraphqlDocumentFromFile("constraints");
//     string url = "ws://localhost:9091/constraints";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient);
//     check common:sendSubscriptionMessage(wsClient, document, operationName = "Sub");
//     json expectedMsgPayload = check common:getJsonContentFromFile("constraints_with_subscription");
//     check common:validateErrorMessage(wsClient, expectedMsgPayload);
//     io:println("end testSubscriptionWithConstraints");

// }

// @test:Config {
//     groups: ["constraints", "subscriptions"]
// }
// isolated function testMultipleSubscriptionClientsWithConstraints() returns error? {
//     io:println("start testMultipleSubscriptionClientsWithConstraints");

//     string document = check common:getGraphqlDocumentFromFile("constraints");
//     string url = "ws://localhost:9091/constraints";
//     websocket:ClientConfiguration config = {subProtocols: [GRAPHQL_TRANSPORT_WS]};
//     websocket:Client wsClient1 = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient1);
//     check common:sendSubscriptionMessage(wsClient1, document, "1", operationName = "Sub");

//     websocket:Client wsClient2 = check new (url, config);
//     check common:initiateGraphqlWsConnection(wsClient2);
//     check common:sendSubscriptionMessage(wsClient2, document, "2", operationName = "Sub");

//     json expectedMsgPayload = check common:getJsonContentFromFile("constraints_with_subscription");
//     check common:validateErrorMessage(wsClient1, expectedMsgPayload, "1");
//     check common:validateErrorMessage(wsClient2, expectedMsgPayload, "2");
//     io:println("end testMultipleSubscriptionClientsWithConstraints");

// }
