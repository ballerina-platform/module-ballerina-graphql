// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/graphql;
import ballerina/http;

listener http:Listener httpListener1 = new(91021);
listener http:Listener httpListener2 = check new(91021);
listener http:Listener httpListener3 = check new http:Listener(91021);
listener http:Listener httpListener4 = check new http:Listener(91021);

graphql:ListenerConfiguration configs = {
    timeout: 1.0
};

listener graphql:Listener listener0 = new (9090, configs);
listener graphql:Listener listener1 = new(httpListener1, configs);
listener graphql:Listener listener2 = check new(httpListener2, configs);
listener graphql:Listener listener3 = new graphql:Listener(httpListener3, configs);
listener graphql:Listener listener4 = check new graphql:Listener(httpListener4, configs);
listener graphql:Listener listener5 = new (listenTo = httpListener1, httpVersion = http:HTTP_2_0);
listener graphql:Listener listener6 = check new (listenTo = httpListener2, httpVersion = http:HTTP_2_0);
listener graphql:Listener listener7 = new (httpVersion = http:HTTP_2_0, listenTo = httpListener3);
listener graphql:Listener listener8 = check new (httpVersion = http:HTTP_2_0, listenTo = httpListener4);
listener graphql:Listener listener9 = new (httpVersion = http:HTTP_2_0, host = "192.168.1.1", listenTo = httpListener1);
listener graphql:Listener listener10 = check new (httpVersion = http:HTTP_2_0, host = "192.168.1.1", listenTo = 9090);

service graphql:Service on new graphql:Listener(httpListener1, configs) {
    resource function get name() returns string {
        return "John";
    }
}

service graphql:Service on listener1 {
    resource function get name() returns string {
        return "John";
    }
}

service graphql:Service on listener2 {
    resource function get name() returns string {
        return "John";
    }
}

service graphql:Service on listener3 {
    resource function get name() returns string {
        return "John";
    }
}

service graphql:Service on listener4 {
    resource function get name() returns string {
        return "John";
    }
}
