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

// no resource functions in any parent interface class
// resource function in an un-implemented interface - Deque
distinct service class Iterable {
    string name;

    function init(string name) {
        self.name = name;
    }
}

distinct service class Collection  {
    *Iterable;

    function init(string name) {
        self.name = name;
    }
}

distinct service class Queue {
    *Collection;

    function init(string name) {
        self.name = name;
    }
}

service class LinkedList {
    *Queue;

    string name = "LinkedList";
}

service class ArrayDeque {
    *Queue;

    string name = "ArrayDeque";
}

service /graphql on new graphql:Listener(9000) {

    isolated resource function get list(int length) returns Queue {
        if (length > 1) {
            return new LinkedList();
        } else {
            return new ArrayDeque();
        }
    }
}
