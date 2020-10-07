import ballerina/test;

@test:Config{}
function testParseDocument() returns error? {
    string document = readFileAndGetString(DOCUMENT_SHORTHAND, 34);
    Document parsedDocument = check parse(document);
    Document expectedDocument = {
        operation: "query",
        fields: ["name", "id", "birthDate"]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseDocumentWithOperation() returns error? {
    string document = readFileAndGetString(DOCUMENT_FULL, 47);
    Document parsedDocument = check parse(document);
    Document expectedDocument = {
        operation: "query",
        operationName: "getData",
        fields: ["name", "id", "birthDate"]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}
