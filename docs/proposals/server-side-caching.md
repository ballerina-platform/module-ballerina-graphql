# Proposal: GraphQL Server-side Caching

_Owners_: @DimuthuMadushan  \
_Reviewers_: @shafreenAnfar @ThisaruGuruge  \
_Created_: 2024/02/01  \
_Updated_: 2024/02/01  \
_Issue_: [#3621](https://github.com/ballerina-platform/ballerina-library/issues/3621)

## Summary

This proposal is to introduce GraphQL server-side caching. The GraphQL server-side caching reduces the number of data fetches from the data source and leads to lower latency responses, which enhances the user experience.

## Goals

* Introduce GraphQL server-side in-memory caching

## Non-Goals

* Introduce GraphQL server-side distributed caching

## Motivation

When it comes to GraphQL services, the latency, number of requests to fetch the data, and scalability are major concerns. In some specific scenarios, achieving lower latency and reducing the number of data source requests is crucial. GraphQL server-side caching can be utilized as a solution to mitigate the impact of these factors. Server-side caching significantly reduces the frequency of data fetching requests, subsequently lowering latency, which enhances the user experience.

## Description

GraphQL server-side caching is a crucial feature that helps developers enhance the user experience. This proposal mainly focuses on server-side in-memory caching, which utilizes query operations. To enable more granular-level cache management, it introduces configuration capabilities at operation-level and field-level. The Ballerina cache module is used to handle the cache internally using a single cache table. The GraphQL package automatically generates cache keys based on resource paths and arguments for optimized caching. In specific scenarios, developers may need to remove particular cache entries based on specific operations. Hence, the proposal includes dedicated APIs within the GraphQL context object for efficient cache eviction.

### Cache Configurations

The cache configuration record includes the configuration that is essential to enabling GraphQL caching. The cache config record consists of three fields that have default values. The enabled field can be used to enable or disable the cache. The default value is set to true. The maxAge field can be used to indicate the TTL. By default, the maxAge is set to 60 seconds. The maxSize field indicates the maximum capacity of the cache table by entries. The default cache table size is 120 entries.

```ballerina
public type CacheConfig record {|
    boolean enabled = true;
    decimal maxAge = 60;
    int maxSize= 120;
|};
```

### Operation Level Cache

Operation level caching can be used to cache the entire operation. If the operation-level cache configuration is provided without any field-level cache configurations, all fields from the request will be cached according to the provided operation-level cache configurations. The operation-level cache can be enabled by providing the cache configurations via GraphQL ServiceConfig. It contains an optional field `cacheConfig` that accepts a cacheConfig record type value.

```ballerina
public type GraphqlServiceConfig record {|
    CacheConfig cacheConfig?;
|};
```

### Field Level Cache

The GraphQL server side caching can be enabled only for a specific field. This can be enabled by providing the cache configurations via ResourceConfig. The field-level cache configurations are identical to the service-level cache configurations, and it can override the operation-level configurations.

```ballerina
public type GraphqlResourceConfig record {|
    CacheConfig cacheConfig?;
|};
```

### Cache Key Generation

The cache key is generated using both the resource path and arguments. Argument values are converted into a Base64-encoded hash value, and the path is added as a prefix to the hashed arguments. In cases where there are no arguments, the cache key will be the path. The sub fields cache key is generated in the same way as described above. It includes all the argument values encountered within that path to generate the hash.

Ex:

```shell
profile.name.#[(id)]
profile.friends.#[(id),{...},[ids]]
```

### Cache Eviction

Cache eviction is crucial functionality in some cases. Hence, the dedicated APIs for cache eviction are included in GraphQL context objects. The developers can manually evict the cache using the API. If developers possess the exact path for a particular field that requires removal from the cache, they can provide the path as a string to the cache eviction function `evictCache`. This action will remove all cache entries associated with that specific path. Additionally, developers can clear the entire cache using the `invalidateAll`` API.

```ballerina
public isolated class Context {

    public isolated function evictCache(string path) returns error? {}

    public isolated function invalidateAll() returns error? {}
}
```

### Example

Consider the following GraphQL service that enables the field-level cache.

```ballerina
service /graphql on new graphql:Listener(9090) {

    @gaphql:ResourceConfig {
        cacheConfig: {
            maxSize: 30
        }
    }
    resource function get profile(int id) returns Person {
        return new;
    }
}

service class Person {
    resource function get name() returns string {
        return "X";
    }

    resource function get friends(int[] ids) returns string[] {
        return [“a”, “b”, “c”];
    }
}
```

For the query:

```graphql
query A {
    profile(id: 1) {
        name
        friends(ids: [1,4,5])
    }
}
```

It generates the following cache map.
| Key| Value|
|---|---|
| profile/name:#[1] |  "X"|
| profile/friends:#[1, [1, 4, 5]] |   [“a”, “b”, “c”]|

* If the user wishes to clear the cache entry related to the `name` field, the API call should be as follows. This action will specifically remove the entry associated with the name field.

```ballerina
context.evictCache(“profile.name”);
```

* If the developer intends to clear the cache associated with `profile`, the API call should follow this format. This action will remove all cache entries linked to profile, including its sub fields. In the provided example, executing this will clear the entire cache table, as all cache entries are connected to profile.

```ballerina
context.evictCache(“profile”);
```

* If the provided path does not match any existing cache entries, an error will be returned. Developers can handle this error. In such cases, developers have the option to either directly return an error or log a message, depending on the use case.
