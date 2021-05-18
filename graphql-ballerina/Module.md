## Overview

This module provides an implementation for connecting and interacting with GraphQL endpoints.

GraphQL is an open-source data query and manipulation language for APIs. GraphQL allows clients to define the structure of the data required, and the same structure of the data is returned from the server, therefore preventing the returning of excessively large amounts of data.

The Ballerina GraphQL implementation is using HTTP as the underlying protocol.

### Listener

The `graphql:Listener` is used to listen to a given IP/Port. To create a `graphql:Listener`, an `http:Listener` or a port number can be used.

#### Create a standalone `graphql:Listener`
```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = new(4000);
```

#### Create a `graphql:Listener` using an `http:Listener`
```ballerina
import ballerina/graphql;
import ballerina/http;

listener http:Listener httpListener = check new(4000);
listener graphql:Listener graphqlListener = new(httpListener);
```

#### Additional Configurations
When initializing the Ballerina GraphQL listener, a set of additional configurations can be provided to configure the listener including security and resiliency settings.
The configurations that can be passed here are defined in the `graphql:ListenerConfiguration` record.

```ballerina
import ballrina/graphql;

listener graphql:Listener graphqlListener = new (4000, timeout = 10, secureSocket = { key: { path: <KEYSTORE_PATH>, password: <PASSWORD>}});
```

### Service
The Ballerina GraphQL service represents the GraphQL schema. When a service is attached to a `graphql:Listener`, a GraphQL schema will be auto-generated. The resource functions inside the service represent the resolvers of the root type.
Then, the GraphQL listener will handle all the incoming requests and dispatch them to the relevant resource function.

Since the GraphQL endpoints are exposed through a single endpoint, the endpoint URL of the GraphQL service can be provided after the service declaration, as shown in the following code snippet, where the endpoint URL is `/graphql`.

The accessor of the resource function should always be `get`. The resource function name will become the name of the particular field in the GraphQL schema. The return type of the resource function will be the type of the corresponding field.

```ballerina
import ballerina/graphql;

service graphql:Service /graphql on new graphql:Listener(4000) {
    resource function get greeting(string name) returns string {
        return "Hello, " + name;
    }
}
```

The above can be queried using the GraphQL document below:

```
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


#### Additional Configurations
Additional configurations to a Ballerina GraphQL service can be provided using the `graphql:ServiceConfiguration`.
These configurations include security-related configurations for the GraphQL service.

##### Security Configurations
A GraphQL service
```ballerina
@ServiceConfiguration {
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

@graphql:ServiceConfiguration {
    maxQueryDepth: 2
}
service graphql:Service /graphql on new graphql:Listener(9090) {
    // Service definition
}
```

The above service only accepts queries of less than 2 levels. For an example, consider the following document:
```
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

### Types
The Ballerina GraphQL resources can return the following types:

#### Return Types

##### Scalar types
The following Ballerina types are considered as Scalar types:
- `int`
- `string`
- `boolean`
- `float`
- `decimal`
- `enum`

```ballerina
resource function get greeting() returns string {
    return "Hello, World";
}
```

This can be queried using the following document:
```
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

##### Record types

When a resource is returning a record type, each field of the record can be queried separately.
Each record type is mapped to a GraphQL `OBJECT` type, and the field of the record type are mapped to the fields of the `OBJECT` type.

```ballerina
public type Person record {|
    string name;
    int age;
|};

resource function get profile() returns Person {
    return { name: "Walter White", age: 51 };
}
```

This will generate the following schema
```
type Query {
    profile: Person!
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:
```
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
```
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

#### Service Objects
When a resource function returns a service object, the Service type is mapped to a GraphQL `OBJECT` type, and the resource functions of the service type will be mapped as the fields of the `OBJECT`.

When a service type is returned from a `graphql:Service`, the returning service type should also follow the rules of the `graphql:Service`, explained above.

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

```
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

Which will result in the following JSON:

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
A GraphQL resource can return an array of the types mentioned above.
When a resource is returning an array, the result will be a JSON array.

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

```
type Query {
    profile: [Person!]!
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:
```
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

Note that each element in the array consists only of the required `name` field.


#### Optional Types
A Ballerina GraphQL resource can return an optional type. When the return value is `()`, the resulting field in the JSON will be `null`.

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

```
type Query {
    profile: Person
}

type Person {
    name: String!
    age: Int!
}
```

This can be queried using the following document:
```
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
```
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

Since Ballerina supports the union types by nature, directly returning a union type is also allowed, but not recommended. The recommended way is to define a union type name separately and then use that type name, as shown in the following example. If a union type is returned directly without providing a type name, the type name will be `T1|T2|T3|...|Tn`.

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

```
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

```
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

```
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
A Ballerina GraphQL resource can return an `error` with the union of the types mentioned above.

Note: A resource cannot return `error` or any subtype of `error` alone or, `error?` which will results in a compilation error.

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
```
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
A resource inside a GraphQL service can have hierarchical paths.
When a hierarchical path is present, each level of the hierarchical path maps to the GraphQL field of the same name, and the type of that field will be mapped to an `OBJECT` type, with the same name.

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

Note the field name, and the type names are equal.
