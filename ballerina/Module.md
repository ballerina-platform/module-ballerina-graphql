## Overview

This module provides APIs for connecting and interacting with GraphQL endpoints.

GraphQL is an open-source data query and manipulation language for APIs. GraphQL allows clients to define the structure of the data required and the same structure of the data is returned from the server, preventing the returning of excessively large amounts of data.

The Ballerina GraphQL implementation is using the HTTP as the underlying protocol.

### Listener

The `graphql:Listener` is used to listen to a given IP/Port. To create a `graphql:Listener`, an `http:Listener` or a port number can be used.

#### Create a Standalone `graphql:Listener`
```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = new(4000);
```

#### Create a `graphql:Listener` Using an `http:Listener`
```ballerina
import ballerina/graphql;
import ballerina/http;

listener http:Listener httpListener = check new(4000);
listener graphql:Listener graphqlListener = new(httpListener);
```

#### Additional Configurations
When initializing the Ballerina GraphQL listener, a set of additional configurations can be provided to configure the listener including security and resiliency settings.
The configurations that can be passed for this are defined in the `graphql:ListenerConfiguration` record.

```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = new (4000, timeout = 10, secureSocket = { key: { path: <KEYSTORE_PATH>, password: <PASSWORD>}});
```

### Service
The Ballerina GraphQL service represents the GraphQL schema. When a service is attached to a `graphql:Listener`, a GraphQL schema will be auto-generated.

The GraphQL services are exposed through a single endpoint. The path of the GraphQL service endpoint can be provided via the service path of the GraphQL service. The end point of the following Ballerina GraphQL service will be `/graphql`.

```ballerina
import ballerina/graphql;

service /graphql on new graphql:Listener(4000) {
    // ...
}
```

The GraphQL service endpoint URL will be `<host>:<port>/graphql`.

Alternatively, a Ballerina graphql service can not have a path, in which case the endpoint will be the host URL and the port as the following example.

```ballerina
import ballerina/graphql;

service on new graphql:Listener(4000) {
    // ...
}
```

The GraphQL service endpoint URL will be `<host>:<port>`

#### Query Type
The `resource` functions inside the service represent the resolvers of the `Query` root type.

When a `resource` function is defined inside a GraphQL service, the generated schema will have a `Query` root type and the `resource` function will be a field of the `Query` object.

>**Note:** A GraphQL service must have at least one resource function defined. Otherwise it will result in a compilation error.

The accessor of the `resource` function should always be `get`. The `resource` function name will become the name of the particular field in the GraphQL schema. The return type of the `resource` function will be the type of the corresponding field.

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

#### Mutation Type
The `remote` functions inside the GraphQL service represent the resolvers of the `Mutation` root type.

When a `remote` function is defined inside a GraphQL service, the schema will have a `Mutation` operation and the `remote` function will be a field of the `Mutation` object.

