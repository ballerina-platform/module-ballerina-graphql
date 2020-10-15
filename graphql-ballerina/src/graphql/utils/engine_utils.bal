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

import ballerina/java;

isolated function getStoredResource(Listener 'listener, string name) returns Scalar|error? = @java:Method {
    name: "getResource",
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;

isolated function getFieldNames(service s) returns string[] = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;

isolated function getResultJson(map<json> data, json[] errors) returns map<json> {
    map<json> result = {};
    if (errors.length() > 0) {
        result[RESULT_FIELD_ERRORS] = errors;
    }
    if (data.length() > 0) {
        result[RESULT_FIELD_DATA] = data;
    }
    return result;
}

isolated function getErrorJsonFromError(Error err) returns json {
    map<json> result = {};
    result[FIELD_MESSAGE] = err.message();
    var errorRecord = err.detail()[FIELD_ERROR_RECORD];
    if (errorRecord is ErrorRecord) {
        json[] jsonLocations = getLocationsJsonArray(errorRecord?.locations);
        if (jsonLocations.length() > 0) {
            result[FIELD_LOCATIONS] = jsonLocations;
        }
    }
    return result;
}

isolated function getLocationsJsonArray(Location[]? locations) returns json[] {
    json[] jsonLocations = [];
    if (locations is Location[]) {
        foreach Location location in locations {
            json jsonLocation = <json>location.cloneWithType(json);
            jsonLocations.push(jsonLocation);
        }
    }
    return jsonLocations;
}
