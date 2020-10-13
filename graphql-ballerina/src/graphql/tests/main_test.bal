import ballerina/http;
import ballerina/test;

listener Listener gqlListener = new(9091);

@test:Config{}
function testSimpleGraphqlQuery() {
    string document = getShorthandNotationDocument();
    var result = gqlListener.__attach(gqlService);
    json payload = {
        query: document
    };
    json expectedJson = {
        data: {
            name: "John Doe",
            birthDate: "01-01-1980"
        },
        errors: [
            {
                message: "Cannot query field \\\"id\\\" on type \\\"QUERY\\\".",
                locations: [
                    {
                        line: 3,
                        column: 4
                    }
                ]
            }
        ]
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
            test:assertEquals(responsePayload, expectedJson);
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
        return "John Doe";
    }

    isolated resource function birthDate() returns string {
        return "01-01-1980";
    }
};
