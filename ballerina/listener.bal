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

# Represents a Graphql listener endpoint.
public class Listener {
    private http:Listener httpListener;

    # Invoked during the initialization of a `graphql:Listener`. Either an `http:Listner` or a port number must be
    # provided to initialize the listener.
    #
    # + listenTo - An `http:Listener` or a port number to listen to the GraphQL service endpoint
    # + configuration - The additional configurations for the GraphQL listener
    # + return - A `graphql:Error` if the listener initialization is failed or else `()`
    public isolated function init(int|http:Listener listenTo, *ListenerConfiguration configuration)
    returns Error? {
        if (listenTo is int) {
            http:Listener|error httpListener = new(listenTo, configuration);
            if (httpListener is error) {
                return error Error("Listener initialization failed", httpListener);
            } else {
                self.httpListener = httpListener;
            }
        } else {
            self.httpListener = listenTo;
        }
    }

    # Attaches the provided service to the Listener.
    #
    # + s - The `graphql:Service` object to attach to the listener
    # + name - The path of the service to be hosted
    # + return - A `graphql:Error` if an error occurred during the service-attaching process or the schema
    #            generation process or else `()`
    public isolated function attach(Service s, string[]|string? name = ()) returns Error? {
        __Schema schema = check createSchema(s);
        addDefaultDirectives(schema);
        GraphqlServiceConfig? serviceConfig = getServiceConfig(s);
        int? maxQueryDepth = getMaxQueryDepth(serviceConfig);
        Engine engine = check new(schema, maxQueryDepth);
        attachServiceToEngine(s, engine);

        HttpService httpService = new(engine, serviceConfig);
        attachHttpServiceToGraphqlService(s, httpService);

        error? result = self.httpListener.attach(httpService, name);
        if result is error {
            return error Error("Error occurred while attaching the service", result);
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
            if (result is error) {
                return error Error("Error occurred while detaching the service", result);
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
    }

    # Gracefully stops the graphql listener. Already accepted requests will be served before the connection closure.
    #
    # + return - A `graphql:Error`, if an error occurred during the service stopping process, otherwise nil
    public isolated function gracefulStop() returns Error? {
        error? result = self.httpListener.gracefulStop();
        if result is error {
            return error Error("Error occurred while stopping the service", result);
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
    }
}
