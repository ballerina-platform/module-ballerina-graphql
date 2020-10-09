import ballerina/java;

isolated function getStoredResource(Listener 'listener, string name) returns Scalar? = @java:Method {
    name: "getResource",
    'class: "io.ballerina.stdlib.graphql.engine.Engine"
} external;
