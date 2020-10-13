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
    var errorRecord = err.detail()["errorRecord"];
    if (errorRecord is ErrorRecord) {
        var jsonError = errorRecord.cloneWithType(json);
        if (jsonError is error) {
            json result = {
                message: jsonError.message()
            };
            return result;
        } else {
            return jsonError;
        }
    }
}
