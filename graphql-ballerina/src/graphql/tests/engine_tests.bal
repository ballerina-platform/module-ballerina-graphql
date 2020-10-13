import ballerina/test;

listener Listener 'listener = new(9090);

@test:Config {}
function testInvokeResource() {
    string document = getShorthandNotationDocument();
    var attachResult = 'listener.__attach(invokeResourceTestService);
    if (attachResult is error) {
        test:assertFail("Attaching the service resulted in an error." + attachResult.toString());
    }
    var result = getOutputForDocument('listener, document);
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
