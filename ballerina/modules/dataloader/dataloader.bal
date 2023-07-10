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

# Represents the type of the batch function to be used in the DataLoader.
public type BatchLoadFunction isolated function (readonly & anydata[] keys) returns anydata[]|error;

# Represents a DataLoader object that can be used to load data from a data source.
public type DataLoader isolated object {

    # Collects a key to perform a batch operation at a later time.
    #
    # + key - The key to load later
    public isolated function load(anydata key);

    # Retrieves the result for a particular key.
    #
    # + key - The key to retrieve the result
    # + 'type - The type of the result
    # + return - The result for the key on success, error on failure
    public isolated function get(anydata key, typedesc<anydata> 'type = <>) returns 'type|error;

    # Dispatches a user-defined batch load operation for all keys that have been collected.
    public isolated function dispatch();
};
