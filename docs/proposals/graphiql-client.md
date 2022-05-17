# Proposal: Integrate GraphiQL Client into GraphQL Package

_Owners_: @ThisaruGuruge @DimuthuMadushan     
_Reviewers_: @shafreenAnfar @ThisaruGuruge       
_Created_: 2022/03/03   
_Updated_: 2021/04/05     
_Issue_: [#1936](https://github.com/ballerina-platform/ballerina-standard-library/issues/1936)

## Summary
This proposal is to integrate GraphiQL into Ballerina GraphQL services on demand. GraphiQL is the official reference implementation of GraphQL Integrated Development Environment(IDE) that provides a graphical view and querying facility for the service.

## Goals
- Integrate GraphiQL into Ballerina GraphQL Services.
- Provide an easy way to test the Ballerina GraphQL APIs locally.

## Non-Goals
- Use a none CDN based approach for the GraphiQL client implementation.

## Motivation

GraphQL has several tools that can be integrated into a GraphQL library. To give a better development experience for the GraphQL users, most of the GraphQL libraries integrate GraphiQL which is a very popular tool among the GraphQL community. GraphiQL provides a graphical user interface to execute the GraphQL queries. Users will be able to use any kind of complex GraphQL queries with GraphiQL. This can be used for testing purposes and to learn and understand the GraphQL query language as well. GraphiQL displays the schema of the service in Schema Definition Language(SDL) which is an important feature, especially for code first approach libraries like Ballerina GraphQL. Also, this can be used as a debugging tool for GraphQL APIs.

## Description

GraphQL Foundation provides multiple ways to implement a GraphiQL client. This proposal proposes to include the GraphiQL client as a single-page web application served from the Ballerina server using the existing CDN assets. An example implementation of the web app can be found in GraphiQL [examples](https://github.com/graphql/graphiql/tree/main/examples/graphiql-cdn). The web app can be saved as a single HTML file inside the Ballerina GraphQL package. Developers can enable/disable the GraphiQL client and configure the path where the GraphiQL is served.

### GraphiQL Configurations
Even though GraphiQL is an essential tool, it will be disabled in the production level APIs due to security concerns. Hence, the GraphQL service accepts a separate set of configurations for the GraphiQL client. With these configurations, the user will be able to enable the client easily. Configurations can be sent via Ballerina GraphQL [service configuration](https://github.com/ballerina-platform/module-ballerina-graphql/blob/master/docs/spec/spec.md#81-service-configuration). It has a separate optional field for GraphiQL configurations. It accepts a record as the input and it consists of a mandatory field and an optional field. 

```ballerina
type graphiql record {
    boolean enable = false;
    string path = "/graphiql";
};
```
In this GraphiQL configuration record, the field `enable` accepts a boolean that denotes whether the client is enabled or not. By default, it has been set to `false`. The optional field `path` accepts a valid string path for the GraphiQL service. The path can be any valid string. If the path is not provided in the configuration, the `/graphiql` is set as the default path. If the GraphiQL client is configured to the same path as the GraphQL path, an error will be thrown.
If the configurations are provided correctly, the web app will be served at the given path when the service is started. The developer will be able to accessed the web application via a web browser.
