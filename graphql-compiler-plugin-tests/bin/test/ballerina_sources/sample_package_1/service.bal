import ballerina/graphql;

service graphql:Service on new graphql:Listener(4000) {
    isolated remote function greeting() returns string {
        return "Hello";
    }
}
