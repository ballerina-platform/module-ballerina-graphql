# Snowtooth: A Fake Ski Resort

[![Star on Github](https://img.shields.io/badge/-Star%20on%20Github-blue?style=social&logo=github)](https://github.com/ballerina-platform/module-ballerina-graphql)

_Authors_: @shafreenAnfar \
_Reviewers_: @ThisaruGuruge \
_Created_: 2021/07/11 \
_Updated_: 2022/09/16

# Overview

This is an implementation of the popular [snowtooth example](https://snowtooth.moonhighway.com/) in Ballerina. Snowtooth is a fake ski resort which includes a bunch of chairlifts and trails. A GraphQL API is built around this for a mobile application.

Unlike the original example this implementation only supports Query operations. This is a limitation coming from the Ballerina GraphQL package as it only supports query operations at the moment. Support for Mutations and Subscriptions are planned in near future releases.

# Implementation

Implementation is purely done using the Ballerina GraphQL package. In order to maintain the simplicity a simple in memory datasource is created using Ballerina tables.

Also this implementation extensively uses the Ballerina Query feature. A SQL like query language which radically simplifies the implementation of the service.

# Starting the Service

To start the service, move into the snowtooth folder and execute the below command.

```
$bal run
```

It will build the snowtooth Ballerina project and then run it.

# Querying the Service

Any GraphQL compliant tool can be used to query the service. Enter the URL `http://localhost:9000/graphql` to connect to the service. Then the service can be queried with any query compliant with the written GraphQL service.

**Example Query**

```graphql
{
  allLifts(status: OPEN) {
    name
    id
    trailAccess {
      name
      difficulty
    }
  }
}
```
