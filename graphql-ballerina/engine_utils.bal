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
import graphql.parser;

isolated function getOutputObjectFromErrorDetail(ErrorDetail|ErrorDetail[] errorDetail) returns OutputObject {
    if (errorDetail is ErrorDetail) {
        return {
            errors: [errorDetail]
        };
    } else {
        return {
            errors: errorDetail
        };
    }
}

isolated function getErrorDetailFromError(parser:Error err) returns ErrorDetail {
    Location location = <Location>err.detail()["location"];
    return {
        message: err.message(),
        locations: [location]
    };
}

isolated function getResultJsonForError(Error err) returns map<json> {
    map<json> result = {};
    json[] jsonErrors = [getErrorJsonFromError(err)];
    result[RESULT_FIELD_ERRORS] = jsonErrors;
    return result;
}

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
    parser:Location location = <parser:Location>err.detail()["location"];
    json jsonLocation = <json>location.cloneWithType(json);
    result[FIELD_LOCATIONS] = [jsonLocation];
    return result;
}

isolated function createSchema(Service s) returns __Schema = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;

isolated function executeSingleResource(ExecutorVisitor visitor, parser:FieldNode fieldNode, map<Scalar> arguments)
returns future<any|error> = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;
