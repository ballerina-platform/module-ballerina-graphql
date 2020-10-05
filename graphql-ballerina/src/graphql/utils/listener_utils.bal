//import ballerina/http;
import ballerina/java;

isolated function attach(Listener 'listener, service s, string? name) returns error? = @java:Method
{
    'class: "org.ballerinalang.stdlib.graphql.service.ServiceHandler"
} external;

//isolated function getHttpService() returns service {
//    return service {
//        resource isolated function query(http:Caller caller, http:Request request) {
//
//        }
//    };
//}
