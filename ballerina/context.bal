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

import ballerina/http;
import ballerina/lang.value;

public isolated class Context {
    private final map<value:Cloneable|isolated object {}> attributes;

    public isolated function init() {
        self.attributes = {};
    }

    public isolated function add(string 'key, value:Cloneable|isolated object {} value) returns Error? {
        lock {
            if self.attributes.hasKey('key) {
                return error Error(string`Cannot add attribute to the context. Key "${'key}" already exists`);
            } else if value is value:Cloneable {
                self.attributes['key] = value.clone();
            } else {
                self.attributes['key] = value;
            }
        }
    }

    public isolated function get(string 'key) returns value:Cloneable|isolated object {} {
        lock {
            if self.attributes.hasKey('key) {
                value:Cloneable|isolated object {} value = self.attributes.get('key);
                if value is value:Cloneable {
                    return value.clone();
                } else {
                    return value;
                }
            }
        }
        return error Error(string`Attribute with the key "${'key}" not found in the context`);
    }

    public isolated function remove(string 'key) returns value:Cloneable|isolated object {} {
        lock {
            if self.attributes.hasKey('key) {
                value:Cloneable|isolated object {} value = self.attributes.remove('key);
                if value is value:Cloneable {
                    return value.clone();
                } else {
                    return value;
                }
            }
        }
        return error Error(string`Attribute with the key "${'key}" not found in the context`);
    }
}

isolated function initContext(http:Request request, http:RequestContext requestContext) returns Context|error {
    return new;
}
