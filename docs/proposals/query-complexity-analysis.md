# Proposal: GraphQL Query Complexity Analysis

_Owners_: @ThisaruGuruge \
_Reviewers_: @DimuthuMadushan @MohamedSabthar @shafreenAnfar \
_Created_: 2024/07/10 \
_Updated_: 2024/07/10 \
_Issue_: [#6722](https://github.com/ballerina-platform/ballerina-library/issues/6722)

## Summary

This proposal aims to introduce a Query Complexity Analysis feature to the Ballerina GraphQL module. This feature will evaluate the complexity of incoming GraphQL queries and help prevent performance and security issues caused by overly complex queries.

## Goals

- Provide a way to define the complexity of each GraphQL resolver field.
- Calculate the complexity of incoming queries based on defined metrics.
- Allow users to set complexity thresholds for queries.

## Non-Goals

- Analyzing field resolvers and calculating their complexity. (This should be done by the user.)
- Query optimization based on the complexity analysis. (This is out of scope for this feature.)

## Motivation

GraphQL allows users to query data in a flexible and efficient way. However, this flexibility can be abused by malicious users or result in performance issues due to overly complex queries resulting in Denial of Service (DoS) attacks or high server load. By introducing a complexity analysis feature, Ballerina can help users identify and prevent such issues. This will enhance the user experience and security of Ballerina applications that use GraphQL.

## Description

### Definition

The query complexity of a GraphQL operation can be calculated based on the complexity of its fields. The complexity of a field can be defined by the user based on the field’s type and the amount of data it retrieves. The complexity of a query is the sum of the complexities of its fields. Users can set a maximum complexity threshold for queries, and queries exceeding this threshold can be either rejected by throwing an error or logged as a warning as per the user’s configuration.

### Proposed Design

At the service level, the users can define the maximum query complexity allowed, the default complexity of a field, and whether to log a warning or throw an error when the complexity threshold is exceeded. These configurations are introduced as a separate field named `queryComplexityConfig` in the `graphql:ServiceConfig` annotation. The `QueryComplexityConfig` is an optional field, and each field inside the `QueryComplexityConfig` record is required, but has default values. Following is the definition of the `QueryComplexityConfig` record:

```ballerina
public type GraphqlServiceConfig record {|
    // ... existing fields
    QueryComplexityConfig queryComplexityConfig?;
|};

public type QueryComplexityConfig record {|
    int maxComplexity = 100;
    int defaultFieldComplexity = 1;
    boolean warnOnly = false;
|};
```

#### The `QueryComplexityConfig` Record

The `QueryComplexityConfig` record contains the following fields:

- `maxComplexity`: The maximum allowed complexity for a query. The default value is 100.
- `defaultFieldComplexity`: The default complexity value for a field. The default value is 1. This will be applied to each field on the query, unless a it is overridden by a custom complexity value on the field.
- `warnOnly`: A boolean value indicating whether to log a warning or throw an error when the complexity threshold is exceeded. The default value is `false`, which means an error will be thrown.

#### Field Complexity

A new field `complexity` will be introduced to the `graphql:ResourceConfig` annotation. This field allows users to define the complexity of a field. The `complexity` field is an optional field, and if not provided, the default complexity value defined in the `QueryComplexityConfig` will be used. Following is the updated definition of the `GraphqlResourceConfig` record:

```ballerina
public type GraphqlResourceConfig record {|
    // ... existing fields
    int complexity?;
|};
```

#### Record Field Complexity

This proposal does not intend to introduce custom complexity values for record fields. The record field complexity will be default complexity value defined in the `QueryComplexityConfig`. This is because the complexity of a record field is directly related to the complexity of the record itself. This can be revisited in future enhancements, if necessary.

### Complexity Calculation

When the GraphQL schema is created from the Ballerina service, the complexity of each field will be added to the generated schema.

> **Note:** This information is not visible via the introspection since GraphQL does not allow showing the applies directives via introspection. There is an ongoing efforts in GraphQL spec to allow metadata retrieval via introspection. Once that is available, we can expose the complexity information via introspection.

When calculating the complexity of a query, only the operation intended to execute will be considered. All the other operations will be ignored. The complexity will be accumulated per each field and the final complexity will be the sum of all the field complexities.

> **Note:** When an array is returned from a resolver (`resource` or `remote` method), the complexity is not multiplied by the number of elements, since the number of elements cannot be calculated before the execution. This aspect should be considered when assigning complexity values to a particular field.

### Query Complexity Threshold

After the query complexity is calculated for a particular operation, the GraphQL engine will check the complexity threshold defined in the `QueryComplexityConfig`. If the calculated complexity exceeds the threshold, either of the following two actions will be taken based on the `warnOnly` field:

1. When `warnOnly: false`
   An error will be thrown without executing the query. The corresponding HTTP status code will be 400. The error message will be in the following format:

    ```none
    The operation <Operation Name : Will be empty for anonymous query> exceeds the maximum query complexity threshold. Maximum allowed complexity: <Max Complexity>. Calculated query complexity: <Calculated Complexity>.
    ```

2. When `warnOnly: true`
   A warning will be logged without executing the query. The warning message will be in the following format:

    ```none
    The operation <Operation Name : Will be empty for anonymous query> exceeds the maximum query complexity threshold. Maximum allowed complexity: <Max Complexity>. Calculated query complexity: <Calculated Complexity>.
    ```

### Examples

Following is an example GraphQL service with query complexity analysis enabled:

```ballerina
import ballerina/graphql;

@graphql:ServiceConfig {
    queryComplexityConfig: {
        maxComplexity: 25,
        defaultFieldComplexity: 5
    }
}
service graphql:Service on new graphql:Listener(9090) {
    @graphql:ResourceConfig {
        complexity: 1 // Reduced complexity for the greeting field
    }
    resource function get greeting(string name) returns string {
        return string `Hello, ${name}!`;
    }

    @graphql:ResourceConfig {
        complexity: 10 // Increased complexity for fetching array of profiles
    }
    resource function get profiles(@graphql:ID int[] ids) returns Profile[] {
        // Some DB operation
    }

    @graphql:ResourceConfig {
        complexity: 8 // Increased complexity for the addProfile mutation
    }
    remote function addProfile(ProfileInput input) returns boolean {
        // Some DB operation
    }

    // Default complexity will be applied for this field
    resource function get profile(@graphql:ID int id) returns Profile {
        // Some DB operation
    }
}

public service class Profile {
    private final string name;
    private final int age;

    function init(string name, int age) {
        self.name = name;
        self.age = age;
    }

    @graphql:ResourceConfig {
        complexity: 2
    }
    resource function get name() returns string {
        return self.name;
    }

    @graphql:ResourceConfig {
        complexity: 2
    }
    resource function get age() returns int {
        return self.age;
    }

    @graphql:ResourceConfig {
        complexity: 10 // Increased complexity for the friends field
    }
    resource function get friends() returns Profile[] {
        // some DB operation
    }
}
```

Following are some example queries, their calculated complexities, and the expected responses:

1. Query with complexity below the threshold:

    - GraphQL Document:

        ```graphql
        query {
            greeting(name: "Alice")
        }
        ```

    - Calculated Complexity: 1

    - Expected Response:

        ```json
        {
            "data": {
                "greeting": "Hello, Alice!"
            }
        }
        ```

2. Query with complexity exceeding the threshold:

    - GraphQL Document:

        ```graphql
        query GetProfiles {
            profiles(ids: [1, 2, 3]) {
                name
                age
                friends {
                    name
                    age
                }
            }
        }
        ```

    - Calculated Complexity: 28

    - Expected Response:

        ```json
        {
            "errors": [
                {
                    "message": "The operation GetProfiles exceeds the maximum query complexity threshold. Maximum allowed complexity: 25. Calculated query complexity: 28."
                }
            ]
        }
        ```

3. Document with multiple operations:

    - GraphQL Document:

        ```graphql
        query GetProfiles {
            profiles(ids: [1, 2, 3]) {
                name
                age
                friends {
                    name
                    age
                }
            }
        }

        query GetGreeting {
            greeting(name: "Alice")
        }
        ```

      Execute the `GetGreeting` operation.

    - Calculated Complexity: 1

    - Expected Response:

        ```json
        {
            "data": {
                "greeting": "Hello, Alice!"
            }
        }
        ```

## Alternatives

### Bring all the Analysis into Single Configuration

In GraphQL there are some additional query analysis that can be done in parallel with the complexity analysis, such as `maxHeight`, `maxAliases`, and `maxRootFields`, in addition to the existing validation of `maxQueryDepth`. These can be combined into a single configuration, such as `QueryAnalysisConfig`. Following is an example of such a configuration:

```ballerina
public type GraphqlServiceConfig record {|
    // ... existing fields
    QueryAnalysisConfig queryAnalysisConfig?;
|};

public type QueryAnalysisConfig record {|
    ComplexityConfig complexityConfig?;
    DepthConfig depthConfig?;
    HeightConfig heightConfig?;
    AliasesConfig aliasesConfig?;
    RootFieldsConfig rootFieldsConfig?;
|};

public type ComplexityConfig record {|
    int maxComplexity = 100;
    int defaultFieldComplexity = 1;
    boolean warnOnly = false;
|};

public type DepthConfig record {|
    int maxDepth = 10;
    boolean warnOnly = false;
|};

public type HeightConfig record {|
    int maxHeight = 100;
    boolean warnOnly = false;
|};

public type AliasesConfig record {|
    int maxAliases = 10;
    boolean warnOnly = false;
|};

public type RootFieldsConfig record {|
    int maxRootFields = 10;
    boolean warnOnly = false;
|};
```

The `Height`, `Aliases`, and `RootFields` configurations are not considered in this proposal since they are not directly related to the complexity analysis. Comparatively, these configurations are less likely to be used by users. We can consider adding these configurations in future enhancements, if necessary.

Combining the `maxQueryDepth` and `queryComplexityConfig` is not considered in this proposal since it will be a breaking change.
