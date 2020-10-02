import ballerina/java;

isolated function attach(Listener 'listener, service s, string? name) returns error? = @java:Method
{
    'class: "org.ballerinalang.stdlib.graphql.service.ServiceHandler"
} external;
