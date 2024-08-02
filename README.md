# Ballerina GraphQL Library

  [![Build](https://github.com/ballerina-platform/module-ballerina-graphql/actions/workflows/build-timestamped-master.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-graphql/actions/workflows/build-timestamped-master.yml)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-graphql/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-graphql)
  [![Trivy](https://github.com/ballerina-platform/module-ballerina-graphql/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-graphql/actions/workflows/trivy-scan.yml)
  [![GraalVM Check](https://github.com/ballerina-platform/module-ballerina-graphql/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-graphql/actions/workflows/build-with-bal-test-graalvm.yml)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-graphql.svg)](https://github.com/ballerina-platform/module-ballerina-graphql/commits/master)
  [![Github issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/graphql.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Fgraphql)

## Overview

This library provides APIs for connecting and interacting with GraphQL endpoints.

GraphQL is an open-source data query and manipulation language for APIs. GraphQL allows clients to define the structure of the data required and the same structure of the data is returned from the server, preventing the returning of excessively large amounts of data or reducing the number of requests sent to the server.

The Ballerina GraphQL implementation is using HTTP as the underlying protocol.

## Listener

The `graphql:Listener` is used to listen to a given IP/Port. To create a `graphql:Listener`, an `http:Listener` or a port number can be used.

### Create a standalone `graphql:Listener`

```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = check new(4000);
```

### Create a `graphql:Listener` using an `http:Listener`

```ballerina
import ballerina/graphql;
import ballerina/http;

listener http:Listener httpListener = check new(4000);
listener graphql:Listener graphqlListener = check new(httpListener);
```

## Service

The Ballerina GraphQL service represents the GraphQL schema. When a service is attached to a `graphql:Listener`, a GraphQL schema will be auto-generated.

The GraphQL services are exposed through a single endpoint. The path of the GraphQL service endpoint can be provided via the service path of the GraphQL service. The endpoint of the following Ballerina GraphQL service will be `/graphql`.

```ballerina
import ballerina/graphql;

service graphql:Service /graphql on graphqlListener {
    // ...
}
```

The GraphQL service endpoint URL will be `<host>:<port>/graphql`.

Alternatively, a Ballerina graphql service can not have a path, in which case the endpoint will be the host URL and the port as following example.

```ballerina
import ballerina/graphql;

service graphql:Service on graphqlListener {
    // ...
}
```

The GraphQL service endpoint URL will be `<host>:<port>`

Alternatively, the listener and service initialization can be combined into a single statement as follows:

```ballerina
service graphql:Service on new graphql:Listener(9090) {

}
```

### Query type

The `resource` functions inside the GraphQL service can represent the resolvers of the `Query` root type.

When a `resource` function is defined inside a GraphQL service with the `get` accessor, the generated schema will have a `Query` root type and the `resource` function will be a field of the `Query` object.

>**Note:** A GraphQL service must have at least one resource function defined. Otherwise, it will result in a compilation error.

The `resource` method must use the `get` accessor for a field to be considered as a `Query` field. The `resource` function name will become the name of the particular field in the GraphQL schema. The return type of the `resource` function will be the type of the corresponding field.

```ballerina
import ballerina/graphql;

service graphql:Service /graphql on new graphql:Listener(4000) {
    resource function get greeting(string name) returns string {
        return "Hello, " + name;
    }
}
```

The above can be queried using the GraphQL document below:

```graphql
{
    greeting(name: "John")
}
```

The result will be the following JSON.

```json
{
    "data": {
        "greeting": "Hello, John"
    }
}
```

### Mutation type

The `remote` functions inside the GraphQL service represent the resolvers of the `Mutation` root type.

When a `remote` function is defined inside a GraphQL service, the schema will have a `Mutation` operation and the `remote` function will be a field of the `Mutation` object.

For example, consider the following service that has a `Person` record named `profile`. It has a `Query` field named `profile`, which returns the `Person` record. It also has two `remote` functions named `updateName` and `updateCity`, which are used as mutations.

```ballerina
import ballerina/graphql;

public type Person record {|
    string name;
    int age;
    string city;
|};

service /graphql on new graphql:Listener(4000) {
    private Person profile;

    function init() {
        self.profile = { name: "Walter White", age: 50, city: "Albuquerque" };
    }

    resource function get profile() returns Person {
        return self.profile;
    }

    remote function updateName(string name) returns Person {
        self.profile.name = name;
        return self.profile;
    }

    remote function updateCity(string city) returns Person {
        self.profile.city = city;
        return self.profile;
    }
}
```

This will generate the following schema:

```graphql
type Query {
    profile: Person!
}

type Mutation {
    updateName(name: String!): Person!
    updateCity(city: String!): Person!
}

type Person {
    name: String!
    age: Int!
    city: String!
}
```

>**Note:** A GraphQL schema must have a root `Query` type. Therefore, a Ballerina GraphQL service must have at least one `resource` function defined.

This can be mutated using the following document.

```graphql
mutation updatePerson {
    updateName(name: "Mr. Lambert") {
        ... ProfileFragment
    }
    updateCity(city: "New Hampshire") {
        ... ProfileFragment
    }
}

fragment ProfileFragment on Person {
    name
    city
}
```

>**Note:** This document uses two mutations and each mutation requests the same fields from the service using a fragment (`ProfileFragment`).

Result:

```json
{
    "data": {
        "updateName": {
            "name": "Mr. Lambert",
            "city": "Albuquerque"
        },
        "updateCity": {
            "name": "Mr. Lambert",
            "city": "New Hampshire"
        }
    }
}
```

See how the result changes the `Person` record. The first mutation changes only the name and it populates the result of the `updateName` field. Then, it will execute the `updateCity` operation and populate the result. This is because the execution of the mutation operations will be done serially in the same order as they are specified in the document.

### Subscription Type

The subscription type can be used to continuously fetch the data from a GraphQL service.

The `resource` functions inside the GraphQL service with the `subscribe` accessor can represent the resolvers of the `Subscription` root type.

When a `resource` function is defined inside a GraphQL service with the `subscribe` accessor, the generated schema will have a `Subscription` root type and the `resource` function will be a field of the `Subscription` object.

The `resource` method must use the `subscribe` accessor for a field to be considered as a `Subscription` field. The `resource` function name will become the name of the particular field in the GraphQL schema. The return type of the `resource` function will be the type of the corresponding field.

The `resource` functions that belong to `Subscription` type must return a stream of `any` type. Any other return type will result in a compilation error.

The return type

```ballerina
import ballerina/graphql;

service graphql:Service /graphql on new graphql:Listener(4000) {
    resource function subscribe messages() returns stream<string> {
        return ["Walter", "Jesse", "Mike"].toStream();
    }
}
```

The above can be queried using the GraphQL document below:

```graphql
subscription {
    messages
}
```

When a subscription type is defined, a WebSocket service will be created to call the subscription. The above service
will create the service as follows:

```none
ws://<host>:4000/graphql
```

This can be accessed using a WebSocket client. When the returned stream has a new entry, it will be broadcast to the subscribers.

## Types

The Ballerina GraphQL resolver (`resource`/`remote`) methods can return the following types:

### Return types

#### Scalar types

When a Ballerina primitive type is returned from a `resource` or a `remote` method, it will be mapped to a GraphQL `NON_NULL` type of the corresponding GraphQL scalar type.

The following Ballerina types are considered as Scalar types:

* `int`
* `string`
* `boolean`
* `float`

```ballerina
resource function get greeting() returns string {
    return "Hello, World";
}
```

This can be queried using the following document:

```graphql
{
    greeting
}
```

Result:

```json
{
    "data": {
        "greeting": "Hello, World"
    }
}
```

#### Enums

When a `resource` or a `remote` function returns an `enum` value, it will be mapped to a GraphQL `ENUM` type.

```ballerina
import ballerina/graphql;

public enum Color {
    RED,
    GREEN,
    BLUE
}

service on new graphql:Listener(4000) {
    resource function get color(int code) returns Color {
        // ...
    }
}
```

The above service will generate the following GraphQL schema.

```graphql
type Query {
    color: Color!
}

enum Color {
    RED
    GREEN
    BLUE
}
```

#### Record types

When a `resource` or `remote` method is returning a `record` type, each field of the record can be queried separately.
Each `record` type is mapped to a GraphQL `OBJECT` type and the fields of the `record` type are mapped to the fields of the `OBJECT` type.

```ballerina
public type Person record {|
    string name;
    int age;
|};

resource function get profile() returns Person {
    return { name: "Walter White", age: 51 };
}
```

This will generate the following schema.

```graphql
type Query {
    profile: Person!
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:

```graphql
{
    profile {
        name
        age
    }
}
```

Result:

```json
{
    "data": {
        "profile": {
            "name": "Walter White",
            "age": 51
        }
    }
}
```

Each field can be queried separately as shown in the following document:

```graphql
{
    profile {
        name
    }
}
```

Result:

```json
{
    "data": {
        "profile": {
            "name": "Walter White"
        }
    }
}
```

#### Service types

When a `resource` function returns a service type, the service type is mapped to a GraphQL `OBJECT` type and the `resource` methods of the service type will be mapped as the fields of the `OBJECT`.

When a service type is returned from a `graphql:Service`, the returning service type should also follow the rules of the `graphql:Service` explained above.

```ballerina
import ballerina/graphql;

service graphql:Service /graphql on new graphql:Listener(4000) {
    resource function get profile() returns Person {
        return new("Walter White", 51);
    }
}

service class Person {
    private string name;
    private int age;

    public function init(string name, int age) {
        self.name = name;
        self.age = age;
    }

    resource function get name() returns string => self.name;

    resource function get age() returns int => self.age;
}
```

This will generate the following schema:

```graphql
type Query {
    profile: Person!
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:

```graphql
query getProfile {
    profile {
        name
    }
}
```

The above will result in the following JSON:

```json
{
    "data": {
        "profile": {
            "name": "Walter White"
        }
    }
}
```

#### Arrays

A GraphQL `resource` function can return an array of the types mentioned above. When a `resource` method returns an array, the corresponding GraphQL field will be the type of `LIST`.

```ballerina
public type Person record {|
    string name;
    int age;
|};

resource function get people() returns Person[] {
    Person p1 = { name: "Walter White", age: 51 };
    Person p2 = { name: "James Moriarty", age: 45 };
    Person p3 = { name: "Tom Marvolo Riddle", age: 71 };
    return [p1, p2, p3];
}
```

This will generate the following schema:

```graphql
type Query {
    profile: [Person!]!
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:

```graphql
{
    people {
        name
    }
}
```

Result:

```json
{
    "data": {
        "people": [
            {
                "name": "Walter White"
            },
            {
                "name": "James Moriarty"
            },
            {
                "name": "Tom Marvolo Riddle"
            }
        ]
    }
}
```

> **Note:** Each element in the array consists only of the required `name` field.

#### Nullable types

A Ballerina GraphQL `resource` function can return a union of a type and nil. When a `resource` method returns a union of a type and nil, the corresponding GraphQL field will be of a nullable type.

```ballerina
public type Person record {|
    string name;
    int age;
|};

resource function get profile(int id) returns Person? {
    if (id == 1) {
        return { name: "Walter White", age: 51 };
    }
}
```

This will generate the following schema:

```graphql
type Query {
    profile: Person
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:

```graphql
{
    profile(id: 1) {
        name
    }
}
```

Result:

```json
{
    "data": {
        "profile": {
            "name": "Walter White"
        }
    }
}
```

If the following document is used:

```graphql
{
    profile(id: 4) {
        name
    }
}
```

This will be the result:

```json
{
    "data": {
        "profile": null
    }
}
```

#### Union types

The Ballerina GraphQL service can return a union of distinct service types. This will be mapped to a GraphQL `UNION` type.

> **Note:** If a union type is returned directly without providing a type name (`returns T1|T2|T3`), the type name will be `T1_T2_T3`.

```ballerina
import ballerina/graphql;

public type Profile Student|Teacher;

service /graphql on new graphql:Listener(4000) {
    resource function get profile(int purity) returns Profile {
        if (purity < 90) {
            return new Student(1, "Jesse Pinkman");
        } else {
            return new Teacher(737, "Walter White", "Chemistry");
        }
    }
}

distinct service class Student {
    private int id;
    private string name;

    public function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    resource function get id() returns int {
        return self.id;
    }

    resource function get name() returns string {
        return self.name;
    }
}

distinct service class Teacher {
    private int id;
    private string name;
    private string subject;

    public function init(int id, string name, string subject) {
        self.id = id;
        self.name = name;
        self.subject = subject;
    }

    resource function get id() returns int {
        return self.id;
    }

    resource function get name() returns string {
        return self.name;
    }

    resource function get subject() returns string {
        return self.subject;
    }
}
```

This will generate the following schema:

```graphql
type Query {
    profile(purity: Int!): Profile!
}

type Student {
    id: Int!
    name: String!
}

type Teacher {
    id: Int!
    name: String!
    subject: String!
}

union Profile = Student|Teacher
```

This can be queried using the following document:

```graphql
query {
    profile(purity: 75) {
        ... on Student {
            name
        }
        ... on Teacher {
            name
            subject
        }
    }
}
```

The result will be:

```json
{
    "data": {
        "profile": {
            "name": "Jesse Pinkman"
        }
    }
}
```

If the following document is used:

```graphql
query {
    profile(purity: 99) {
        ... on Student {
            name
        }
        ... on Teacher {
            name
            subject
        }
    }
}
```

The result will be:

```json
{
    "data": {
        "profile": {
            "name": "Walter White",
            "subject": "Chemistry"
        }
    }
}
```

#### Errors

A Ballerina GraphQL `resource` or `remote` method can return an `error` with the union of the types mentioned above.

> **Note:** A `resource` or a `remote` function cannot return only an `error`, any subtype of an `error`, or, an `error?`, which will result in a compilation error.

```ballerina
public type Person record {|
    string name;
    int age;
|};

resource function get profile(int id) returns Person|error {
    if (id == 1) {
        return { name: "Walter White", age: 51 };
    } else {
        return error(string `Invalid ID provided: ${id}`);
    }
}
```

This can be queried using the following document:

```graphql
{
    profile(id: 5) {
        name
    }
}
```

Result:

```json
{
    "errors": [
        {
            "message": "Invalid ID provided: 5",
            "locations": [
                {
                    "line": 2,
                    "column": 4
                }
            ]
        }
    ]
}
```

> **Note:** The error message will be logged to the console and the error will be returned to the client.

### Hierarchical resource paths

A `resource` method inside a GraphQL service can have hierarchical paths.

When a hierarchical path is present, each level of the hierarchical path maps to the GraphQL field of the same name, and the type of that field will be mapped to an `OBJECT` type with the same name.

```ballerina
import ballerina/graphql;

service graphql:Service /graphql on new graphq:Listener(4000) {
    resource function profile/name/first() returns string {
        return "Walter";
    }

    resource function profile/name/last() returns string {
        return "White"
    }

    resource function profile/age() returns int {
        return 51;
    }
}
```

The above service will create the following schema:

```graphql
type Query {
    profile: profile!
}

type profile {
    name: name!
    age: Int!
}

type name {
    first: String!
    last: String!
}
```

> **Note:** The field name and the type names are equal.

Refer to the [Ballerina GraphQL specification](https://ballerina.io/spec/graphql) for more information.

## Issues and projects

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina Library. To report bugs, request new features, start new discussions, view project boards, etc., go to the [Ballerina Library parent repository](https://github.com/ballerina-platform/ballerina-standard-library).
This repository only contains the source code for the module.

## Build from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 17 (from one of the following locations).

   * [Oracle](https://www.oracle.com/java/technologies/downloads/)
   * [OpenJDK](https://adoptium.net/)

        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Generate a GitHub access token with read package permissions, then set the following `env` variables:

    ```shell
   export packageUser=<Your GitHub Username>
   export packagePAT=<GitHub Personal Access Token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To run a group of tests

   ```bash
   ./gradlew clean test -Pgroups=<test_group_names>
   ```

4. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`graphql` library](https://lib.ballerina.io/ballerina/graphql/latest).
* For the specifications of the package, go to the [Ballerina GraphQL specification](https://ballerina.io/spec/graphql).
* For example, demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
