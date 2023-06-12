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

service graphql:Service on new graphql:Listener(4000) {
    resource function get name(@graphql:ID boolean id) returns Student1 {
        return new Student1(false);
    }
}

public distinct service class Student1 {
    final boolean id;

    function init(boolean id) {
        self.id = id;
    }

    resource function get id() returns @graphql:ID boolean {
        return self.id;
    }
}

type ID record {
    int id;
};

service graphql:Service on new graphql:Listener(4000) {
    resource function get name(@graphql:ID ID id) returns Student4 {
        return new Student4(["hello", "world"]);
    }
}

public distinct service class Student4 {
    final string[] id;

    function init(string[] id) {
        self.id = id;
    }

    resource function get id() returns @graphql:ID string[] {
        return self.id;
    }
}
