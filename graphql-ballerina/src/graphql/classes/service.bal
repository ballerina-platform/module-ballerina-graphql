import ballerina/http;
import ballerina/log;

service httpService =
@http:ServiceConfig {
    basePath: basePath
}
service {
    @http:ResourceConfig {
        path: "/",
        methods: ["GET"]
    }
    resource isolated function get(http:Caller caller, http:Request request) {
        log:printInfo("HTTP service - GET request");
    }

    @http:ResourceConfig {
        path: "/",
        methods: ["POST"]
    }
    resource isolated function post(http:Caller caller, http:Request request) {
        log:printInfo("HTTP service - POST request");
    }
};
