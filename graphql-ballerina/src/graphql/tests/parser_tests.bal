import ballerina/test;

@test:Config{}
function testParseShorthandDocument() returns error? {
    //string document = getShorthandNotationDocument();
    //Document parsedDocument = check parse(document);
    //Document expectedDocument = {
    //    operations: [
    //        {
    //            'type: "query",
    //            fields: ["name", "id", "birthDate"]
    //        }
    //    ]
    //};
    //test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseGeneralNotationDocument() returns error? {
    string document = getGeneralNotationDocument();
    Document parsedDocument = check parse(document);
    Operation expectedOperation = {
        'type: "query",
        name: "getData",
        fields: ["name", "id", "birthDate"]
    };
    Document expectedDocument = {
        operations: [expectedOperation]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseAnonymousOperation() returns error? {
    string document = getAnonymousOperationDocument();
    var result = parse(document);
}

@test:Config{}
function testParseDocumentWithNoCloseBrace() returns error? {
    string document = getNoCloseBraceDocument();
    var result = parse(document);
}
