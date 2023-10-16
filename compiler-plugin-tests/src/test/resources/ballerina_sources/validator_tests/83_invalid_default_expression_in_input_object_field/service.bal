// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

final int v = 3;

type InputObject3 record {|
    int val = v;
|};

type InputObject2 record {|
    *InputObject3;
|};

type InputObject record {|
    *InputObject2;
|};

service /defaultParam on new graphql:Listener(8080) {
    resource function get data() returns OutputObject? {
        return;
    }
}

distinct service class OutputObject {
    resource function get data(InputObject obj) returns string? {
        return;
    }
}
