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
import ballerina/websocket;
import ballerina/io;

# Represents a Graphql listener endpoint.
public class Listener {
    private http:Listener httpListener;
    private websocket:Listener? wsListener;
    private Graphiql graphiql;
    private string httpEndpoint;
    private string websocketEndpoint;

    # Invoked during the initialization of a `graphql:Listener`. Either an `http:Listener` or a port number must be
    # provided to initialize the listener.
    #
    # + listenTo - An `http:Listener` or a port number to listen to the GraphQL service endpoint
    # + configuration - The additional configurations for the GraphQL listener
    # + return - A `graphql:Error` if the listener initialization is failed or else `()`
    public isolated function init(int|http:Listener listenTo, *ListenerConfiguration configuration)
    returns Error? {
        configuration.httpVersion = http:HTTP_1_1;
        if listenTo is int {
            http:Listener|error httpListener = new (listenTo, configuration);
            if httpListener is error {
                return error Error("Listener initialization failed", httpListener);
            }
            self.httpListener = httpListener;
        } else {
            self.httpListener = listenTo;
        }
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
        GraphqlServiceConfig? serviceConfig = getServiceConfig(s);
        self.graphiql = getGraphiqlConfig(serviceConfig);
        string schemaString = getSchemaString(serviceConfig);
        int? maxQueryDepth = getMaxQueryDepth(serviceConfig);
        readonly & (readonly & Interceptor)[] interceptors = getServiceInterceptors(serviceConfig);
        boolean introspection = getIntrospection(serviceConfig);
        boolean validation = getValidation(serviceConfig);
        ServerCacheConfig? operationCacheConfig = getCacheConfig(serviceConfig);
        ServerCacheConfig? fieldCacheConfig = getFieldCacheConfigFromServiceConfig(serviceConfig);
        Engine engine;
        if self.graphiql.enabled {
            check validateGraphiqlPath(self.graphiql.path);
            string gqlServiceBasePath = name is () ? "" : getBasePath(name);
            engine = check new (schemaString, maxQueryDepth, s, interceptors, introspection, validation,
                                operationCacheConfig, fieldCacheConfig);
            __Schema & readonly schema = engine.getSchema();
            __Type? subscriptionType = schema.subscriptionType;
            string graphqlUrl = string `${self.httpEndpoint}/${gqlServiceBasePath}`;
            string subscriptionUrl = string `${self.websocketEndpoint}/${gqlServiceBasePath}`;
            HttpService graphiqlService = subscriptionType is __Type
                                        ? getGraphiqlService(serviceConfig, graphqlUrl, subscriptionUrl)
                                        : getGraphiqlService(serviceConfig, graphqlUrl);
            attachGraphiqlServiceToGraphqlService(s, graphiqlService);
            error? result = self.httpListener.attach(graphiqlService, self.graphiql.path);
            if result is error {
                return error Error("Error occurred while attaching the GraphiQL endpoint", result);
            }
        } else {
            engine = check new (schemaString, maxQueryDepth, s, interceptors, introspection, validation,
                                operationCacheConfig, fieldCacheConfig);
        }

        HttpService httpService = getHttpService(engine, serviceConfig);
        attachHttpServiceToGraphqlService(s, httpService);

        error? result = self.httpListener.attach(httpService, name);
        if result is error {
            return error Error("Error occurred while attaching the service", result);
        }

        __Schema & readonly schema = engine.getSchema();
        __Type? subscriptionType = schema.subscriptionType;
        if subscriptionType is __Type && self.wsListener is () {
            string httpVersion = self.httpListener.getConfig().httpVersion;
            if httpVersion !is http:HTTP_1_1|http:HTTP_1_0 {
                string message = string `Websocket listener initialization failed due to the incompatibility of ` +
                                 string `provided HTTP(version ${httpVersion}) listener`;
                return error Error(message);
            }
            websocket:Listener|error wsListener = new(self.httpListener);
            if wsListener is error {
                return error Error("Websocket listener initialization failed", wsListener);
            }
            self.wsListener = wsListener;
        }

        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            UpgradeService wsService = getWebsocketService(engine, schema, serviceConfig);
            attachWebsocketServiceToGraphqlService(s, wsService);
            result = wsListener.attach(wsService, name);
            if result is error {
                return error Error("Error occurred while attaching the websocket service", result);
            }
        }
    }

    # Detaches the provided service from the Listener.
    #
    # + s - The service to be detached from the listener
    # + return - A `graphql:Error` if an error occurred during the service detaching process or else `()`
    public isolated function detach(Service s) returns Error? {
        HttpService? httpService = getHttpServiceFromGraphqlService(s);
        if httpService is HttpService {
            error? result = self.httpListener.detach(httpService);
            if result is error {
                return error Error("Error occurred while detaching the service", result);
            }
        }

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
        if graphiqlService is HttpService {
            error? result = self.httpListener.detach(graphiqlService);
            if result is error {
                return error Error("Error occurred while detaching the GraphiQL endpoint", result);
            }
        }
    }

    # Starts the attached service.
    #
    # + return - A `graphql:Error`, if an error occurred during the service starting process, otherwise nil
    public isolated function 'start() returns Error? {
        error? result = self.httpListener.'start();
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
        error? result = self.httpListener.gracefulStop();
        if result is error {
            return error Error("Error occurred while stopping the service", result);
        }
        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            result = wsListener.gracefulStop();
            if result is error {
                return error Error("Error occurred while stopping the websocket service", result);
            }
        }
    }

    # Stops the service listener immediately.
    #
    # + return - A `graphql:Error` if an error occurred during the service stopping process or else `()`
    public isolated function immediateStop() returns Error? {
        error? result = self.httpListener.immediateStop();
        if result is error {
            return error Error("Error occurred while stopping the service", result);
        }
        websocket:Listener? wsListener = self.wsListener;
        if wsListener is websocket:Listener {
            result = wsListener.immediateStop();
            if result is error {
                return error Error("Error occurred while stopping the websocket service", result);
            }
        }
    }
}
