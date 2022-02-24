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

http:Listener httpListener1 = check new(4000);
http:Listener httpListener2 = check new http:Listener(4000);
http:Listener httpListener3 = check new http:Listener(4000);

listener graphql:Listener listener1 = new(httpListener1, timeout = 1000, server = "0.0.0.0");
listener graphql:Listener listener2 = check new(httpListener2, timeout = 1000, server = "0.0.0.0");
listener graphql:Listener listener3 = new graphql:Listener(httpListener3, timeout = 1000, server = "0.0.0.0");
listener graphql:Listener listener4 = check new graphql:Listener(httpListener1, timeout = 1000, server = "0.0.0.0");

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
