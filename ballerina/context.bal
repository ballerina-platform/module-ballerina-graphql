// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import graphql.dataloader;

import ballerina/http;
import ballerina/jballerina.java;
import ballerina/lang.value;

# The GraphQL context object used to pass the meta information between resolvers.
public isolated class Context {
    private final map<value:Cloneable|isolated object {}> attributes;
    private final ErrorDetail[] errors;
    private Engine? engine;
    private int nextInterceptor;
    private boolean hasFileInfo = false; // This field value changed by setFileInfo method
    private map<dataloader:DataLoader> idDataLoaderMap = {}; // Provides mapping between user defined id and DataLoader
    private map<PlaceHolder> uuidPlaceHolderMap = {};
    private map<()> nonDispatchedDataLoaderIds = {};
    private PlaceHolder[] unResolvedPlaceHolders = [];
    private boolean containPlaceHolders = false;
    private int unResolvedPlaceHolderCount = 0; // Tracks the number of PlaceHolders needs to be resolved
    private int unResolvedPlaceHolderNodeCount = 0; // Tracks the number of nodes to be replaced in the value tree

    public isolated function init(map<value:Cloneable|isolated object {}> attributes = {}, Engine? engine = (), 
                                  int nextInterceptor = 0) {
        self.attributes = {};
        self.engine = engine;
        self.errors = [];
        self.nextInterceptor = nextInterceptor;
        
        foreach var item in attributes.entries() {
            string key = item[0];
            value:Cloneable|isolated object {} value = item[1];
            self.attributes[key] = value;
        }
    }

    # Sets a given value for a given key in the GraphQL context.
    #
    # + key - The key for the value to be set
    # + value - Value to be set
    public isolated function set(string 'key, value:Cloneable|isolated object {} value) {
        lock {
            if value is value:Cloneable {
                self.attributes['key] = value.clone();
            } else {
                self.attributes['key] = value;
            }
        }
    }

    # Retrieves a value using the given key from the GraphQL context.
    #
    # + key - The key corresponding to the required value
    # + return - The value if the key is present in the context, a `graphql:Error` otherwise
    public isolated function get(string 'key) returns value:Cloneable|isolated object {}|Error {
        lock {
            if self.attributes.hasKey('key) {
                value:Cloneable|isolated object {} value = self.attributes.get('key);
                if value is value:Cloneable {
                    return value.clone();
                } else {
                    return value;
                }
            }
            return error Error(string`Attribute with the key "${'key}" not found in the context`);
        }
    }

    # Removes a value using the given key from the GraphQL context.
    #
    # + key - The key corresponding to the value to be removed
    # + return - The value if the key is present in the context, a `graphql:Error` otherwise
    public isolated function remove(string 'key) returns value:Cloneable|isolated object {}|Error {
        lock {
            if self.attributes.hasKey('key) {
                value:Cloneable|isolated object {} value = self.attributes.remove('key);
                if value is value:Cloneable {
                    return value.clone();
                } else {
                    return value;
                }
            }
            return error Error(string`Attribute with the key "${'key}" not found in the context`);
        }
    }

    isolated function addError(ErrorDetail err) {
        lock {
            self.errors.push(err.clone());
        }
    }

    isolated function addErrors(ErrorDetail[] errs) {
        readonly & ErrorDetail[] errors = errs.cloneReadOnly();
        lock {
            self.errors.push(...errors);
        }
    }

    isolated function getErrors() returns ErrorDetail[] {
        lock {
            return self.errors.clone();
        }
    }

    isolated function setFileInfo(map<Upload|Upload[]> fileInfo) = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    isolated function getFileInfo() returns map<Upload|Upload[]> = @java:Method {
        'class: "io.ballerina.stdlib.graphql.runtime.engine.EngineUtils"
    } external;

    public isolated function resolve(Field 'field) returns anydata {
        Engine? engine = self.getEngine();
        if engine is Engine {
            return engine.resolve(self, 'field, false);
        }
        return;
    }

    isolated function setEngine(Engine engine) {
        lock {
            self.engine = engine;
        }
    }

    isolated function getEngine() returns Engine? {
        lock {
            return self.engine;
        }
    }

    isolated function getNextInterceptor(Field 'field) returns (readonly & Interceptor)? {
        Engine? engine = self.getEngine();
        if engine is Engine {
            (readonly & Interceptor)[] interceptors = engine.getInterceptors();
            if interceptors.length() > self.getInterceptorCount() {
                (readonly & Interceptor) next = interceptors[self.getInterceptorCount()];
                if !isGlobalInterceptor(next) && 'field.getPath().length() > 1 {
                    self.increaseInterceptorCount();
                    return self.getNextInterceptor('field);
                }
                self.increaseInterceptorCount();
                return next;
            }
            int nextFieldInterceptor = self.getInterceptorCount() - engine.getInterceptors().length();
            if 'field.getFieldInterceptors().length() > nextFieldInterceptor {
                readonly & Interceptor next = 'field.getFieldInterceptors()[nextFieldInterceptor];
                self.increaseInterceptorCount();
                return next;
            }
        }
        self.resetInterceptorCount();
        return;
    }

    isolated function resetInterceptorCount() {
        lock {
            self.nextInterceptor = 0;
        }
    }

    isolated function getInterceptorCount() returns int {
        lock {
            return self.nextInterceptor;
        }
    }

    isolated function increaseInterceptorCount() {
        lock {
            self.nextInterceptor += 1;
        }
    }

    isolated function resetErrors() {
        lock {
            self.errors.removeAll();
        }
    }

    isolated function addDataLoader(string id,
            (isolated function (readonly & anydata[] keys) returns anydata[]|error) batchFunction) {
        lock {
            if self.idDataLoaderMap.hasKey(id) {
                return;
            }
            DefaultDataLoader dataloader = new (batchFunction);
            self.idDataLoaderMap[id] = dataloader;
            return;
        }
    }

    isolated function addUnResolvedPlaceHolder(string uuid, PlaceHolder placeHolder) {
        lock {
            self.containPlaceHolders = true;
            self.uuidPlaceHolderMap[uuid] = placeHolder;
            self.unResolvedPlaceHolders.push(placeHolder);
            self.unResolvedPlaceHolderCount += 1;
            self.unResolvedPlaceHolderNodeCount += 1;
        }
    }

     isolated function addNonDispatchedDataLoaderIds(string[] dataLoaderIds) {
        final readonly & string[] loaderIds = dataLoaderIds.cloneReadOnly();
        lock {
            foreach string id in loaderIds {
                self.nonDispatchedDataLoaderIds[id] = ();
            }
        }
    }

    isolated function resolvePlaceHolders() {
        lock {
            string[] nonDispatchedDataLoaderIds = self.nonDispatchedDataLoaderIds.keys();
            self.nonDispatchedDataLoaderIds = {};
            PlaceHolder[] unResolvedPlaceHolders = self.unResolvedPlaceHolders;
            self.unResolvedPlaceHolders = [];
            foreach string dataLoaderId in nonDispatchedDataLoaderIds {
                self.idDataLoaderMap.get(dataLoaderId).dispatch();
            }
            foreach PlaceHolder placeHolder in unResolvedPlaceHolders {
                Engine? engine = self.getEngine();
                if engine is () {
                    continue;
                }
                anydata resolvedValue = engine.resolve(self, 'placeHolder.getField(), false);
                placeHolder.setValue(resolvedValue);
                self.unResolvedPlaceHolderCount -= 1;
            }
        }
    }

    isolated function getPlaceHolderValue(string uuid) returns anydata {
        lock {
            return self.uuidPlaceHolderMap.remove(uuid).getValue();
        }
    }

    isolated function getUnresolvedPlaceHolderCount() returns int {
        lock {
            return self.unResolvedPlaceHolderCount;
        }
    }

    isolated function getUnresolvedPlaceHolderNodeCount() returns int {
        lock {
            return self.unResolvedPlaceHolderNodeCount;
        }
    }

    isolated function decrementUnresolvedPlaceHolderNodeCount() {
        lock {
            self.unResolvedPlaceHolderNodeCount-=1;
        }
    }

    isolated function hasPlaceHolders() returns boolean {
        lock {
            return self.containPlaceHolders;
        }
    }

    isolated function clearDataLoadersAndPlaceHolders() {
        // This function is called at the end of each subscription loop execution.
        // This avoid using the same data loader in the next loop itteration and avoid filling up the idPlaceHolderMap.
        lock {
            self.idDataLoaderMap.removeAll();
            self.unResolvedPlaceHolders.removeAll();
            self.uuidPlaceHolderMap.removeAll();
            self.nonDispatchedDataLoaderIds.removeAll();
            self.containPlaceHolders = false;
        }
    }
}

isolated function initDefaultContext(http:RequestContext requestContext, http:Request request) returns Context|error {
    return new;
}
