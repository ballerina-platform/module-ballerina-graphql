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
import ballerina/lang.'object;
import ballerina/log;

string basePath = "graphql";
Engine? globalEngine = ();

public class Listener {
    *'object:Listener;
    private int port;
    private http:Listener httpListener;
    private Engine engine;

    public function init(int port, ListenerConfiguration? configs = ()) {
        http:ListenerConfiguration? httpListenerConfigs = ();
        if (configs is ListenerConfiguration) {
            httpListenerConfigs = getHttpListenerConfigs(configs);
        }
        self.httpListener = new(port, httpListenerConfigs);
        self.port = port;
        self.engine = new(self);
        globalEngine = self.engine;
    }

    // Cannot mark as isolated due to global variable usage. Discussion:
    // (https://ballerina-platform.slack.com/archives/C47EAELR1/p1602066015052000)
    public function __attach(service s, string? name = ()) returns error? {
        self.engine.addService(s);
        GraphQlServiceConfiguration? serviceConfig = getServiceAnnotations(s);
        if (serviceConfig is GraphQlServiceConfiguration) {
            basePath = serviceConfig.basePath;
        }
        service httpService =
        @http:ServiceConfig {
            basePath: basePath
        }
        service {
            @http:ResourceConfig {
                path: "/",
                methods: ["GET"]
            }
            resource isolated function get(http:Caller caller, http:Request request) {
                json payload = getErrorJson("HTTP GET requests are not yet supported");
                http:Response response = new;
                response.setPayload(payload);
                var result = caller->respond(response);
            }

            @http:ResourceConfig {
                path: "/",
                methods: ["POST"]
            }
            resource function post(http:Caller caller, http:Request request) {
                http:Response response = handlePostRequests(globalEngine, request);
                var sendResult = caller->respond(response);
            }
        };
        checkpanic self.httpListener.__attach(httpService);
        check attach(self, s, name);
    }

    public isolated function __detach(service s) returns error? {
        return detach(self, s);
    }

    public isolated function __start() returns error? {
        checkpanic self.httpListener.__start();
        log:printInfo("started GraphQL listener " + self.port.toString());
    }

    public isolated function __gracefulStop() returns error? {
        return self.httpListener.__gracefulStop();
    }

    public isolated function __immediateStop() returns error? {
        return self.httpListener.__immediateStop();
    }
}
