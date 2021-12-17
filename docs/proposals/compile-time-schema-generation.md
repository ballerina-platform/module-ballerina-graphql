# Proposal: Generate GraphQL Schema at the Compile-Time

_Owners_: @ThisaruGuruge @DimuthuMadushan     
_Reviewers_: @shafreenAnfar
_Created_: 2021/10/14   
_Updated_: 2021/12/17     
_Issue_: [#2047](https://github.com/ballerina-platform/ballerina-standard-library/issues/2047)

## Summary
Currently, the GraphQL schema for a given Ballerina GraphQL service is generated in the runtime, which has some limitations such as adding documentation. Since this missing information can be retrieved at the-compile time, this proposal suggests generating the schema at the compile-time.

## Goals
* Generate the schema at the compile-time by walking through the Ballerina GraphQL service
* Include documentation, deprecated information for the GraphQL fields

## Non-Goals
* Change the current structure of the generated schema

## Motivation
In the current Ballerina GraphQL package, there are some limitations in the runtime schema generation. The most notable limitations are:
* Cannot retrieve the documentation for the types and the fields
* Cannot define `deprecated` fields
* Cannot retrieve the default values for the arguments

Due to these limitations, the Ballerina GraphQL module is missing some key features. To overcome these issues, we propose to generate the GraphQL schema at the compile-time, where this missing information is available. 
This will slightly increase the server start time as well since the schema generation will be moved out from the service attach method.

## Description
The existing GraphQL compiler plugin will be used to generate the schema as well, although we might introduce a new `ServiceAnalyzer` to decouple service validation and the schema generation.
The service identification and type identification will be similar to the existing compiler plugin. Both the SyntaxAPI and the SemanticAPI will be used to read the documentation and other information. Default values are also read in the compile-time since only constant values are allowed as the default values. 

After generating the schema, it will be serialized as POJO and passed to the runtime as a resource of the Ballerina package. It will then be used to create the `__Schema` record. 

This can affect the current test structure as well since the new schema generation will not be available at the `graphql` module build. Therefore, a new test approach should be introduced (probably with the language support for integration tests). The current test setup might be changed a little due to this. Most of the existing tests will end up being integration tests, and new unit tests have to be introduced in the `graphql` top-level module. Furthermore, modularizing the `graphql` module should be considered, by decoupling the Engine and the Listener. 

With these changes the high-level architecture of the module is as follows:
![GraphQL Module Architecture drawio](https://user-images.githubusercontent.com/40016057/146490845-e52cc510-45af-4190-9b77-a782f81f88b4.png)

There are 3 main parts in the GraphQL package.
* Compiler Plugin
* Listener
* Engine

### Compiler Plugin
The compiler plugin has two submodules:
- Service Validator
- Schema Generator

The service validator will analyze the graphql services at the compile-time and validates them. This is currently implemented.
The schema generator will be the new addition, which will generate the schema for the given service. This generated schema will be serialized and saved as a resource in the Ballerina project so that the Ballerina GraphQL engine can deserialize and use it.

### Listener
The Listener has two submodules:
- HTTP Service
- HTTP Listener

Inside the Listener, there is an HTTP listener object and an HTTP service. When a GraphQL service is attached to the GraphQL listener, it will attach the HTTP service to the HTTP listener and start it. Then this HTTP listener will receive the requests and dispatch them to the HTTP service.
The HTTP service will then separate out the GraphQL document from the HTTP request and forwards it to the GraphQL engine.

### Engine
The GraphQL engine has three components.
- Parser
- Validator
- Executor

Although the parser is a part of the engine, it is separated out from the other components for modularity. 

## Dependencies
* Integration Tests support from the Language
* Adding resources to the package using the PackageAPI.
