Ballerina GraphQL Library
===================

  [![Build](https://github.com/ballerina-platform/module-ballerina-graphql/workflows/Build/badge.svg)](https://github.com/ballerina-platform/module-ballerina-graphql/actions?query=workflow%3ABuild)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-graphql.svg)](https://github.com/ballerina-platform/module-ballerina-graphql/commits/master)
  [![Github issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/graphql.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Fgraphql)
  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-graphql/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-graphql)
The GraphQL package is one of the standard library packages of the <a target="_blank" href="https://ballerina.io/">Ballerina</a> language.

This package provides an implementation for connecting and interacting with GraphQL endpoints over the network.

For more information, go to [The GraphQL Module](https://ballerina.io/learn/api-docs/ballerina/graphql/index.html).

For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).

   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
   * [OpenJDK](https://adoptopenjdk.net/)
   
        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Generate a Github access token with read package permissions, then set the following `env` variables:
    ```
   export packageUser=<Your GitHub Username>
   export packagePAT=<GitHub Personal Access Token>
    ```

### Building the Source

Execute the commands below to build from the source.

1. To build the package:
   ```    
   ./gradlew clean build
   ```

2. To run the tests:
   ```
   ./gradlew clean test
   ```
   
3. To run a group of tests
   ```
   ./gradlew clean test -Pgroups=<test_group_names>
   ```
   
4. To build the without the tests:
   ```
   ./gradlew clean build -x test
   ```
   
5. To debug package implementation:
   ```
   ./gradlew clean build -Pdebug=<port>
   ```
   
6. To debug with Ballerina language:
   ```
   ./gradlew clean build -PbalJavaDebug=<port>
   ```
   
## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss the code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
