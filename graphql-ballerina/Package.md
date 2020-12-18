# Package Overview

This module provides an implementation for connecting and interacting with GraphQL endpoints.

 
## Listener

The `graphql:Listener` is used to listen to a given port. Ballerina GraphQL is using HTTP as the underlying network protocol. To create a `graphql:Listener`, an `http:Listener` or a port number can be used.
 
 Note: If the `graphql:Listener` is created using a port number, an `http:Listener` with the same port number should not be present.
 
### Create a `graphql:Listener` using an `http:Listener` 
```ballerina
import ballerina/http;
import ballerina/graphql;

http:Listener httpListener = new(<port number>);
listener graphql:Listener graphqlListener = new(httpListener);
``` 

### Create a `graphql:Listener` using port number
```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = new(<port number>);
``` 
 
## Service

The `graphql:Service` represents a GraphQL endpoint. Inside a `graphql:Service`, resource functions can be used to define graphql resolvers. The `graphql:Service` is attached to a `graphql:Listener`. Ballerina GraphQL package will then generate the schema and handle the incoming GraphQL requests. 

```ballerina
import ballerina/graphql;

listener graphql:Listener graphqlListener = new(<port number>);

graphql:Service graphql on graphqlListener {
    resource function name() returns string {
        return "James Moriarty";
    }

    resource function age() returns int {
        return 40;
    }
}
```

The above can be queried using the following document:

```
{
    name
    age
}
```
