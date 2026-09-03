// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/jballerina.java;
import ballerina/uuid;

# The Ballerina GraphQL client that can be used to communicate with GraphQL APIs.
public isolated client class Client {
    final http:Client httpClient;
    final SubscriptionConnection subscriptionConnection;

    # Gets invoked to initialize the `connector`.
    #
    # + serviceUrl - URL of the target service
    # + clientConfig - The configurations to be used when initializing the `connector`
    # + return - An error at the failure of client initialization
    public isolated function init(string serviceUrl, *ClientConfiguration clientConfig) returns ClientError? {
        http:ClientConfiguration httpClientConfig = toHttpClientConfig(clientConfig);
        httpClientConfig.httpVersion = http:HTTP_1_1;
        http:Client|http:ClientError httpClient = new (serviceUrl, httpClientConfig);
        if httpClient is http:ClientError {
             return error HttpError("GraphQL Client Error", httpClient, body = ());
        }
        self.httpClient = httpClient;
        WebSocketConfiguration subscriptionConfig = clientConfig.subscription ?: {};
        check validateReconnectConfig(subscriptionConfig.reconnect);
        check validateKeepAliveConfig(subscriptionConfig.keepAlive);
        string webSocketServiceUrl = check resolveWebSocketServiceUrl(subscriptionConfig.serviceUrl, serviceUrl);
        self.subscriptionConnection = new (webSocketServiceUrl, subscriptionConfig);
    }

    # Executes a GraphQL query operation and data binds the response.
    #
    # + document - The GraphQL document containing the query operation.
    #              For example `query countryByCode($code: ID!) { country(code: $code) { name } }`
    # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`
    # + operationName - The GraphQL operation name. If the document has more than one operation,
    #                   the operation name must be provided
    # + headers - The headers to be sent with the request
    # + targetType - The type the response is expected to be bound to
    # + return - The data-bound response, or a `graphql:ClientError` if the execution fails
    remote isolated function query(string document, map<anydata>? variables = (),
            string? operationName = (), map<string|string[]>? headers = (),
            typedesc<GenericResponseWithErrors|record {}> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.Client",
        name: "query"
    } external;

    private isolated function processQuery(typedesc<GenericResponseWithErrors|record {}> targetType,
            string document, map<anydata>? variables, string? operationName, map<string|string[]>? headers)
            returns GenericResponseWithErrors|record {}|ClientError {
        if self.subscriptionConnection.isClosed() {
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        check validateOperationKind(document, operationName, parser:OPERATION_QUERY);
        return self.executeGraphqlDocument(targetType, document, variables, operationName, headers);
    }

    # Executes a GraphQL mutation operation and data binds the response.
    #
    # + document - The GraphQL document containing the mutation operation.
    #              For example `mutation { addCountry(name: "<country_name>") { code } }`
    # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`
    # + operationName - The GraphQL operation name. If the document has more than one operation,
    #                   the operation name must be provided
    # + headers - The headers to be sent with the request
    # + targetType - The type the response is expected to be bound to
    # + return - The data-bound response, or a `graphql:ClientError` if the execution fails
    remote isolated function mutate(string document, map<anydata>? variables = (),
            string? operationName = (), map<string|string[]>? headers = (),
            typedesc<GenericResponseWithErrors|record {}> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.Client",
        name: "mutate"
    } external;

    private isolated function processMutate(typedesc<GenericResponseWithErrors|record {}> targetType,
            string document, map<anydata>? variables, string? operationName, map<string|string[]>? headers)
            returns GenericResponseWithErrors|record {}|ClientError {
        if self.subscriptionConnection.isClosed() {
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        check validateOperationKind(document, operationName, parser:OPERATION_MUTATION);
        return self.executeGraphqlDocument(targetType, document, variables, operationName, headers);
    }

    # Executes a GraphQL subscription document and returns a stream of data-bound responses.
    #
    # + document - The GraphQL document containing the subscription operation.
    #              For example `subscription { totalDonations }`
    # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`
    # + operationName - The GraphQL operation name. If the document has more than one operation,
    #                   the operation name must be provided
    # + id - The unique ID for the subscription operation. If not provided, a UUID is generated.
    #        The ID must be unique among the active subscriptions of this client
    # + targetType - The type each subscription event is expected to be bound to
    # + return - A stream of data-bound responses, or a `graphql:ClientError` if the subscription
    #            could not be established
    remote isolated function subscribe(string document, map<anydata>? variables = (),
            string? operationName = (), string? id = (),
            typedesc<GenericResponseWithErrors|record {}> targetType = <>)
            returns stream<targetType, ClientError?>|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.Client",
        name: "subscribe"
    } external;

    private isolated function processSubscribe(typedesc<GenericResponseWithErrors|record {}> targetType,
            string document, map<anydata>? variables, string? operationName, string? id)
            returns SubscriptionStreamGenerator|ClientError {
        if self.subscriptionConnection.isClosed() {
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        check validateOperationKind(document, operationName, parser:OPERATION_SUBSCRIPTION);
        string operationId = id ?: uuid:createRandomUuid();
        json subscribeMessage = {
            'type: WS_SUBSCRIBE,
            id: operationId,
            payload: getGraphqlPayload(document, variables, operationName)
        };
        MessageQueue messageQueue = new;
        check self.subscriptionConnection.subscribe(operationId, subscribeMessage.cloneReadOnly(), messageQueue);
        return new SubscriptionStreamGenerator(operationId, messageQueue, targetType, self.subscriptionConnection);
    }

    # Terminates all active subscriptions, closes the underlying WebSocket connection (if any),
    # and marks the client as closed.
    #
    # + return - A `graphql:ClientError` if the client could not be closed gracefully
    remote isolated function close() returns ClientError? {
        return self.subscriptionConnection.close();
    }

    # Executes a GraphQL document and data binds the GraphQL response to a record with data, extensions and errors
    # which is a subtype of GenericResponseWithErrors.
    #
    # + document - The GraphQL document. It can include queries & mutations.
    #              For example `query countryByCode($code:ID!) {country(code:$code) {name}}`.
    # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`.
    # + operationName - The GraphQL operation name. If a request has two or more operations, then each operation must have a name.
    #                   A request can only execute one operation, so you must also include the operation name to execute.
    # + headers - The GraphQL API headers to execute each query
    # + targetType - The payload (`GenericResponseWithErrors`), which is expected to be returned after data binding. For example
    #               `type CountryByCodeResponse record {| map<json?> extensions?; record {| record{|string name;|}? country; |} data; ErrorDetail[] errors?; |};`
    # + return - The GraphQL response or a `graphql:ClientError` if failed to execute the query
    # # Deprecated
    # This method is now deprecated. Use the per-operation `query()`, `mutate()`, and `subscribe()` APIs instead
    @deprecated
    remote isolated function execute(string document, map<anydata>? variables = (), string? operationName = (),
                                     map<string|string[]>? headers = (),
                                     typedesc<GenericResponseWithErrors|record{}|json> targetType = <>)
                                     returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.Client",
        name: "execute"
    } external;

    private isolated function processExecute(typedesc<GenericResponseWithErrors|record{}|json> targetType,
                                             string document, map<anydata>? variables, string? operationName,
                                             map<string|string[]>? headers)
                                             returns GenericResponseWithErrors|record{}|json|ClientError {
        if self.subscriptionConnection.isClosed() {
            return error ClientError(CLIENT_ALREADY_CLOSED_MESSAGE);
        }
        json|ClientError httpResponse = self.sendGraphqlRequest(document, variables, operationName, headers);
        if httpResponse is ClientError {
            return httpResponse;
        }
        do {
            return check httpResponse.cloneWithType(targetType);
        } on fail error e {
            return getPayloadBindingError(httpResponse, e);
        }
    }

    private isolated function executeGraphqlDocument(typedesc<GenericResponseWithErrors|record {}> targetType,
            string document, map<anydata>? variables, string? operationName, map<string|string[]>? headers)
            returns GenericResponseWithErrors|record {}|ClientError {
        json|ClientError httpResponse = self.sendGraphqlRequest(document, variables, operationName, headers);
        if httpResponse is ClientError {
            return httpResponse;
        }
        return performDataBindingWithErrors(targetType, httpResponse);
    }

    private isolated function sendGraphqlRequest(string document, map<anydata>? variables, string? operationName,
            map<string|string[]>? headers) returns json|ClientError {
        http:Request request = new;
        json graphqlPayload = getGraphqlPayload(document, variables, operationName);
        request.setPayload(graphqlPayload);
        json|http:ClientError httpResponse = self.httpClient->post("", request, headers = headers);
        if httpResponse is http:ClientError {
            return handleHttpClientErrorResponse(httpResponse);
        }
        return httpResponse;
    }
}
