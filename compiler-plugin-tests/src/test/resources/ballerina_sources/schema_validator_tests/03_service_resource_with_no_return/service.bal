import ballerina/graphql;


isolated service on new graphql:Listener(9000) {

    isolated resource function get name() returns string {
    }
}
