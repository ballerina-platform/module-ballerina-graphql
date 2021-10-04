# Proposal: GraphQL Context

_Owners_: Thisaru, Dimuthu    
_Reviewers_: Shafreen, Chanaka      
_Created_: 2021/10/04   
_Updated_: 2021/10/04     
_Issue_: [#1906](https://github.com/ballerina-platform/ballerina-standard-library/issues/1906)

## Summary
Implement the context support for the Ballerina GraphQL package. The GraphQL context can be used to pass meta-information such as auth-related information to the GraphQL resolver (resource/remote) functions.

## Goals
* Provide a way to create a GraphQL context per each request nad to pass it into the resolver functions on demand.
* Provide a way to the users to define and control the context.

## Motivation
Although the GraphQL resolvers can have input arguments, they might need some more meta-information to work properly. This information can include authorization information such as usernames and scopes, and sometimes additional information that needs to be transferred between the resolvers.
Most of the GraphQL implementations, including the [reference implementation](https://github.com/graphql/graphql-js), have introduced a concept called GraphQL context to address this requirement. The context is accessible from all the resolvers, and the resolvers can modify the context as well. (Although destructive-modification is not recommended).
Developers can define what are the fields the context includes when defining the service. The Ballerina GraphQL module is expected to be supporting similar functionality.

## Description

### The `graphql:Context` Object
The `graphql:Context` will be defined as an isolated object in the Ballerina GraphLQ module. Following is the API of the `graphql:Context` object:

```ballerina
public isolated class Context {
    public isolated function add(string 'key, value:Cloneable|isolated object {} value) returns Error?;

    public isolated function get(string 'key) returns value:Cloneable|isolated object {}|Error

    public isolated function remove(string 'key) returns value:Cloneable|isolated object {}|Error
}
```

The fields of the `Context` objects can be either `value:Clonable` or an isolated object.

* The `add` function can be used to add a field to the context. It requires two arguments, the `key` and the `value`. Key must be a `string`. It will result in a `graphql:Error` if the provided key already exists in the context.

* The `get` function can be used to get a field value from the context. It requires one argument, the `key`, which is a `string`. If the provided key exists in the context, it will return the value, otherwise it will return a `graphql:Error`.

* The `remove` function can be used to remove a field from the context. It requires one argument, the `key`, which is a `string`. If the provided key exists in the context, it will remove and return the value, otherwise it will return a `graphql:Error`.


### Initializing the Context
Developers can write a function to initialize the context. Inside this function the developer have to initialize the `graphql:Context` object and add the necessary fields. The original `http:Request` and the `http:RequestContext` will be passed into this function, so that the developers can use those values to add fields to the context.

The function signature is as follows:

```ballerina
isolated function initContext(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
    graphql:Context context = new;
    check context.add("<key>", <value>);
    return context;
}
```

This function then can be passed as a field in the `graphql:ServiceConfig`. Then this function will run per each request and the context will be passed to the resolvers. Following is an example on how to pass the init function to the service:

```ballerina
@graphql:ServiceConfig {
    contextInit: initContext // Function pointer of the init function
}
service on new graphql:Listener(9000) {

}
```

### Using the Context in the Resolvers
The `graphql:Context` is available at any resolver function. To use the context, the resolver function has to have `graphql:Context` as the first parameter. Following is an example:

```ballerina
resource function get greeting(graphql:Context context) returns string|error {
    value:Cloneable|isolated object {} scope = check context.get("scope);
    if scope is string {
        if scope == "admin" {
            return "Hello, admin";
        } else if scope == "user" {
            return "Hello, user";
        } else {
            return error("Unauthorized");
        }
    }
    return error("Scope not found");
}
```

### Non-Destructive Modification
Even though the `graphql:Context` object have a `remove` method, it is not recommended to destructively-modify the context object. This is because the resource functions (query fields) are executed in parallel. Therefore, any modification done to the context can cause issues.

## Alternatives
Providing a context object with a pre-defined set of fields is also considered. This may cater the most of the use cases, since this object will include the `http:Request` object as well. But it is not scalable and not user-friendly.
