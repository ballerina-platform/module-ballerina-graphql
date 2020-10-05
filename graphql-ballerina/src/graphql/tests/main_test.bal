import ballerina/io;
import ballerina/http;
import ballerina/test;

listener Listener gqlListener = new(9091);

@test:Config{}
function testAttach() {
    http:Client httpClient = new("http://localhost:9090/graphQL");
    var document = readFileAndGetDocument("src/graphql/resources/document.txt");
    if (document is error) {
        logAndPanicError("Error occurred while reading the document", document);
    }
    string payload = <string>document;
    io:print(payload);
}

service gqlService on gqlListener {
    isolated resource function name() returns string {
        return "John Doe";
    }

    isolated resource function id() returns int {
        return 1;
    }

    isolated resource function birthDate() returns string {
        return "01-01-1980";
    }
}
