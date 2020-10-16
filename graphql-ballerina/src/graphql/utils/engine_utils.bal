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

isolated function validateDocument(Engine engine, Document document) returns ValidationError? {
    map<Operation> operations = document.operations;
    if (operations.length() > 1) {
        return NotImplementedError("Ballerina GraphQL does not support multiple operations yet.");
    } else if (operations.length() == 0) {
        return InvalidDocumentError("Document does not contain any operation.");
    }
    foreach Operation operation in operations {
        check validateOperation(engine, operation);
    }
}

isolated function validateOperation(Engine engine, Operation operation) returns ValidationError? {
    OperationType 'type = operation.'type;
    if ('type != QUERY) {
        string message = "Ballerina GraphQL does not support " + getOperationName('type) + " operation yet.";
        return NotImplementedError(message);
    }

    Token[] tokens = operation.fields;
    foreach Token token in tokens {
        check validateField(engine, token, 'type);
    }
}

isolated function validateField(Engine engine, Token token, OperationType 'type) returns ValidationError? {
    string value = token.value;
    int? index = engine.getFields().indexOf(value);
    if (index is ()) {
        string message = "Cannot query field \"" + value + "\" on type \"" + getOperationName('type) + "\".";
        ErrorRecord errorRecord = getErrorRecordFromToken(token);
        return FieldNotFoundError(message, errorRecord = errorRecord);
    }
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

isolated function executeResource(Listener 'listener, string name) returns Scalar|error? = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;

isolated function getFieldNames(service s) returns string[] = @java:Method {
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;
