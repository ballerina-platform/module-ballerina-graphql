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

    resource function name(Caller caller) {
        string name = "Thisaru";
        var result = caller->respond(name);
    }

    resource function id(Caller caller) {
        int id = 1;
        var result = caller->respond(id);
    }

    resource function birthDate(Caller caller) {
        string birthDate = "1990-05-15";
        var result = caller->respond(birthDate);
    }
}
