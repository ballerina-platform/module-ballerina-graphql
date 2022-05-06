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

import ballerina/graphql;

service /graphql on new graphql:Listener(4000) {

    isolated resource function get lift() returns Lift {
        return new("lift1");
    }

    isolated resource function get trail() returns Trail {
        return new("trail1");
    }
}

# Represents a Lift in the Snowtooth park
public isolated service class Lift {
    final string name;

    public isolated function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get trails() returns Trail[] {
        return [new Trail("trail1")];
    }
}

# Represents a Trail in the Snowtooth park.
public isolated service class Trail {
    final string name;

    public isolated function init(string name) {
        self.name = name;
    }

    isolated resource function get name() returns string {
        return self.name;
    }

    isolated resource function get lifts() returns Lift[] {
        return [new Lift("lift1")];
    }
}
