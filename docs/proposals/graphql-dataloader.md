# Proposal: Introduce GraphQL Interceptors

_Owners_: @MohamedSabthar @ThisaruGuruge     
_Reviewers_: @shafreenAnfar @ThisaruGuruge       
_Created_: 2023/06/14
_Updated_: 2023/06/14
_Issue_: [#4569](https://github.com/ballerina-platform/ballerina-standard-library/issues/4569)

## Summary
DataLoader is a versatile tool used for accessing various remote data sources in GraphQL. Within the realm of GraphQL, DataLoader is extensively employed to address the N+1 problem. The aim of this proposal is to incorporate a DataLoader functionality into the Ballerina GraphQL package.

## Goals
- Implement DataLoader as a sub-module of the Ballerina GraphQL package.

## Motivation

### The N+1 problem
The N+1 problem can be exemplified in a scenario involving authors and their books. Imagine a book catalog application that displays a list of authors and their respective books. When encountering the N+1 problem, retrieving the list of authors requires an initial query to fetch author information (N), followed by separate queries for each author to retrieve their books (1 query per author).

This results in N+1 queries being executed, where N represents the number of authors, leading to increased overhead and potential performance issues. Following is a GraphQL book catalog application written in Ballerina which susceptible to N +1 problem

```ballerina
import ballerina/graphql;
import ballerina/sql;
import ballerina/io;
import ballerinax/java.jdbc;
import ballerinax/mysql.driver as _;

service on new graphql:Listener(9090) {
    resource function get authors() returns Author[]|error {
        var query = sql:queryConcat(`SELECT * FROM authors`);
        io:println(query);
        stream<AuthorRow, sql:Error?> authorStream = dbClient->query(query);
        return from AuthorRow authorRow in authorStream
            select new (authorRow);
    }
}

isolated distinct service class Author {
    private final readonly & AuthorRow author;

    isolated function init(AuthorRow author) {
        self.author = author.cloneReadOnly();
    }

    isolated resource function get name() returns string {
        return self.author.name;
    }

    isolated resource function get books() returns Book[]|error {
        int authorId = self.author.id;
        var query = sql:queryConcat(`SELECT * FROM books WHERE author = ${authorId}`);
        io:println(query);
        stream<BookRow, sql:Error?> bookStream = dbClient->query(query);
        return from BookRow bookRow in bookStream
            select new Book(bookRow);
    }
}

isolated distinct service class Book {
    private final readonly & BookRow book;

    isolated function init(BookRow book) {
        self.book = book.cloneReadOnly();
    }

    isolated resource function get id() returns int {
        return self.book.id;
    }

    isolated resource function get title() returns string {
        return self.book.title;
    }
}

final jdbc:Client dbClient = check new ("jdbc:mysql://localhost:3306/mydatabase", "root", "password");

public type AuthorRow record {
    int id;
    string name;
};

public type BookRow record {
    int id;
    string title;
};
```
Executing the query 
```graphql
{
  authors {
    name
    books {
      title
    }
  }
}
```
on the above service will print the following SQL queries in the terminal
```
SELECT * FROM authors
SELECT * FROM books WHERE author = 10
SELECT * FROM books WHERE author = 9
SELECT * FROM books WHERE author = 8
SELECT * FROM books WHERE author = 7
SELECT * FROM books WHERE author = 6
SELECT * FROM books WHERE author = 5
SELECT * FROM books WHERE author = 4
SELECT * FROM books WHERE author = 3
SELECT * FROM books WHERE author = 2
SELECT * FROM books WHERE author = 1
```
where the first query returns 10 authors then for each author a separate query is executed to obtain the book details resulting in a total of 11 queries which leads to inefficient database querying. The DataLoader allows us to overcome this problem.

### DataLoader
The DataLoader is the solution found by the original developers of the GraphQL spec. The primary purpose of DataLoader is to optimize data fetching and mitigate performance issues, especially the N+1 problem commonly encountered in GraphQL APIs. It achieves this by batching and caching data requests, reducing the number of queries sent to the underlying data sources. DataLoader helps minimize unnecessary overhead and improves the overall efficiency and response time of data retrieval operations.

## Success Metrics
In almost all GraphQL implementations, the DataLoader is a major requirement. Since the Ballerina GraphQL package is now spec-compliant, we are looking for ways to improve the user experience in the Ballerina GraphQL package. Implementing a DataLoader in Ballerina will improve the user experience drastically.


## Description
The DataLoader batches and caches operations for data fetchers from different data sources.The DataLoader requires users to provide a batch function that accepts an array of keys as input and retrieves the corresponding array of values for those keys.

### API
#### DataLoader object 
This object defines the public APIs accessible to users.
```ballerina
public type DataLoader isolated object {
   # Collects a key to perform a batch operation at a later time.
   pubic isolated function load(anydata key);

   # Retrieves the result for a particular key.
   public isolated function get(anydata key, typedesc<anydata> t = <>) returns t|error;

   # Executes the user-defined batch function.
   public isolated function dispatch();
};
```

#### DefaultDataLoader class
This class provides a default implementation for the DataLoader
```ballerina
isolated class DefaultDataLoader {
    *DataLoader;

    private final table<Key> key(key) keys = table [];
    private table<Result> key(key) resultTable = table [];
    private final (isolated function (readonly & anydata[] keys) returns anydata[]|error) batchLoadFunction;

    public isolated function init(isolated function (readonly & anydata[] keys) returns anydata[]|error batchLoadFunction) {
        self.batchLoadFunction = batchLoadFunction;
    }

    // … implementations of load, get and dispatch methods
}

type Result record {|
    readonly anydata key;
    anydata|error value; 
|};
```
The DefaultDataLoader class is an implementation of the DataLoader with the following characteristics:

- Inherits from DataLoader.
- Maintains a key table to collect keys for batch execution.
- Stores/caches results in a resultTable.
- Requires an isolated function `batchLoadFunction` to be provided during initialization.

##### `init` method

The `init` method instantiates the DefaultDataLoader and accepts a `batchLoadFunction` function pointer as a parameter. The `batchLoadFunction` function pointer has the following type:
```ballerina
isolated function (readonly & anydata[] keys) returns anydata[]|error
```
Users are expected to define the logic for the `batchLoadFunction`, which handles the batching of operations. The `batchLoadFunction` should return an array of anydata where each element corresponds to a key in the input `keys` array upon successful execution.

##### `load` method

The `load` method takes an `anydata` key parameter and adds it to the key table for batch execution. If a result is already cached for the given key in the result table, the key will not be added to the key table again.

##### `get` method

The `get` method takes an `anydata` key as a parameter and retrieves the associated value by looking up the result in the result table. If a result is found for the given key, this method attempts to perform data binding and returns the result. If a result cannot be found or data binding fails, an error is returned.

##### `dispatch` method

The `dispatch` method invokes the user-defined `batchLoadFunction`. It passes the collected keys as an input array to the `batchLoadFunction`, retrieves the result array, and stores the key-to-value mapping in the resultTable.

#### Requirements to Engaging DataLoader in GraphQL Module

To integrate the DataLoader with the GraphQL module, users need to follow these three steps:
1. Identify the resource method (GraphQL field) that requires the use of the DataLoader. Then, add a new parameter `map<dataloader:DataLoader>` to its parameter list.
2. Define a matching remote/resource method called loadXXX, where XXX represents the Pascal-cased name of the GraphQL field identified in the previous step. This method may include all/some of the required parameters from the graphql field and the `map<dataloader:DataLoader>` parameter. This function is executed as a prefetch step before executing the corresponding resource method of GraphQL field. (Note that both the loadXXX method and the XXX method should have same resource accessor or should be remote methods)
3. Annotate the loadXXX method written in step two with `@dataloader:Loader` annotation and pass the required configuration.  This annotation helps avoid adding loadXXX as a field in the GraphQL schema and also provides DataLoader configuration.

#### `Loader` annotation 
```ballerina
# Provides a set of configurations for the load resource method.
public type LoaderConfig record {|
      # Facilitates a connection between a data loader key and a batch function. 
      # The data loader key enables the reuse of the same data loader across resolvers
      map<isolated function (readonly & anydata[] keys) returns anydata[]|error> batchFunctions;
|};

# The annotation to configure the load resource method with a DataLoader
public annotation LoaderConfig Loader on object function;
```
The following section demonstrates the usage of DataLoader in Ballerina GraphQL.

##### Modifying the Book Catalog Application to Use DataLoader
In the previous Book Catalog Application example `SELECT * FROM books WHERE author = ${authorId}` was executed each time for N = 10 authors. To batch these database calls to a single request we need to use a DataLoader at the books field. The following code block demonstrates the changes made to the books field and Author service class.

```ballerina
import ballerina/graphql.dataloader;

isolated distinct service class Author {
    private final readonly & AuthorRow author;

    isolated function init(AuthorRow author) {
        self.author = author.cloneReadOnly();
    }

    isolated resource function get name() returns string {
        return self.author.name;
    }

       // 1. Add a map<dataloader:DataLoader> parameter to it’s parameter list
       isolated resource function get books(map<dataloader:DataLoader> loaders) returns Book[]|error {
        dataloader:DataLoader bookLoader = loaders.get("bookLoader");
        BookRow[] bookrows = check bookLoader.get(self.author.id); // get the value from DataLoader for the key
        return from BookRow bookRow in bookrows
            select new Book(bookRow);
    }

    // 3. add dataloader:Loader annotation to the loadXXX method.
    @dataloader:Loader {
        batchFunctions: {"bookLoader": bookLoaderFunction}
    }
    // 2. create a loadXXX method
    isolated resource function get loadBooks(map<dataloader:DataLoader> loaders) {
        dataloader:DataLoader bookLoader = loaders.get("bookLoader");
        bookLoader.load(self.author.id); // pass the key so it can be collected and batched later
    }

}

// User written code to batch the books
isolated function bookLoaderFunction(readonly & anydata[] ids) returns BookRow[][]|error {
    readonly & int[] keys = <readonly & int[]>ids;
    var query = sql:queryConcat(`SELECT * FROM books WHERE author IN (`, sql:arrayFlattenQuery(keys), `)`);
    io:println(query);
    stream<BookRow, sql:Error?> bookStream = dbClient->query(query);
    map<BookRow[]> authorsBooks = {};
    checkpanic from BookRow bookRow in bookStream
        do {
            string key = bookRow.author.toString();
            if !authorsBooks.hasKey(key) {
                authorsBooks[key] = [];
            }
            authorsBooks.get(key).push(bookRow);
        };
    final readonly & map<BookRow[]> clonedMap = authorsBooks.cloneReadOnly();
    return keys.'map(key => clonedMap[key.toString()] ?: []);
};
```

executing the following query
```graphql
{
  authors {
    name
    books {
      title
    }
  }
```
after incorporating DataLoader will now include only two database queries.
```
SELECT * FROM authors
SELECT * FROM books WHERE author IN (1,2,3,4,5,6,7,8,9,10)
```

### Engaging DataLoader with GraphQL Engine 
At a high level the GraphQL Engine breaks the query into subproblems and then constructs the value for the query by solving the subproblems as shown in the below diagram. 
![image](https://github.com/ballerina-platform/ballerina-standard-library/assets/43032716/531bfb6b-4aab-4a44-aca9-4e4372be8cb7)
Following algorithm demonstrates how the GraphQL engine engages the DataLoader at a high level.
1. The GraphQL engine searches for the associated resource/remote function for each field in the query.
2. If a matching resource/remote function with the pattern `loadXXX` (where `XXX` is the field name) is found, the engine:
    - Creates a map of DataLoader instances using the provided batch loader functions in the `@dataloader:Loader` annotation.
    - Makes this map of DataLoader instances available for both the `XXX` and `loadXXX` functions.
    - Executes the `loadXXX` resource method and generates a placeholder value for that field.
3. If no matching `loadXXX` function is found, the engine executes the corresponding `XXX` resource function for that field.
4. After completing the above steps, the engine generates a partial value tree with placeholders.
5. The engine then executes the `dispatch()` function of all the created DataLoaders.
6. For each non-resolved field (placeholder) in the partial value tree:
    - Executes the corresponding resource function (`XXX`).
    - Obtains the resolved value and replaces the placeholder with the resolved value.
    - If the resolved value is still a non-resolved field (placeholder), the process repeats steps 1-7.
7. Finally, the fully constructed value tree is returned.

## Future Plans
The DataLoader object will be enhanced with the following public methods:

- loadMany: This method allows adding multiple keys to the key table for future data loading.
- getMany: Given an array of keys, this method retrieves the corresponding values from the DataLoader's result table, returning them as an array of anydata values or an error, if applicable. The return type is (anydata | error)[].
- clear: This method takes a key as a parameter and removes the corresponding result from the result table, effectively clearing the cached data for that key.
- clearAll: This method removes all cached results from the result table, providing a way to clear the entire cache in one operation.
- prime: This method takes a key and an anydata value as arguments and replaces or stores the key-value mapping in the result table. This allows preloading or priming specific data into the cache for efficient retrieval later.
These methods enhance the functionality of the DataLoader, providing more flexibility and control over data loading, caching, and result management.