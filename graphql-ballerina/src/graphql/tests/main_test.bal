import ballerina/test;

listener Listener gqlListener = new(9091);

@test:Config{}
function testAttach() {
    var result = gqlListener.__attach(gqlService);
    var resourceValue = getStoredResource(gqlListener, "name");
    test:assertEquals(resourceValue, "John Doe");
}

service gqlService = service {
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
