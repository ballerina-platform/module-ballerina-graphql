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

public isolated service class Lift {
    isolated resource function get name() returns string {
        return "L1";
    }
}

isolated service class Trail {
    isolated resource function get id() returns string {
        return "T1";
    }

    remote function lifts() returns Lift[] {
        return [new];
    }
}

service /graphql on new graphql:Listener(4000) {
    isolated resource function get lift() returns Trail {
        return new;
    }
}
