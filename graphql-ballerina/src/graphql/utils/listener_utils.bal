import ballerina/http;
import ballerina/java;
import ballerina/reflect;

isolated function getHttpListenerConfigs(ListenerConfiguration configs) returns http:ListenerConfiguration {
    http:ListenerConfiguration httpConfigs = {
        host: configs.host
    };
    return httpConfigs;
}

isolated function attach(Listener 'listener, service s, string? name) returns error? = @java:Method
{
    'class: "io.ballerina.stdlib.graphql.service.ServiceHandler"
} external;

isolated function detach(Listener 'listener, service s) returns error? = @java:Method
{
    'class: "io.ballerina.stdlib.graphql.service.ServiceHandler"
} external;

isolated function getServiceAnnotations(service s) returns GraphQlServiceConfiguration? {
    any annData = reflect:getServiceAnnotations(s, "ServiceConfiguration", "ballerina/graphql:0.1.0");
    if (!(annData is ())) {
        return <GraphQlServiceConfiguration> annData;
    }
}
