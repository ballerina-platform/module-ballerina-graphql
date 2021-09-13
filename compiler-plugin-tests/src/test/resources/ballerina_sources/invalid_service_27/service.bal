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

distinct service class Iterable {
    int counter;

    function init(int counter) {
        self.counter = counter;
    }

    resource function get counter() returns int {
        return self.counter;
    }
}

distinct service class Collection  {
    string name;

    function init(string name) {
        self.name = name;
    }

    resource function get name() returns string {
        return self.name;
    }
}

distinct service class Queue {
    *Collection;
    *Iterable;

    function init(string name, int counter) {
        self.name = name;
        self.counter = counter;
    }

    resource function get name() returns string {
        return self.name;
    }

    resource function get counter() returns int {
        return self.counter;
    }
}

service class LinkedList {
    *Queue;

    int counter = 1;
    string name = "LinkedList";

    resource function get counter() returns int {
        return self.counter;
    }
}

service class ArrayDeque {
    *Queue;

    string name = "ArrayDeque";
    int counter = 1;

    resource function get name() returns string {
        return self.name;
    }
}

service /graphql on new graphql:Listener(9000) {

    // returning type is an interface. Has sub types ArrayDeque and LinkedList
    resource function get list(int length) returns Queue {
        if (length > 1) {
            return new LinkedList();
        } else {
            return new ArrayDeque();
        }
    }
}
