# Proposal: Introduce GraphQL Interceptors

_Owners_: @ThisaruGuruge @DimuthuMadushan     
_Reviewers_: @shafreenAnfar @ThisaruGuruge       
_Created_: 2022/06/07   
_Updated_: 2021/07/18     
_Issue_: [#2001](https://github.com/ballerina-platform/ballerina-standard-library/issues/2001)


## Summary
Introduce the GraphQL Interceptors to enhance the execution flow of the GraphQL services. The GraphQL interceptors can execute custom code before and after the resolver function gets invoked which helps with common stuff like authentication, authorization, logging, observability, etc.

## Goals
* Introduce service level interceptors

## Non-Goals
* Add Interceptor support for subscriptions

## Motivation

Even though the Ballerina GraphQL package provides almost all the main features in GrpahQL spec, there are a few more additional features that need to be added to enhance the execution flow and usability. Due to the unavailability of these additional features, it’s difficult to perform some useful operations (Ex: Observability) with the existing capabilities of the GraphQL package. When it comes to popular GraphQL packages, they have introduced the [Middleware](https://github.com/maticzav/graphql-middleware#readme) concept which addresses the above difficulties. However, the Middleware concept is very much similar to the Interceptor concept in the Ballerina HTTP package. Adapting the Interceptor concept into the GraphQL package will resolve the aforementioned limitations. With the GraphQL Interceptors, It will be possible to implement the following functionalities easily.
* Authentication
* Authorization
* Observability
* Logging
* Input Sanitization
* Output Manipulation

In some GraphQL services, resolvers are getting cluttered with business logic which reduces code readability drastically. As an example, consider the Ballerina GraphQL services which use security stuff. The developer has to write the security logic inside the resolver along with the business logic. But the GraphQL interceptor provides a clear separation of concerns that improves the code modularity. At the same time, It eliminates the repetitive code from the resolvers and keeps the resolver clean and simple.

## Description

The Interceptor concept is much similar to the GraphQL middleware concept. The key attributes of interceptors are as follows.
* Can execute any code before/after invoking a Resolver function
* Can return errors
* Have access to the `graphql:Context` and the `graphql:RequestInfo`
* Can apply to multiple resolvers
* Can pass state from one interceptor to another

### Interceptor Service Object
The interceptor service object is the object that provides by the GrpahQL package. It includes a single remote function named `execute` that accepts `graphql:Context` and `graphql:Field` as the parameters. The function's return type is a union of `anydata` and `error`.

```ballerina
public type Interceptor distinct service object {
    isolated remote function execute(Context context, Field 'field) returns anydata|error;
};
```

### GraphQL Field Object
GraphQL interceptor execute function accepts the `Field` object as an input parameter that consists of APIs to access the execution field information. Following is the implementation of the Field object.

```ballerina
public class Field {
   public isolated function getName() returns string;
 
   public isolated function getAlias() returns string;
}
```
* The `getName()` function can be used to get the current execution field name.
* The `getAlias()` function returns aliases if the current execution filed has aliases. If not, it returns the name of the field.

Users will be able to access these APIs within the interceptor function.

### GraphQL Interceptor
Interceptors can be defined as a readonly service class that infers the Interceptor object provided by the GraphQL package. User-specific name can be used as the service class name. The Interceptor service class should have the implementation of the `execute()` remote function that infers from the interceptor service object. Apart from that, It can not have any other `resource/remote` methods inside the interceptor. However, the users are able to define the usual functions inside the interceptors. Code needed to be included in the interceptor should be kept inside the `execute()` function. To invoke the actual resolver function or the next interceptor the `context.resolve()` function can be called. When calling the `context.resolve()` function, the `graphql:Field` must be passed as the function argument. This will invoke the next interceptor if available. If not, it will call the actual resolver. Following is an example of a GraphQL interceptor.

```ballerina
readonly service class InterceptorName {
   *graphql:Interceptor;
 
   remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
       // Do some work
       var output = context.resolve('field);
       // Do some work
   }
}
```
Interceptors allow alternating the value returning from `context.resolve()` function. When alternating the return value, the new value should be either the same type value as the actual resolver return type or an error. Otherwise, it'll return an error.
(Ex: If the actual revolver returns a list, the interceptor should return a list. But the list elements can be different.)

### GraphQL Context
The following function will be added to the GraphQL [context](https://github.com/ballerina-platform/module-ballerina-graphql/blob/master/docs/spec/spec.md#8-context) in order to control the interceptor execution flow. It accepts the `graphql:Field` object as the argument. The resolver function returns an `anydata` that includes the result of the execution of the next interceptor function.

```ballerina
public isolated function resolve(graphql:Field ‘field) returns anydata;
```

### Engaging Interceptors
As mentioned in the goals, interceptors could be engaged at the service level and this proposal includes a simple way to engage the interceptors using annotations.

#### Service Level
If an interceptor needs to be applied to all the resolver functions, it should be engaged at the service level. Therefore, the service level interceptors can be inserted using GraphQL service configurations. It accepts an array of service-level interceptors. GraphQL service config records will be as follow with the `interceptors` field.

> NOTE: The inserting order of the interceptor function into the array, will be the execution order of Interceptors.

```ballerina
public type GraphqlServiceConfig record {|
   int maxQueryDepth?;
   ListenerAuthConfig[] auth?;
   ContextInit contextInit = initDefaultContext;
   CorsConfig cors?;
   Graphiql graphiql = {};
   readonly string schemaString = "";
   readonly readonly & Interceptors[] interceptors = [];
|};
```

The following is an example of inserting interceptors at the service level. The interceptor provided at the service level will be executed for any resolver invoked.

```ballerina
@graphql:ServiceConfig {
   interceptors: [new ResourceInterceptor()]
}
service /graphql on new graphql:Listener(9000) {
   // resolvers
}
```

### Execution
When it comes to interceptor execution, it follows the `onion principle`. Basically, Each interceptor function adds a layer before and after the actual resolver invocation. Therefore, the order of the interceptor array in the configuration will be important. In an Interceptor `execute()` function, all the code lines placed before the `context.resolve()`  will be executed before the resolver function execution, and the code lines placed after the `context.resolve()` will be executed after the resolver function execution.  Consider the following example.

#### Example:
```ballerina
readonly service class ServiceInterceptor {
  *graphql:Interceptor;
  isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
     log:printInfo(string `Service Interceptor execution!`);
     var output = check context.resolve();
     log:printInfo("Connection closed!");
     return output;
  }
}
 
readonly service class Scope {
  *graphql:Interceptor;
  isolated remote function execute(graphql:Context context, graphql:Field 'field) returns anydata|error {
     log:printInfo("Execution Scope: Admin");
     var output = check context.resolve();
     log:printInfo("Leaving Admin Scope!");
     return output;
  }
}
 
@graphql:ServiceConfig {
   interceptors: [new ServiceInterceptor(), new Scope()]
}
service /graphql on new graphql:Listener(9000) {

   resource function get name(int id) returns string {
      log:printInfo("Resolver: name");
      return "Ballerina";
   }
}
```

In above sample included two service level interceptors (ServiceInterceptor, Scope). It will start from the first service level interceptor and then go into deep one by one. Then the service prints the following log statements according to the execution order and the flow can be described as the diagram.

```shell
1. Service Interceptor execution!
2. Execution Scope: Admin
3. Resolver: name
4. Leaving Admin Scope!
5. Connection closed!
```

![interceptor_execution_new](https://user-images.githubusercontent.com/35717653/172832290-615bcd02-3fea-42ec-803e-32eaba74d8e0.png)

When executing an interceptor function, first it will execute the logic before the `context.resolve()`. It will jump to the next interceptor from `cantext.resolve()` and If there are not any interceptors, it will execute the actual resolver function in the GraphQL service. After completing the execution of the next series of interceptors it will come back to execute the logic after the `context.resolve()`.
