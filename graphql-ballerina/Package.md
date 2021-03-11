# Package Overview

This package provides an implementation for connecting and interacting with GraphQL endpoints.

 
## Listener

The `graphql:Listener` is used to listen to a given port. Ballerina GraphQL is using HTTP as the underlying network protocol. To create a `graphql:Listener`, an `http:Listener` or a port number can be used.
 
Note: If the `graphql:Listener` is created using a port number, an `http:Listener` with the same port number should not be present.
 
### Create a `graphql:Listener` using an `http:Listener` 
```ballerina
import ballerina/http;
import ballerina/graphql;

http:Listener httpListener = check new(4000);
listener graphql:Listener graphqlListener = new(httpListener);
``` 

### Create a `graphql:Listener` using port number
```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = new(4000);
``` 
 
## Service
The Ballerina GraphQL service represents the GraphQL schema. When a service is attached to a `graphql:Listener`, a GraphQL schema will be auto-generated. The resource functions inside the service represent the resolvers of the root type.
Then, the GraphQL listener will handle all the incoming requests and dispatch them to the relevant resource function.

### Hello World

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

For more information, see the following.
* [Hello World Example](https://ballerina.io/learn/by-example/graphql-hello-world.html)
* [Returning Records from GraphQL services](https://ballerina.io/learn/by-example/graphql-resources-with-record-values.html)
* [Hierarchical Resource Paths Example](https://ballerina.io/learn/by-example/graphql-hierarchical-resource-paths.html)

### Return types
The Ballerina GraphQL resources can return the following types:

#### Scalar types 
The following Ballerina types are considered as Scalar types:
- `int`
- `string`
- `boolean`
- `float`
- `decimal`
     
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

#### Record types

When a resource is returning a record type, each field of the record can be queried separately.
  
```ballerina
public type Person record {|
    string name;
    int age;
|};

resource function get profile() returns Person {
    return { name: "Walter White", age: 51 };
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

#### Arrays
A GraphQL resource can return an array of the types mentioned above.
When a resource is returning an array, the result will return a JSON array.
  
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

Each element in the array consists only of the required `name` field.


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

#### Errors (With union)
A Ballerina GraphQL resource can return an `error` with the union of the types mentioned above.

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

### Additional Configurations
Additional configurations to a Ballerina GraphQL service can be provided using a service annotation (`graphql:ServiceConfiguration`).

#### Defining maximum query depth
When a maximum query depth is provided, all the queries exceeding that limit will be rejected at the validation phase and will not be executed.

```ballerina
import ballerina/graphql;

@graphql:ServiceConfiguration {
    maxQueryDepth: 2
}
service graphql:Service /graphql on new graphql:Listener(9090) {
    resource function get book(int id) returns Book {
        // Logic
    }
}
```

The above service only accepts queries of less than 2 levels. For an example, consider the following document:
```
{
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
            "message": "Query has depth of 5, which exceeds max depth of 2",
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
