import ballerina/test;

@test:Config{}
function testParseDocument() {
    var fileText = readFileAndGetDocument("src/graphql/resources/document.txt", 34);
    if (fileText is error) {
        logAndPanicError("Error occurred while reading the document", fileText);
    }
    string document = <string>fileText;
    Document parsedDocument = parse(document);
    Document expectedDocument = {
        operation: "query",
        fields: ["name", "id", "birthDate"]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseDocumentWithOperation() {
    var fileText = readFileAndGetDocument("src/graphql/resources/document_with_operation.txt", 47);
    if (fileText is error) {
        logAndPanicError("Error occurred while reading the document", fileText);
    }
    string document = <string>fileText;
    Document parsedDocument = parse(document);
    Document expectedDocument = {
        operation: "query",
        operationName: "getData",
        fields: ["name", "id", "birthDate"]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}
