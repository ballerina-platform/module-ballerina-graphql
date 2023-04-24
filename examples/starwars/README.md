# Starwars GraphQL API

[![Star on Github](https://img.shields.io/badge/-Star%20on%20Github-blue?style=social&logo=github)](https://github.com/ballerina-platform/module-ballerina-graphql)

_Authors_: @DimuthuMadushan  
_Reviewers_: @shafreenAnfar @ThisaruGuruge  
_Created_: 2021/02/07  
_Updated_: 2023/03/21

## Overview
 
This is an implementation of `Starwars` example in Ballerina. The `Starwars` schema and resolvers are based on popular Star Wars characters. This sample implementation can be used to learn the Ballerina GraphQL package functionalities.

In this implementation, it supports both query and mutation operations. Subscriptions are not included in this exaple due to the limitation coming from the Ballerina GraphQL package. Support for Subscriptions are planned in near future releases.
 
## Implementation
 
Implementation is purely done using the Ballerina GraphQL package. In order to maintain the simplicity a simple in memory datasource is created using Ballerina tables.
 
Also this implementation extensively uses the Ballerina Query feature. A SQL like query language which radically simplifies the implementation of the service.
 
## Starting the Service
 
To start the service, move into the starwars folder and execute the below command.
 
```shell
bal run
```
 
It will build the starwars Ballerina project and then run it.

**Example Query**
 
```graphql
query {
    hero(episode: EMPIRE) {
        ...on Human {
            name
            homePlanet
            friends {
                ...on Droid {
                    name
                    primaryFunction
                }
            }
        }
    }
}
```
