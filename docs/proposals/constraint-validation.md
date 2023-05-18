# Proposal: Add Constraint Validation Support

_Owners_: @DimuthuMadushan     
_Reviewers_: @shafreenAnfar @ThisaruGuruge  
_Created_: 2023/05/18   
_Updated_: 2023/05/18     
_Issue_: [#4176](https://github.com/ballerina-platform/ballerina-standard-library/issues/4176)

## Summary
The Ballerina `Constraint` package provides a convenient way to input validation. Since the GraphQL services have input validations, adding constraint validation support would increase the developer experience. This proposal will add the constraint package validation support to the Ballerina GraphQL module.

## Goals
- Add constraint validation support for GraphQL input types.

## Non-Goals
- Add constraint validation support for GraphQL output types.

## Motivation

As in most applications, input validation is a common part of a GraphQL service. Even though GraphQL validates the inputs provided by the user, in most cases, the developer needs to add constraints to the inputs as per the requirements of the business logic. Adding constraints to the inputs makes the resolver functions cluttered and increases the complexity of the business logic. But the Ballerina constraint package provides a convenient way to handle constraint validation. Therefore, integrating the constraint package validation support with GraphQL will make the business logic implementation easy and simple. It also isolates input constraint validation from the business logic.

## Description

User input validation is an essential task for any kind of application. Since GraphQL validates the inputs against the generated `__schema` record, additional effort is needed to integrate the constraint validation. The constraint package needs the input value and the input parameter typedesc. Therefore, it is essential to get access to the input value and input parameter typedesc in the validation phase. Apart from that, the developer will be able to configure the constraints validation. When it comes to GraphQL output values, the GraphQL developer has the authority to define them. Since there is no direct user involvement in defining the output values, the output constraint validation is not considered in this proposal.

### Constraints Validation Configuration
The developer should be able to enable or disable constraint validation according to their requirements. Hence, a new boolean field named `validation` is added to the GraphQL Service Config records to configure the constraint validation. If the `validation` is set to `true`, the constraint validation is carried out, and if it is set to `false`, the constraint validation is skipped. By default, the `validation` is set to `true`.

```ballerina
public type GraphqlServiceConfig record {|
   boolean validation = true
|};
```

### Argument Handler
The `ArgumentHandler` class that is being used to generate the argument from ArgumentNodes for the GraphQL resolvers can be used to validate the input type constraints. A new method is added to the ArgumentHandler class to validate the input constraints. To validate the constraints, the value and the typedesc of the parameter are needed. Since the ArgumentHandler includes these details, the native API of the constraint package can be used to validate the input constraints. If there are any constraint validation errors, they will be converted to a GraphQL-specific error and added to the GraphQL context. The following is a formatted error message for a constraint validation error.

Sample error message:
```shell
"Input validation failed in the field \"movie\": Validation failed for '$.downloads:minValue','$.imdb:minValue','$.name:maxLength' constraint(s).",
```
