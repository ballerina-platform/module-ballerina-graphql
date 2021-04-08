import ballerina/graphql;

service graphql:Service on new graphql:Listener(4000) {
    isolated remote function get greeting() returns string {
        return "Hello";
    }
}
