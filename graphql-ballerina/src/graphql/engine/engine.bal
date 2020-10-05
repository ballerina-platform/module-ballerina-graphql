isolated function getOperation(string document, string opeartionName) returns string|error {
    return error("not implemented");
}

function getStoredResource(Listener 'listener, string name) returns Scalar {
    return getStoredResourceExt('listener, name);
}
