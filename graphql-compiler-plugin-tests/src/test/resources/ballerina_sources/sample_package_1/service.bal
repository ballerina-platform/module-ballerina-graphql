import ballerina/graphql;

service graphql:Service on new graphql:Listener(4000) {
    isolated resource function get greeting() returns string {
        return "Hello";
    }
}
