import ballerina/test;

@test:Config
isolated function testDispatch() returns error? {
    final DataLoader loader = new DefaultDataLoader(authorLoaderFunction);
    lock {
        readonly & int[] keys = [...authorTable.keys(), 1];
        keys.forEach(key => loader.add(key));
        loader.dispatch();
        foreach int key in keys {
            AuthorRow author = check loader.get(key);
            test:assertEquals(author, authorTable.get(key));
        }
    }
}

@test:Config
isolated function testDataBindingError() returns error? {
    final DataLoader loader = new DefaultDataLoader(authorLoaderFunction);
    loader.add(1);
    lock {
        loader.dispatch();
        int|error author = loader.get(1);
        test:assertTrue(author is error);
    }
}

@test:Config
isolated function testBatchLoadFunctionReturingError() returns error? {
    final DataLoader loader = new DefaultDataLoader(authorLoaderFunction);
    loader.add(10);
    lock {
        loader.dispatch();
        AuthorRow|error author = loader.get(10);
        test:assertTrue(author is error);
        if author is error {
            test:assertEquals(author.message(), "Invalid keys found for authors");
        }
    }
}

@test:Config
isolated function testClearAll() returns error? {
    final DataLoader loader = new DefaultDataLoader(authorLoaderFunction);
    lock {
        authorTable.keys().forEach(key => loader.add(key));
        loader.dispatch();
        loader.clearAll();
        foreach int key in authorTable.keys() {
            AuthorRow|error author = loader.get(key);
            test:assertTrue(author is error);
            if author is error {
                test:assertEquals(author.message(), string `No result found for the given key ${key}`);
            }
        }
    }
}

@test:Config
isolated function testDataLoaderHavingFaultyBatchLoadFunction() returns error? {
    final DataLoader loader = new DefaultDataLoader(faultyAuthorLoaderFunction);
    lock {
        authorTable.keys().forEach(key => loader.add(key));
        loader.dispatch();
        foreach int key in authorTable.keys() {
            AuthorRow|error author = loader.get(key);
            test:assertTrue(author is error);
            if author is error {
                test:assertEquals(author.message(), "The batch function should return a number of results equal to the number of keys");
            }
        }
    }
}

isolated function authorLoaderFunction(readonly & anydata[] ids) returns AuthorRow[]|error {
    readonly & int[] keys = check ids.ensureType();
    // Simulate query: SELECT * FROM authors WHERE id IN (...keys);
    lock {
        readonly & int[] validKeys = keys.'filter(key => authorTable.hasKey(key)).cloneReadOnly();
        return keys.length() != validKeys.length() ? error("Invalid keys found for authors")
            : validKeys.'map(key => authorTable.get(key));
    }
};

isolated function faultyAuthorLoaderFunction(readonly & anydata[] ids) returns AuthorRow[]|error {
    return [];
};
