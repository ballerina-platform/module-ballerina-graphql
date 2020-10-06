import ballerina/java;

isolated function getStoredResourceExt(Listener 'listener, string name) returns Scalar = @java:Method {
    name: "getResource",
    'class: "org.ballerinalang.stdlib.graphql.engine.Engine"
} external;
