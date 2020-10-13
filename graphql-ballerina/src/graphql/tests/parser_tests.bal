import ballerina/test;

Token[] fields = [
    {
        value: "name",
        line: 2,
        column: 4
    },
    {
        value: "id",
        line: 3,
        column: 4
    },
    {
        value: "birthDate",
        line: 4,
        column: 4
    }
];

@test:Config{}
function testParseShorthandDocument() returns error? {
    string document = getShorthandNotationDocument();
    Document parsedDocument = check parse(document);
    Document expectedDocument = {
        operations: [
            {
                'type: "query",
                fields: fields
            }
        ]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseGeneralNotationDocument() returns error? {
    string document = getGeneralNotationDocument();
    Document parsedDocument = check parse(document);
    Operation expectedOperation = {
        'type: "query",
        name: "getData",
        fields: fields
    };
    Document expectedDocument = {
        operations: [expectedOperation]
    };
    test:assertEquals(parsedDocument, expectedDocument);
}

@test:Config{}
function testParseAnonymousOperation() returns error? {
    string document = getAnonymousOperationDocument();
    Document result = check parse(document);
    Document expected = {
        operations: [
            {
                'type: "query",
                fields: fields
            }
        ]
    };
    test:assertEquals(result, expected);
}

@test:Config{}
function testParseDocumentWithNoCloseBrace() returns error? {
    string document = getNoCloseBraceDocument();
    Document|Error result = parse(document);
    if (result is Document) {
        test:assertFail("Expected error, received document");
    } else {
        test:assertEquals(result.message(), "Syntax Error: Expected Name, found \\\"<EOF>\\\".");
    }
}
