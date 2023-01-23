# Proposal: Write GraphQL Schema to a File

_Owners_: @ThisaruGuruge @DimuthuMadushan     
_Reviewers_: @shafreenAnfar  
_Created_: 2023/01/13   
_Updated_: 2023/01/13   
_Issue_: [#3531](https://github.com/ballerina-platform/ballerina-standard-library/issues/3531)


## Summary
The Ballerina GraphQL package generates the schema for a given Ballerina GraphQL service at the compile time. Currently, the generated schema is exposed to the outside only via introspection. This proposal is to write the generated schema to a file in GraphQL Schema Definition Language(SDL) that the users can access.

## Goals
* Export the GraphQL schema files using a GraphQL CLI command.

## Motivation
Since the Ballerina GraphQL module uses the code-first approach, users can not have the generated schema from the service in Schema Definition Language(SDL). The only way to check the schema in SDL is by using a client tool (e.g., GraphQL Playground). Therefore, it’s essential to have a way to access the schema generated from the service. With this, the users will be able to access the schema and ensure the validity of the generated schema. Also, the file can be exported and used with any other GraphQL libraries without any issue since the schema is written in a language-agnostic way.

## Description
The SDL schema file generation can be done using the GraphQL CLI command. The GraphQL CLI tool gets the compilation of given GraphQL service to access the schema string. It extracts the annotated schema string from the syntax tree and deserializes it to the schema object. This schema object is used to generate the GraphQL SDL schema string using the `SdlSchemaStringGenerator` which is published in the GraphQL Commons package. The generated SDL schema string is written to a file and exported into the given path in the CLI command. When an error occurs during the SDL schema generation, a stderr message is logged in the console. The errors that don't have a specific location return (-1:-1,-1:-1) as the error location.

### SDL schema string generator
The SDL Schema String Generator is a new component added to the GraphQL Commons package. It accepts the generated schema object and creates the schema string in GraphQL Schema Definition Language.

### CLI command
The CLI command for the SDL file generation includes multiple parameters as follows.

```
$bal graphql [-i | --input] <graphql-service-file-path>
             [-o | --output] <output-location> 
             [-s | --service] <service-base-path>
```

#### 1. graphql-service-file-path

The `ballerina-service-file-path` parameter specifies the path of the ballerina service file (e.g., `graphql.bal`) and is mandatory. If there are multiple GraphQL services included in the `bal` file, the command generates the schema for each graphql service.

#### 2. output-location

The SDL schema file is exported into the location given as the `output-location` in the CLI command. This is an optional parameter. By default, the schema file is exported into the same directory where the `bal` command is executed.

#### 3. service-base-path

The `service-base-path` can be used to specify the absolute service path of the GraphQL service(e.g., `/gql`). Then the schema is generated only for the service that has the matching absolute path. If no matching service is found, an error is returned. This is an optional parameter as the `output-location`.

### Schema File

The schema file is written in GraphQL Schema Definition Language(SDL) with a name of the following format. The file extension is `.graphql`.

```
|--schema_<service-base-path>/<service-file-name>.<duplicate-count(optional)>.graphql
```
The `service-base-path` is a concatenation of base path segments by an underscore(e.g., “graphql_service”).  The `duplicate-count` is appended to the name in order to distinguish the schema file when having multiple services with the same base path in a given service file. It is an optional segment in the file name.

Also, if there is a duplicate schema file in the output directory, a response message is displayed in the console to get a user input. It asks whether to override the existing file or generate a new file. Based on the user input, It decides whether to override the file or create a new file. If the user doesn’t want to override it,  the `duplicate-count` is appended to the name of the newly generated schema file.
