# Proposal: GraphQL Field Interceptors

_Owners_: @DimuthuMadushan   
_Reviewers_: @shafreenAnfar @ThisaruGuruge @MohamedSabthar  
_Created_: 2022/10/19   
_Updated_: 2023/03/23   
_Issue_: [#2001](https://github.com/ballerina-platform/ballerina-standard-library/issues/2001)


## Summary
Introduce the GraphQL field Interceptors to further enhance the execution flow of the GraphQL services. The GraphQL field interceptors can execute custom code before and after a specific resolver function. This provides a more convenient way to handle the additional logic related to a GraphQL resolver function.

## Goals
* Introduce field interceptors    

## Non-Goals
* Add support field interceptor execution for a specific record field

## Motivation

Even though the Ballerina GraphQL package provides service interceptors, there are some use cases that need field interceptors. Due to the unavailability of field interceptor support, service interceptor logic becomes complex. In most use cases, only a few resource functions require the interceptors. In that case, if the user uses service interceptors, it needs some extra effort to filter out the resource function. With field interceptor support, the user is able to apply an interceptor function to a specific resource function in the GraphQL service.

## Description
In order to add the field interceptors, it needs to introduce a new GraphQLResourceConfig in the Ballerina GraphQL module. This resource config includes an array that accepts the interceptors. Therefore the field interceptors should be inserted at the ResourceConfig. This is the key difference between service and field interceptors. Other than that, there are no differences from service interceptors in terms of declaration or execution. Field interceptors also use the onion principle when executing. The insertion order of the interceptors into the array becomes the execution order. More information on the GraphQL interceptor can be found [here](https://github.com/ballerina-platform/module-ballerina-graphql/blob/master/docs/spec/spec.md#10-interceptors).

### GraphQL Resource Configurations
The resource config record can be declared in the following format. Since the GraphQL package has not introduced any resource config earlier, the record includes only the “interceptors” field. It can accept an array of interceptor instances.

```ballerina
public type GraphqlResourceConfig record {|
    readonly Interceptors|Interceptors[] interceptors = [];
|};
```

### Engaging the Field Interceptors
To insert the field interceptors, GraphQL resource configurations should be introduced as described in the GraphQL resource configurations section. Interceptors that need to be applied for a specific GraphQL revolver can be inserted using the resource configurations. It accepts a single interceptor instance or an array of interceptor instances and the execution order will be the array items order. Following is an example of field interceptor insertion.

```ballerina
@graphql:ResourceConfig {
    interceptors: [new SubscriptionInterceptor1(), new SubscriptionInterceptor2()]
}
isolated resource function get name() returns string {
}
```

### Execution
The field interceptor execution also follows the “onion principle”. When both service and field interceptors are present in a GraphQL service, its execution happens as follows.

`Service Interceptors` –> `Field interceptors` –> `Actual Resolver`

When there are multiple service interceptors and multiple field interceptors that are applied to a single resolver function, first it executes all the service interceptors and then starts the execution of field interceptors.

### Example
Consider the following program.
```ballerina
service class ServiceInterceptor {
    *graphql:Interceptor;
    isolated remote function execute(graphql:Context context, Field ‘field) returns anydata|error {
        log:printInfo(string `Service Interceptor execution!`);
        var output = ctx.resolve(’field);
        log:printInfo("Connection closed!");
        return output;
    }
}
 
service class Scope {
    *graphql:Interceptor;
    isolated remote function execute(graphql:Context context, Field ‘field) returns anydata|error {
        log:printInfo("Execution Scope: Admin");
        var output = ctx.resolve(‘field);
        log:printInfo("Leaving Admin Scope!");
        return output;
    }
}
 
@graphql:ServiceConfig {
    interceptors: new ServiceInterceptor()
}
service /graphql on new graphql:Listener(9000) {
 
    @graphql:ResourceConfig {
        interceptors: new Scope()
    }
    resource function get name(int id) returns string {
        log:printInfo("Resolver: name");
        return "Ballerina";
    }
}
```

In above sample included a service interceptor(ServiceInterceptor) and a field interceptor(Scope). It will start from the service interceptor and then go into deep one by one. Then the service prints the following log statements according to the execution order and the flow can be described as the diagram.
```shell
1. Service Interceptor execution!
2. Execution Scope: Admin
3. Resolver: name
4. Leaving Admin Scope!
5. Connection closed!
```
![interceptor_execution_new](https://user-images.githubusercontent.com/35717653/196609254-ee4b1265-230e-46fd-8c2e-53194822ee82.png)

When executing an interceptor function, first it will execute the logic before the `context.resolve()`. It will jump to the next interceptor from `context.resolve()` and If there are no interceptors, it will execute the actual resolver function in the GraphQL service. After completing the execution of the next series of interceptors it will come back to execute the logic after the `context.resolve()`.
