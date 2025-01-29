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

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/websocket;

# Represents a Graphql listener endpoint.
public class Listener {
    private http:Listener? httpListener = ();
    private int|http:Listener listenTo;
    private final ListenerConfiguration configuration;
    private websocket:Listener? wsListener = ();
    private Graphiql graphiql = {};
    private string httpEndpoint;
    private string websocketEndpoint;
    // The service attach method does not contain the annotation values properly assigned. Therefore, the services are
    // kept in an array to process in the `start` method.
    // https://github.com/ballerina-platform/ballerina-lang/issues/43162
    private final Service[] services = [];

    # Invoked during the initialization of a `graphql:Listener`. Either an `http:Listener` or a port number must be
    # provided to initialize the listener.
    #
    # + listenTo - An `http:Listener` or a port number to listen to the GraphQL service endpoint
    # + configuration - The additional configurations for the GraphQL listener
    # + return - A `graphql:Error` if the listener initialization is failed or else `()`
    public isolated function init(int|http:Listener listenTo, *ListenerConfiguration configuration)
    returns Error? {
        self.listenTo = listenTo;
        self.configuration = configuration.clone();
        self.wsListener = ();
        self.graphiql = {};
        [string, string][httpEndpoint, websocketEndpoint] = getEndpoints(listenTo, configuration);
        self.httpEndpoint = httpEndpoint;
        self.websocketEndpoint = websocketEndpoint;
    }

    # Attaches the provided service to the Listener.
    #
    # + s - The `graphql:Service` object to attach to the listener
    # + name - The path of the service to be hosted
    # + return - A `graphql:Error` if an error occurred during the service-attaching process or the schema
    #            generation process or else `()`
    public isolated function attach(Service s, string[]|string? name = ()) returns Error? {
        GraphqlServiceConfig serviceConfig = check getServiceConfig(s);
        self.graphiql = serviceConfig.graphiql;
        string schemaString = serviceConfig.schemaString;
        int? maxQueryDepth = serviceConfig.maxQueryDepth;
        readonly & Interceptor[] interceptors = getServiceInterceptors(serviceConfig);
        boolean introspection = serviceConfig.introspection;
        boolean validation = serviceConfig.validation;
        ServerCacheConfig? operationCacheConfig = serviceConfig.cacheConfig;
        ServerCacheConfig? fieldCacheConfig = serviceConfig.fieldCacheConfig;
        QueryComplexityConfig? queryComplexityConfig = serviceConfig.queryComplexityConfig;
        Engine engine  = check new (schemaString, maxQueryDepth, s, interceptors, introspection, validation,
                                    operationCacheConfig, fieldCacheConfig, queryComplexityConfig);
        HttpService httpService = getHttpService(engine, serviceConfig);
        attachHttpServiceToGraphqlService(s, httpService);
        __Schema & readonly schema = engine.getSchema();
        boolean isSubscriptionService = schema.subscriptionType is __Type;
        check self.initHttpListener(isSubscriptionService);
        check self.initWebsocketListener(isSubscriptionService);

        http:Listener|Error httpListener = self.getHttpListener();
        if httpListener is Error {
            return httpListener;
        }
        error? result = httpListener.attach(httpService, name);
        if result is error {
            return error Error("Error occurred while attaching the HTTP service", result);
        }
        if isSubscriptionService {
            check self.attachWebSocketService(s, engine, schema, serviceConfig, name);
        }
        if self.graphiql.enabled {
            check validateGraphiqlPath(self.graphiql.path);
            check self.initGraphiqlService(s, engine, name, serviceConfig);
        }
        self.services.push(s);
    }

    # Detaches the provided service from the Listener.
    #
    # + s - The service to be detached from the listener
    # + return - A `graphql:Error` if an error occurred during the service detaching process or else `()`
    public isolated function detach(Service s) returns Error? {
        HttpService? httpService = getHttpServiceFromGraphqlService(s);
        check self.detachHttpService(httpService);

        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            UpgradeService? wsService = getWebsocketServiceFromGraphqlService(s);
            if wsService is UpgradeService {
                error? result = wsListener.detach(wsService);
                if result is error {
                    return error Error("Error occurred while detaching the websocket service", result);
                }
            }
        }

