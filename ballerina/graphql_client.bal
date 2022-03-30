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

import ballerina/jballerina.java;
import ballerina/http;
 
# The [Ballerina](https://ballerina.io/) generic client for GraphQL(https://graphql.org/) APIs.
public isolated client class Client {
    final http:Client httpClient;

    # Gets invoked to initialize the `connector`.
    #
    # + serviceUrl - URL of the target service
    # + clientConfig - The configurations to be used when initializing the `connector`
    # + return - An error at the failure of client initialization
    public isolated function init(string serviceUrl, http:ClientConfiguration clientConfig = {})  returns ClientError? {
        http:Client|http:ClientError httpClient = new (serviceUrl, clientConfig);
        if httpClient is http:ClientError {
             return error RequestError("GraphQL Client Error", httpClient);
        }
        self.httpClient = httpClient;
    }

    # Executes a GraphQL query and data binds the GraphQL response to a record with data and extensions 
    # which is a subtype of GenericResponse.
    #
    # + document - The GraphQL query or mutation. For example `query countryByCode($code:ID!) {country(code:$code) {name}}`.
    # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`.
    # + headers - The GraphQL API headers to execute each query 
    # + targetType - The payload, which is expected to be returned after data binding. For example 
    #                `type CountryByCodeResponse record {| map<json?> __extensions?; record {| record{|string name;|}? country; |} data;`
    # + return - The GraphQL response or a `graphql:ClientError` if failed to execute the query
    remote isolated function executeWithType(string document, map<anydata>? variables = (), 
                                             map<string|string[]>? headers = (), 
                                             typedesc<GenericResponse|record{}|json> targetType = <>) 
                                             returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.QueryExecutor",
        name: "executeWithType"
    } external;

    private isolated function processExecuteWithType(typedesc<GenericResponse|record{}|json> targetType, 
                                                     string document, map<anydata>? variables, 
                                                     map<string|string[]>? headers) 
                                                     returns GenericResponse|record{}|json|ClientError {
        http:Request request = new;
        json graphqlPayload = getGraphqlPayload(document, variables);
        request.setPayload(graphqlPayload);
        json|http:ClientError httpResponse = self.httpClient->post("", request, headers = headers);

        if httpResponse is http:ClientError {
            return handleHttpClientErrorResponse(httpResponse);
        } 
        GenericResponseWithErrors|record{}|json response = check performDataBinding(targetType, httpResponse);
        map<json> responseMap = <map<json>> httpResponse;
        if responseMap.hasKey("errors") {
            return handleGraphqlErrorResponse(responseMap);
        } 
        return response;
    }

    # Executes a GraphQL query and data binds the GraphQL response to a record with data, extensions and errors 
    # which is a subtype of GenericResponseWithErrors.
    #
    # + document - The GraphQL query or mutation. For example `query countryByCode($code:ID!) {country(code:$code) {name}}`.
    # + variables - The GraphQL variables. For example `{"code": "<variable_value>"}`.
    # + headers - The GraphQL API headers to execute each query 
    # + targetType - The payload (`GenericResponseWithErrors`), which is expected to be returned after data binding. For example 
    #               `type CountryByCodeResponse record {| map<json?> __extensions?; record {| record{|string name;|}? country; |} data; ErrorDetail[] errors?; |};`
    # + return - The GraphQL response or a `graphql:ClientError` if failed to execute the query
    remote isolated function execute(string document, map<anydata>? variables = (), map<string|string[]>? headers = (), 
                                     typedesc<GenericResponseWithErrors|record{}|json> targetType = <>) 
                                     returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.client.QueryExecutor",
        name: "execute"
    } external;

    private isolated function processExecute(typedesc<GenericResponseWithErrors|record{}|json> targetType, 
                                             string document, map<anydata>? variables, map<string|string[]>? headers) 
                                             returns GenericResponseWithErrors|record{}|json|ClientError {
        http:Request request = new;
        json graphqlPayload = getGraphqlPayload(document, variables);
        request.setPayload(graphqlPayload);
        json|http:ClientError httpResponse = self.httpClient->post("", request, headers = headers);

        if httpResponse is http:ClientError {
            return handleHttpClientErrorResponse(httpResponse);
        } 
        return check performDataBindingWithErrors(targetType, httpResponse);
    }
}
