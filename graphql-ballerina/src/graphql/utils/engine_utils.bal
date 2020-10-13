import ballerina/java;

isolated function getStoredResource(Listener 'listener, string name) returns Scalar|error? = @java:Method {
    name: "getResource",
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;

isolated function getResultJson(map<json> data, json[] errors) returns map<json> {
    map<json> result = {};
    if (data.length() > 0) {
        result[RESULT_FIELD_DATA] = data;
    }
    if (errors.length() > 0) {
        result[RESULT_FIELD_ERRORS] = errors;
    }
    return result;
}

isolated function getErrorJsonFromError(Error err) returns json {
    map<json> result = {};
    result["message"] = err.message();
    var errorRecord = err.detail()[FIELD_ERROR_RECORD];
    if (errorRecord is ErrorRecord) {
        json[] jsonLocations = getLocationsJsonArray(errorRecord?.locations);
        if (jsonLocations.length() > 0) {
            result["locations"] = jsonLocations;
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