        HttpService? graphiqlService = getGraphiqlServiceFromGraphqlService(s);
        check self.detachHttpService(graphiqlService);
    }

    # Starts the attached service.
    #
    # + return - A `graphql:Error`, if an error occurred during the service starting process, otherwise nil
    public isolated function 'start() returns Error? {
        analyzeServices(self.services);
        http:Listener|Error httpListener = self.getHttpListener();
        if httpListener is Error {
            return httpListener;
        }
        error? result = httpListener.'start();
        if result is error {
            return error Error("Error occurred while starting the service", result);
        }
        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            result = wsListener.'start();
            if result is error {
                return error Error("Error occurred while starting the websocket service", result);
            }
        }
        if self.graphiql.enabled && self.graphiql.printUrl {
            string sanitizedPath = re `^/*`.replace(self.graphiql.path, "");
            string graphiqlUrl = string `${self.httpEndpoint}/${sanitizedPath}`;
            io:println(string `GraphiQL client ready at ${graphiqlUrl}`);
        }
    }

    # Gracefully stops the graphql listener. Already accepted requests will be served before the connection closure.
    #
    # + return - A `graphql:Error`, if an error occurred during the service stopping process, otherwise nil
    public isolated function gracefulStop() returns Error? {
        http:Listener|Error httpListener = self.getHttpListener();
        if httpListener is http:Listener {
            error? result = httpListener.gracefulStop();
            if result is error {
                return error Error("Error occurred while stopping the HTTP listener", result);
            }
        }
        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            error? result = wsListener.gracefulStop();
            if result is error {
                return error Error("Error occurred while stopping the WebSocket listener", result);
            }
        }
    }

    # Stops the service listener immediately.
    #
    # + return - A `graphql:Error` if an error occurred during the service stopping process or else `()`
    public isolated function immediateStop() returns Error? {
        http:Listener|Error httpListener = self.getHttpListener();
        if httpListener is http:Listener {
            error? result = httpListener.immediateStop();
            if result is error {
                return error Error("Error occurred while stopping the service", result);
            }
        }
        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            error? result = wsListener.immediateStop();
            if result is error {
                return error Error("Error occurred while stopping the websocket service", result);
            }
        }
    }

    private isolated function initHttpListener(boolean isSubscriptionService) returns Error? {
        if self.httpListener is http:Listener {
            return;
        }
        int|http:Listener listenTo = self.listenTo;
        if listenTo is http:Listener {
            if isSubscriptionService {
                check validateHttpVersion(listenTo);
            }
            self.httpListener = listenTo;
            return;
        }
        ListenerConfiguration configuration = {
            ...self.configuration
        };
        if isSubscriptionService {
            log:printWarn("GraphQL is using HTTP 1.1 since the schema contains a subscription type");
            configuration.httpVersion = http:HTTP_1_1;
        }
        http:Listener|error httpListener = new (listenTo, configuration);
        if httpListener is error {
            return error Error("HTTP listener initialization failed", httpListener);
        }
        self.httpListener = httpListener;
    }

    private isolated function initWebsocketListener(boolean isSubscriptionService) returns Error? {
        if self.wsListener is websocket:Listener ||!isSubscriptionService {
            return;
        }
        http:Listener|Error httpListener = self.getHttpListener();
        if httpListener is Error {
            return httpListener;
        }
        check validateHttpVersion(httpListener);

        websocket:Listener|error wsListener = new(httpListener);
        if wsListener is error {
            return error Error("Websocket listener initialization failed", wsListener);
        }
        self.wsListener = wsListener;
    }

    private isolated function attachWebSocketService(Service s, Engine engine, __Schema & readonly schema,
        GraphqlServiceConfig serviceConfig, string[]|string? name) returns Error? {
        websocket:Listener? wsListener = self.wsListener;
        if wsListener is () {
            return error Error("Websocket listener is not initialized");
        }
        UpgradeService wsService = getWebsocketService(engine, schema, serviceConfig);
        attachWebsocketServiceToGraphqlService(s, wsService);
        error? result = wsListener.attach(wsService, name);
        if result is error {
            return error Error("Error occurred while attaching the WebSocket service", result);
        }
    }

    private isolated function detachHttpService(HttpService? httpService) returns Error? {
        if httpService is () {
            return;
        }
        http:Listener|Error httpListener = self.getHttpListener();
        if httpListener is Error {
            return httpListener;
        }
        error? result = httpListener.detach(httpService);
        if result is error {
            return error Error("Error occurred while detaching the service", result);
        }
    }

    private isolated function initGraphiqlService(Service s, Engine engine, string[]|string? name,
            GraphqlServiceConfig serviceConfig) returns Error? {
        string gqlServiceBasePath = name is () ? "" : getBasePath(name);
        __Schema & readonly schema = engine.getSchema();
        __Type? subscriptionType = schema.subscriptionType;
        string graphqlUrl = string `${self.httpEndpoint}/${gqlServiceBasePath}`;
        string subscriptionUrl = string `${self.websocketEndpoint}/${gqlServiceBasePath}`;
        HttpService graphiqlService = subscriptionType is __Type
                                    ? getGraphiqlService(serviceConfig, graphqlUrl, subscriptionUrl)
                                    : getGraphiqlService(serviceConfig, graphqlUrl);
        attachGraphiqlServiceToGraphqlService(s, graphiqlService);
        error? result = (check self.getHttpListener()).attach(graphiqlService, self.graphiql.path);
        if result is error {
            return error Error("Error occurred while attaching the GraphiQL endpoint", result);
        }
    }

    private isolated function getHttpListener() returns http:Listener|Error {
        http:Listener? httpListener = self.httpListener;
        if httpListener is http:Listener {
            return httpListener;
        }
        return error Error("HTTP listener is not initialized");
    }
}
