import ballerina/graphql;

public type Person record {
    string name;
    int age;
    Address[] addresses = [];
};

public type Address record {
    int number;
    string street;
    string city;
};

isolated service on new graphql:Listener(9000) {

    isolated resource function get name(Person person) returns string {
        return person.name;
    }
}
