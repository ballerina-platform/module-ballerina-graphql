import ballerina/io;
import ballerina/http;

listener Listener gqlListener = new();

public function main() {
    http:Client httpClient = new("http://localhost:9090/graphQL");
    var document = readFileAndGetDocument("src/graphql/resources/document.txt");
    if (document is error) {
        logAndPanicError("Error occurred while reading the document", document);
    }
    string payload = <string>document;
    io:print(payload);
}

service gqlService on gqlListener {
    resource function get(Caller caller, string document) {
        
    }

    resource function name() returns string {
        return "Thisaru";
    }

    resource function id() returns int {
        return 1;
    }

    resource function birthDate() returns string {
        return "1990-05-15";
    }
}
