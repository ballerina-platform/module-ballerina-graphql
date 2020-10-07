//import ballerina/http;
import ballerina/java;

isolated function attach(Listener 'listener, service s, string? name) returns ListenerError? = @java:Method
{
    'class: "io.ballerina.stdlib.graphql.service.ServiceHandler"
} external;

isolated function detach(Listener 'listener, service s) returns ListenerError? = @java:Method
{
    'class: "io.ballerina.stdlib.graphql.service.ServiceHandler"
} external;

//isolated function getHttpService() returns service {
//    return service {
//        resource isolated function query(http:Caller caller, http:Request request) {
//
//        }
//    };
//}
