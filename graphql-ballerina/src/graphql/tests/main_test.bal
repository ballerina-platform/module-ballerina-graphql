import ballerina/http;
import ballerina/io;
import ballerina/test;

listener Listener gqlListener = new(9091);

@test:Config{}
function testAttach() {
    string document = getShorthandNotationDocument();
    var result = gqlListener.__attach(gqlService);
    json payload = {
        query: document
    };

    http:Client httpClient = new("http://localhost:9091/bakerstreet");
    http:Request request = new;
    request.setPayload(payload);

    var sendResult = httpClient->post("/", request);
    if (sendResult is error) {
        test:assertFail("Error response received for the HTTP call");
    } else {
        var responsePayload = sendResult.getJsonPayload();
        if (responsePayload is json) {
            io:println(responsePayload.toString());
        }
    }
    var stopResult = gqlListener.__immediateStop();
}

service gqlService =
@ServiceConfiguration {
    basePath: "bakerstreet"
}
service {
    isolated resource function name() returns string {
        return "Prof. James Moriarty";
    }

    isolated resource function birthDate() returns string {
        return "01-01-1880";
    }
};
