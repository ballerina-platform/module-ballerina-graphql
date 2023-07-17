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

type Id int;

type User record {|
    int id;
    string name;
|};

type Input record {|
    int id;
|};

type Address record {|
    string street;
    string city;
|};

type Person User;

type PersonInput Input;

type PersonInput2 PersonInput;

type PersonAddress Address;

service on new graphql:Listener(4000) {
    resource function get id(Id id) returns Id {
        return id;
    }

    resource function get person1(PersonInput input) returns int {
      return input.id;
    }

    resource function get person2(PersonInput2 input) returns int {
        return input.id;
    }

    resource function get address() returns PersonAddress {
        return {
            street: "Baker Street",
            city: "London"
        };
    }
}
