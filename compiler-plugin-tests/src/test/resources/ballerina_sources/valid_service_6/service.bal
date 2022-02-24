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

http:Listener httpListener = check new(91021);
listener graphql:Listener listener1 = new(httpListener);
listener graphql:Listener listener2 = new(9000);
listener graphql:Listener listener3 = check new(9000);
listener graphql:Listener listener4 = new graphql:Listener(9000);
listener graphql:Listener listener5 = check new graphql:Listener(9000);

graphql:ListenerConfiguration configs = {
    timeout: 1.0
};

listener graphql:Listener listener6 = new(9000, configs);
listener graphql:Listener listener7 = check new(9000, configs);
listener graphql:Listener listener8 = new graphql:Listener(9000, configs);
listener graphql:Listener listener9 = check new graphql:Listener(9000, configs);

service graphql:Service on new graphql:Listener(4000) {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on new graphql:Listener(httpListener) {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on new graphql:Listener(4000, configs) {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on new graphql:Listener(4000, timeout = 5, server = "0.0.0.0") {
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

service graphql:Service on listener5 {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on listener6 {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on listener7 {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on listener8 {
    resource function get name() returns string {
            return "John";
    }
}

service graphql:Service on listener9 {
    resource function get name() returns string {
            return "John";
    }
}
