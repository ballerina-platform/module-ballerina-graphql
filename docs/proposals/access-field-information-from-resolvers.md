# Proposal: Access GraphQL Field Information from Resolvers

_Owners_: @ThisaruGuruge    
_Reviewers_: @shafreenAnfar @DimuthuMadushan @MohamedSabthar   
_Created_: 2023/01/03   
_Updated_: 2023/01/23   
_Issue_: [#3893](https://github.com/ballerina-platform/ballerina-standard-library/issues/3893)

## Summary
When a GraphQL field is processed, it is helpful to have additional information about the field such as the child fields. This proposal is to provide a way for the user to access the additional information using the `graphql:Field` object.

## Goals
* Provide a way to access field information within the resolver functions.

## Non-Goals
* Change the state of the field.

## Motivation
In GraphQL, the client requests the field they require, and the server is guaranteed to return only the fields the client requested. In most cases, this functionality is used to optimize the backend database queries so that the database is accessed to retrieve the values requested by the client. In Ballerina, currently, this optimization is not possible because the developer does not have access to this information. This proposal is to provide a way for the developer to access this information so that they can optimize their database queries and execution plans.

## Description

### The `graphql:Field` Object
Currently, the Ballerina GraphQL package has a `graphql:Field` object, which exposes the field name and the alias (if there's any). The `graphql:Field` object has the following APIs:

- `getName()`
  This API returns the name of the field as defined in the GraphQL document.
- `getAlias()`
  This API returns the effective alias of the field. This means if the document has an alias defined for the field, this will return the alias. Otherwise, it will return the field name.

In addition to these existing APIs, the following APIs are proposed to introduce.

- `getSubfieldNames()`
  This API returns `string[]` that contains the names of the child fields of the current field. This will include the subfields of the field if the field is a GraphQL `OBJECT` type. Otherwise, it will return an empty array. The resulting array includes the subfields including the fragment fields if there are any. Following is the definition of the method:
    ```ballerina
    isolated function getSubfieldNames() returns string[];
    ```
- `getPath()`
  This API returns the current path of the field from the root operation. If the field is a part of an array, the array index is also included. Following is the definition of the method:
    ```ballerina
    isolated function getPath() returns (int|string)[];
    ```
- `getType()`
  This API returns a `graphql:__Type` record that contains the type information of the field. Following is the definition of the method:
    ```ballerina
    isolated function getType() returns __Type;
    ```
  > **Note:** This will expose the currently package private record types to public that are being used to store schema information, such as `__Type`, `__Field`, `__TypeKind`, etc. These types should be changed to intersection types with `readonly` & `record`, so the users cannot mutate the state of the schema.

>**Note:** The `graphql:__Field` record should not be confused with the `graphql:Field` object. The `graphql:__Field` represents a field in the GraphQL schema whereas the `graphql:Field` object represents a field in a GraphQL document.

### Accessing the Field Object

Accessing the `graphql:Field` is currently supported in interceptors, using the `execute` method. But for most use cases, the `Field` object should be accessed, even without an interceptor. Therefore, this proposal proposes to add the `graphql:Field` object as an input parameter for the `resource` or `remote` methods that represents a GraphQL field. This is similar to [how the context is accessed](https://ballerina.io/spec/graphql/#84-accessing-the-context).

With this proposal, we are removing the limitations for the `graphql:Context` and `graphql:Field` parameter definition rules in the `resource` and `remote` methods inside the Ballerina GraphQL services. This means, we no longer validate the parameter position of the `graphql:Context` or the `graphql:Field` object in a `resource` or a `remote` method. They can be defined anywhere in the parameter list. But it is recommended to use them as the first and the second parameter in a function for better readability in the code.

###### Example: Accessing the Field Object

```ballerina
import ballerina/graphql;

service on new graphql:Listener(9090) {
    // A resource method that accesses the `graphql:Context` and the `graphql:Field` 
    // objects, along with another input parameter.
    resource function get greetingWithContext(graphql:Context context, graphql:Field 'field, string name)
    returns string {
        // ...
    }

    // A resource method that accesses the `graphql:Field` object,
    // along with another input parameter.
    resource function get greetingWihoutContext(graphql:Field 'field, string name) returns string {
        // ...
    }
}
```

###### Counter Example: Field Defined in Invalid Locations

```ballerina
import ballerina/graphql;

service on new graphql:Listener(9090) {
    // If the `graphql:Context` is present, it must be the first parameter. 
    // This will result is a compilation error.
    resource function get greetingWithContext(graphql:Field 'field, graphql:Context context, string name) 
    returns string {
        // ...
    }

    // If the `graphql:Context` is not present and the `graphql:Field` is present, 
    // the `graphql:Field` must be the first parameter. This will result in a compilation error.
    resource function get greetingWihoutContext(string name, graphql:Field 'field) returns string {
        // ...
    }
}
```

## Alternatives

Instead of adding the `graphql:FIeld` as an input parameter in a `resource` or a `remote` method, an alternative approach would be to add the `graphql:Field` to the `graphql:Context` object, and introduce an API, `getField()` in the `graphql:Context` object. This approach was considered first, but it has a couple of drawbacks.
- This might affect the parallel execution of the fields since the context has to be updated each time a field is executed. (This is not an issue as per now, as we are executing the fields serially now since the execution logic migration to Ballerina)
- The DX is a little bit more complex compared with the proposed approach as the users has to define the `graphql:Context` object whenever they need to access the `graphql:Field`, even though the `graphql:Context` might not needed.
- Tightly-coupling the `graphql:Context` and the `graphql:Field` does not seem a good idea as they are designated for two different things:
    - `graphql:Context` is to transfer/access meta-information per-request.
    - `graphql:Field` is to access meta-information per-field.

Due to the above reasons, this proposal is going forward with the approach mentioned in the above **Accessing the Field Object** section.