For an example, consider the following service that has a `Person` record named `person`. It has a `Query` field named `profile`, which returns the `person` record. It also has two `remote` functions named `updateName` and `updateCity`, which are used as mutations.

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

    remote function updateCity(string city) reutns Person {
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

fragment ProfileFragment on Profile {
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

#### Additional Configurations
Additional configurations of a Ballerina GraphQL service can be provided using the `graphql:ServiceConfig`.
These configurations include security-related configurations for the GraphQL service.

##### Security Configurations
A GraphQL service can be secured by setting `auth` field in the `graphql:ServiceConfig`. Ballerina GraphQL services supports Basic Authentication, JWT Authentication and OAuth2 Authentication.

```ballerina
@graphql:SeviceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: <auth_introspection_url>,
                tokenTypeHint: <access_token>,
                scopeKey: <scope_key>,
                clientConfig: {
                    secureSocket: {
                       cert: {
                           path: <truststore_path>,
                           password: <password>
                       }
                    }
                }
            },
            scopes: [<comma_separated_list_of_scopes>]
        }
    ]
}
service graphql:Service /graphql on new graphql:Listener(4000) {
    // Service definition
}
```

##### Maximum Query Depth
When a maximum query depth is provided, all the queries exceeding that limit will be rejected at the validation phase and will not be executed.

```ballerina
import ballerina/graphql;

@graphql:ServiceConfig {
    maxQueryDepth: 2
}
service graphql:Service /graphql on new graphql:Listener(9090) {
    // Service definition
}
```

The above service only accepts queries of less than 2 levels. For an example, consider the following document:
```graphql
query getData {
    book {
        author {
            books {
                author {
                    books
                }
            }
        }
    }
}
```

The result for the above query is the following JSON:

```json
{
    "errors": [
        {
            "message": "Query \"getData\" has depth of 5, which exceeds max depth of 2",
            "locations": [
                {
                    "line": 1,
                    "column": 1
                }
            ]
        }
    ]
}
```

##### Context Init
This field is used to initialize the `graphql:Context` object. Usage of the `graphql:Context` will be described in a separate section.

### Context
The `graphql:Context` can be used to pass meta-information among the graphql resolver (`resource`/`remote`) functions. It will be created per each request, with a defined set of attributes. Attributes can be stored in the `graphql:Context` object using key-value pairs. The key should always be a `string`. The type of the value is `value:Cloneable|isolated object {}`. This means the values can be any immutable type, `readonly` value, or an isolated object. These attributes can be set using a function, which can be given as a service configuration parameter.

#### Context Init
The `graphql:Context` can be initialized using a function. The function signature is as follows:
```ballerina
isolated function (http:RequestContext requestContext, http:Request request) returns graphql:Context|error {}
```

The values from the `http:RequestContext` and the `http:Request` can be set as attributes of the `graphql:Context` since they are passed as arguments for this function. Then the function should be provided as a `graphql:ServiceConfig` parameter.

Following are examples for providing the context init function.

##### Providing the Init Function Directly
```ballerina
import ballerina/graphql;
import ballerina/http;

@graphql:ServiceConfig {
    contextInit: isolated function(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
        graphql:Context context = new;
        check context.add("<key>", <value>);
        return context;
    }
}
service on new graphql:Listener(4000) {
    // ...
}
```

##### Providing the Init Function as a Function Pointer
```ballerina
import ballerina/graphql;
import ballerina/http;

isolated function initContext(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
    graphql:Context context = new;
    check context.add("<key>", <value>);
    return context;
}

@graphql:ServiceConfig {
    contextInit: initContext
}
service on new graphql:Listener(4000) {
    // ...
}
```

> **Note:** Even if the context init function is not provided, a default, empty context will be created per each request.

#### Using the Context in Resolver Functions
If the `graphql:Context` needs to be accessed, the resolver function has to add it as the first parameter of the function.
Following is an example:

```ballerina
service on new graphql:Listener(4000) {
    resource function get greet(graphql:Context context) returns string {
        return "Hello, World!";
    }
}
```

This is similar for any `remote` function, or a `resource` function inside a service object used as a GraphQL object type.

#### Retrieving Attributes from the Context
There are two methods to retrieve attributes from the `graphql:Context`.

##### `get()` Function
This will return the value of the attribute using the provided key. If the key does not exist, it will return a `graphql:Error`.

```ballerina
resource function get greeting(graphql:Context context) returns string|error {
    var username = check context.get("username");
    if username is string {
        return "Hello, " + username;
    }
    return "Hello, World!";
}
```

##### `remove()` Function
This function will remove the attribute for a provided key, and return the value. If the key does not exist, it will return a `graphql:Error`.

> **Note:** Even though this is supported, destructive-modification of the `graphql:Context` is discouraged. This is because these modifications may affect the parallel executions in queries.

```ballerina
resource function get greeting(graphql:Context context) returns string|error {
    var username = check context.remove("username");
    if username is string {
        return "Hello, " + username;
    }
    return "Hello, World!";
}
```

### Types
The Ballerina GraphQL resources can return the following types:

#### Return Types

##### Scalar types
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

##### Record types

When a `resource` function is returning a `record` type, each field of the record can be queried separately.
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

#### Service Types
When a `resource` function returns a service type, the service type is mapped to a GraphQL `OBJECT` type and the `resource` functions of the service type will be mapped as the fields of the `OBJECT`.

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

    resource function get name() returns string {
        return self.name;
    }

    resource function get age() returns int {
        return self.age;
    }
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
A GraphQL `resource` function can return an array of the types mentioned above. When a `resource` function is returning an array, the result will be a JSON array.

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


#### Optional Types
A Ballerina GraphQL `resource` function can return an optional type. When the return value is `()`, the resulting field in the JSON will be `null`.

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

#### Union Types
The Ballerina GraphQL service can return a union of distinct service types. This will be mapped to a GraphQL `UNION` type.

Since Ballerina supports union types by nature, directly returning a union type is also allowed (but not recommended). The recommended way is to define a union type name separately and then use that type name as shown in the following example. If a union type is returned directly without providing a type name, the type name will be `T1|T2|T3|...|Tn`.

```ballerina
import ballerina/graphql;

public type StudentOrTeacher Student|Teacher;

service /graphql on new graphql:Listener(4000) {
    resource function get profile(int purity) returns StudentOrTeacher {
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
    profile(purity: Int!): StudentOrTeacher!
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

union StudentOrTeacher Student|Teacher
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

#### Errors (With union)
A Ballerina GraphQL `resource` function can return an `error` with the union of the types mentioned above.

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

#### Hierarchical Resource Paths
A `resource` function inside a GraphQL service can have hierarchical paths.
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
