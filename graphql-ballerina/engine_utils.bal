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
    int line = <int>err.detail()["line"];
    int column = <int>err.detail()["column"];
    Location location = { line: line, column: column };
    return {
        message: err.message(),
        locations: [location]
    };
}

isolated function getFieldMapForSelection(parser:FieldNode fieldNode, map<anydata> data) returns map<anydata>|error {
    map<anydata> result = {};
    foreach parser:FieldNode selection in fieldNode.getSelections() {
        var fieldValue = data[selection.getName()];
        if (fieldValue is map<anydata>) {
            result[selection.getName()] = <anydata> getFieldMapForSelection(selection, fieldValue);
        } else {
            result[selection.getName()] = fieldValue;
        }
    }
    return result;
}

isolated function createSchema(Service s) returns __Schema = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;

isolated function executeSingleResource(ExecutorVisitor visitor, parser:FieldNode fieldNode, map<Scalar> arguments)
returns anydata = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;
