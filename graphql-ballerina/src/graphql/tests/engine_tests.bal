import ballerina/test;

listener Listener 'listener = new(9090);

@test:Config {}
function testInvokeResource() {
    string document = readFileAndGetString(DOCUMENT_SHORTHAND, 34);
    var attachResult = 'listener.__attach(invokeResourceTestService);
    if (attachResult is error) {
        test:assertFail("Attaching the service resulted in an error." + attachResult.toString());
    }
    Engine engine = new('listener);
    var result = engine.getOutputForDocument(document);
}


service invokeResourceTestService = service {
    isolated resource function name() returns string {
        return "John Doe";
    }

    isolated resource function id() returns int {
        return 1;
    }

    isolated resource function birthDate() returns string {
        return "01-01-1980";
    }
};
