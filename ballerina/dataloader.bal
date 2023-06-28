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

import graphql.dataloader;

import ballerina/jballerina.java;

isolated class DefaultDataLoader {
    *dataloader:DataLoader;
    private final table<Key> key(key) keyTable = table [];
    private final table<Result> key(key) resultTable = table [];
    private final (isolated function (readonly & anydata[] keys) returns anydata[]|error) batchFunction;

    public isolated function init(isolated function (readonly & anydata[] keys) returns anydata[]|error loadFunction) {
        self.batchFunction = loadFunction;
    }

    public isolated function load(anydata key) {
        readonly & anydata clonedKey = key.cloneReadOnly();
        lock {
            // Avoid duplicating keys and get values from cache if available
            if self.keyTable.hasKey(clonedKey) || self.resultTable.hasKey(clonedKey) {
                return;
            }
            self.keyTable.add({key: clonedKey});
        }
    }

    public isolated function get(anydata key, typedesc<anydata> 'type = <>) returns 'type|error = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.DataLoader"
    } external;

    private isolated function processGet(anydata key, typedesc<anydata> 'type) returns anydata|error {
        readonly & anydata clonedKey = key.cloneReadOnly();
        lock {
            if self.resultTable.hasKey(clonedKey) {
                anydata|error result = self.resultTable.get(clonedKey).value;
                if result is error {
                    return result.clone();
                }
                return (check result.ensureType('type)).clone();
            }
        }
        return error(string `No result found for the given key ${key.toString()}`);
    }

    public isolated function dispatch() {
        lock {
            if self.keyTable.length() == 0 {
                return;
            }
            readonly & anydata[] batchKeys = self.keyTable.toArray().'map((key) => key.key).cloneReadOnly();
            self.keyTable.removeAll();
            anydata[]|error batchResult = self.batchFunction(batchKeys);
            if batchResult is anydata[] && batchKeys.length() != batchResult.length() {
                batchResult = error("The batch function should return a number of results equal to the number of keys");
            }
            foreach int i in 0 ..< batchKeys.length() {
                if self.resultTable.hasKey(batchKeys[i]) {
                    continue;
                }
                self.resultTable.add({key: batchKeys[i], value: batchResult is error ? batchResult : batchResult[i]});
            }
        }
    }
}
