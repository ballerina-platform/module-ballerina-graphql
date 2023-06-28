// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/jballerina.java;

isolated class PlaceHolder {
    private Field? 'field = ();
    private anydata value = ();

    isolated function init(Field 'field) {
        self.setField('field);
    }

    isolated function setValue(anydata value) {
        lock {
            self.value = value.clone();
        }
    }

    isolated function getValue() returns anydata {
        lock {
            return self.value.clone();
        }
    }

    isolated function setField(Field 'field) = @java:Method {
        name: "setFieldValue",
        'class: "io.ballerina.stdlib.graphql.runtime.engine.PlaceHolder"
    } external;

    isolated function getField() returns Field = @java:Method {
        name: "getFieldValue",
        'class: "io.ballerina.stdlib.graphql.runtime.engine.PlaceHolder"
    } external;
};
