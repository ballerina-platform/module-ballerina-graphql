// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

isolated function authorLoaderFunction(readonly & anydata[] ids) returns AuthorRow[]|error {
    readonly & int[] keys = check ids.ensureType();
    // Simulate query: SELECT * FROM authors WHERE id IN (...keys);
    lock {
        dispatchCountOfAuthorLoader += 1;
    }
    lock {
        readonly & int[] validKeys = keys.'filter(key => authorTable.hasKey(key)).cloneReadOnly();
        return keys.length() != validKeys.length() ? error("Invalid keys found for authors")
            : validKeys.'map(key => authorTable.get(key));
    }
};

isolated function bookLoaderFunction(readonly & anydata[] ids) returns BookRow[][]|error {
    final readonly & int[] keys = check ids.ensureType();
    // Simulate query: SELECT * FROM books WHERE author IN (...keys);
    lock {
        dispatchCountOfBookLoader += 1;
    }
    return keys.'map(isolated function(readonly & int key) returns BookRow[] {
        lock {
            return bookTable.'filter(book => book.author == key).toArray().clone();
        }
    });
};

isolated function authorUpdateLoaderFunction(readonly & anydata[] idNames) returns AuthorRow[]|error {
    readonly & [int, string][] idValuePair = check idNames.ensureType();
    // Simulate batch udpate
    lock {
        dispatchCountOfUpdateAuthorLoader += 1;
    }
    lock {
        foreach [int, string] [key, _] in idValuePair {
            if !authorTable.hasKey(key) {
                return error(string `Invalid key author key found: ${key}`);
            }
        }

        AuthorRow[] updatedAuthorRows = [];
        foreach [int, string] [key, name] in idValuePair {
            AuthorRow authorRow = {id: key, name};
            authorTable.put(authorRow);
            updatedAuthorRows.push(authorRow.clone());
        }
        return updatedAuthorRows.clone();
    }
};

isolated function faultyAuthorLoaderFunction(readonly & anydata[] ids) returns AuthorRow[]|error {
    readonly & int[] keys = check ids.ensureType();
    lock {
        readonly & int[] validKeys = keys.'filter(key => authorTable.hasKey(key)).cloneReadOnly();
        // This method may return an array of size not equal to the input array (ids) size.
        return validKeys.'map(key => authorTable.get(key));
    }
};

isolated function authorLoaderFunction2(readonly & anydata[] ids) returns AuthorRow[]|error {
    readonly & int[] keys = check ids.ensureType();
    // Simulate query: SELECT * FROM authors WHERE id IN (...keys);
    lock {
        dispatchCountOfAuthorLoader += 1;
    }
    lock {
        readonly & int[] validKeys = keys.'filter(key => authorTable2.hasKey(key)).cloneReadOnly();
        return keys.length() != validKeys.length() ? error("Invalid keys found for authors")
            : validKeys.'map(key => authorTable2.get(key));
    }
};

isolated function bookLoaderFunction2(readonly & anydata[] ids) returns BookRow[][]|error {
    final readonly & int[] keys = check ids.ensureType();
    // Simulate query: SELECT * FROM books WHERE author IN (...keys);
    lock {
        dispatchCountOfBookLoader += 1;
    }
    return keys.'map(isolated function(readonly & int key) returns BookRow[] {
        lock {
            return bookTable2.'filter(book => book.author == key).toArray().clone();
        }
    });
};
