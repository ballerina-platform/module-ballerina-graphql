# Proposal: Write the Generated GraphQL Schema to a File

_Owners_: @ThisaruGuruge @DimuthuMadushan     
_Reviewers_: @shafreenAnfar @ThisaruGuruge         
_Created_: 2022/08/26     
_Updated_: 2021/10/07  
_Issue_: [#3205](https://github.com/ballerina-platform/ballerina-standard-library/issues/3205)

## Summary
The GraphQL module generates the schema for a given Ballerina GraphQL service at the compile time. Currently, the generated schema is not exposed to the outside. This proposal is to write the generated schema to a file in GraphQL Schema Definition Language(SDL) that the users can access.

## Goals
* Write the generated schema to a file in SDL

## Motivation

Since the Ballerina GraphQL module uses the code-first approach, users can not have the generated schema from the service in Schema Definition Language(SDL). The only way to check the schema is by enabling the GraphiQL client. Therefore, it’s essential to have a way to access the schema generated from the service. With this, the users will be able to access the schema and ensure the validity of the generated schema. Also, the file can be exported and used with any other GraphQL stuff since the schema is written in a language-agnostic way.

## Description

The GraphQL module generates the schema for a given GraphQL service at compile-time using the SchemaGenerator. In order to generate the schema in SDL, we might need to introduce `SdlFileGenerator` which uses the generated schema object as the input. The `SdlFileGenerator` can create the schema in SDL by iterating through the generated schema object.

### SDL File Generator

The SDL File Generator is a new component of the GraphQL compiler plugin. It accepts the generated schema object and writes the schema to a file in Schema Definition Language at the compile-time. The schema file is saved in the `./target` directory for the Ballerina projects. For a single `bal` file with a GraphQL service, the schema is created in the same directory where the `bal` command is executed. The file name will be in the following format with the `.graphql` file extension. An integer is appended to the file name to make the schema file name unique.

```
|--target
   |--schema_<integer>.graphql
```

When there is an error occurred during the SDL file generation, A warning message will be displayed in the console. Even though the schema generation failed, it will not affect the execution of the service.
