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

import ballerina/log;
import ballerina/io;

isolated function logAndPanicError(string message, error e) {
    log:printError(message, e);
    panic e;
}

isolated function getOperationTypeName(OperationType operationType) returns string {
    match operationType {
        MUTATION => {
            return "Mutation";
        }
        SUBSCRIPTION => {
            return "Subscription";
        }
    }
    return "Query";
}

isolated function getErrorRecordFromToken(Token token) returns ErrorRecord {
    Location location = token.location;
    return {
        locations: [location]
    };
}

isolated function getErrorRecordFromField(Field 'field, (string|int)[] path = []) returns ErrorRecord {
    if (path.length() == 0) {
        return {
            locations: ['field.location]
        };
    }
    return {
        locations: ['field.location],
        path: path
    };
}

isolated function getErrorJson(string message) returns json {
    return {
        errors: [
            {
                massage: message
            }
        ]
    };
}

isolated function println(anydata value) {
    io:println(value.toString());
}

isolated function print(anydata value) {
    io:print(value.toString());
}
