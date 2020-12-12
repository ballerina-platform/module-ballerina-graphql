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
    private HttpService httpService;
    private Engine engine;

    # Invoked during the initialization of a `graphql:Listener`. Either an `http:Listner` or a port number must be
    # provided to initialize the listener.
    #
    # + httpListener - An `http:Listener` instance, on which the GraphQL service will be served. If this is provided
    #                  with a prot number, the port number will be ignored
    # + port - The port number to which the GraphQL endpoint should listen to
    public isolated function init(http:Listener? httpListener = (), int? port = ()) {
        if (httpListener is ()) {
            if (port is int) {
                self.httpListener = new(port);
            } else {
                error err = error("An http:Listener or a port number must be provided");
                panic err;
            }
        } else {
            self.httpListener = httpListener;
        }
        // TODO: Decouple engine and the listener
        self.engine = new(self);
        self.httpService = new(self.engine);
    }

    # Attaches the provided service to the Listener.
    #
    # + s - The `graphql:Service` object to attach
    # + name - The path of the service to be hosted
    # + return - An `error`, if an error occurred during the service attaching process
    public isolated function attach(Service s, string[]|string? name = ()) returns error? {
        checkpanic self.httpListener.attach(self.httpService, name);
        self.engine.registerService(s);
    }

    # Detaches the provided service from the Listener.
    #
    # + s - The service to be detached
    # + return - An `error`, if an error occurred during the service detaching process
    public isolated function detach(Service s) returns error? {
        checkpanic self.httpListener.detach(self.httpService);
    }

    # Starts the attached service.
    #
    # + return - An `error`, if an error occurred during the listener starting process
    public isolated function 'start() returns error? {
        checkpanic self.httpListener.'start();
    }

    # Gracefully stops the graphql listener. Already accepted requests will be served before the connection closure.
    #
    # + return - An `error`, if an error occurred during the listener stopping process
    public isolated function gracefulStop() returns error? {
        return self.httpListener.gracefulStop();
    }

    # Stops the service listener immediately. It is not implemented yet.
    #
    # + return - An `error`, if an error occurred during the listener stopping process
    public isolated function immediateStop() returns error? {
        return self.httpListener.immediateStop();
    }
}
