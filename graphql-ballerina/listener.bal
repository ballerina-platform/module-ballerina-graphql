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

public class Listener {
    private http:Listener httpListener;
    private Engine engine;
    private HttpService httpService;

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
        self.engine = new(self);
        self.httpService = new(self.engine);
    }

    public isolated function attach(Service s, string[]|string? name = ()) returns error? {
        checkpanic self.httpListener.attach(self.httpService, name);
        check attach(self, s, name);
    }

    public isolated function detach(Service s) returns error? {
        checkpanic self.httpListener.detach(self.httpService);
        return detach(self, s);
    }

    public isolated function 'start() returns error? {
        checkpanic self.httpListener.'start();
    }

    public isolated function gracefulStop() returns error? {
        return self.httpListener.gracefulStop();
    }

    public isolated function immediateStop() returns error? {
        return self.httpListener.immediateStop();
    }
}
