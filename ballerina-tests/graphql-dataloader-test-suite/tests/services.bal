// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/graphql;
import ballerina/graphql.dataloader;
import ballerina/http;

isolated function initContext(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
    graphql:Context ctx = new;
    ctx.registerDataLoader(AUTHOR_LOADER, new dataloader:DefaultDataLoader(authorLoaderFunction));
    ctx.registerDataLoader(AUTHOR_UPDATE_LOADER, new dataloader:DefaultDataLoader(authorUpdateLoaderFunction));
    ctx.registerDataLoader(BOOK_LOADER, new dataloader:DefaultDataLoader(bookLoaderFunction));
    return ctx;
}

@graphql:ServiceConfig {
    contextInit: initContext
}
service /dataloader on wrappedListener {
    function preAuthors(graphql:Context ctx, int[] ids) {
        addAuthorIdsToAuthorLoader(ctx, ids);
    }

    resource function get authors(graphql:Context ctx, int[] ids) returns AuthorData[]|error {
        dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER);
        AuthorRow[] authorRows = check trap ids.map(id => check authorLoader.get(id, AuthorRow));
        return from AuthorRow authorRow in authorRows
            select new (authorRow);
    }

    function preUpdateAuthorName(graphql:Context ctx, int id, string name) {
        [int, string] key = [id, name];
        dataloader:DataLoader authorUpdateLoader = ctx.getDataLoader(AUTHOR_UPDATE_LOADER);
        authorUpdateLoader.add(key);
    }

    remote function updateAuthorName(graphql:Context ctx, int id, string name) returns AuthorData|error {
        [int, string] key = [id, name];
        dataloader:DataLoader authorUpdateLoader = ctx.getDataLoader(AUTHOR_UPDATE_LOADER);
        AuthorRow authorRow = check authorUpdateLoader.get(key);
        return new (authorRow);
    }

    resource function subscribe authors() returns stream<AuthorData> {
        lock {
            readonly & AuthorRow[] authorRows = authorTable.toArray().cloneReadOnly();
            return authorRows.'map(authorRow => new AuthorData(authorRow)).toStream();
        }
    }
}

@graphql:ServiceConfig {
    interceptors: new AuthorInterceptor(),
    contextInit: initContext
}
service /dataloader_with_interceptor on wrappedListener {
    function preAuthors(graphql:Context ctx, int[] ids) {
        addAuthorIdsToAuthorLoader(ctx, ids);
    }

    resource function get authors(graphql:Context ctx, int[] ids) returns AuthorDetail[]|error {
        dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER);
        AuthorRow[] authorRows = check trap ids.map(id => check authorLoader.get(id, AuthorRow));
        return from AuthorRow authorRow in authorRows
            select new (authorRow);
    }
}

@graphql:ServiceConfig {
    interceptors: new AuthorInterceptor(),
    contextInit: isolated function(http:RequestContext requestContext, http:Request request) returns graphql:Context {
        graphql:Context ctx = new;
        ctx.registerDataLoader(AUTHOR_LOADER, new dataloader:DefaultDataLoader(faultyAuthorLoaderFunction));
        ctx.registerDataLoader(AUTHOR_UPDATE_LOADER, new dataloader:DefaultDataLoader(authorUpdateLoaderFunction));
        ctx.registerDataLoader(BOOK_LOADER, new dataloader:DefaultDataLoader(bookLoaderFunction));
        return ctx;
    }
}
service /dataloader_with_faulty_batch_function on wrappedListener {
    function preAuthors(graphql:Context ctx, int[] ids) {
        addAuthorIdsToAuthorLoader(ctx, ids);
    }

    resource function get authors(graphql:Context ctx, int[] ids) returns AuthorData[]|error {
        dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER);
        AuthorRow[] authorRows = check trap ids.map(id => check authorLoader.get(id, AuthorRow));
        return from AuthorRow authorRow in authorRows
            select new (authorRow);
    }
}

function addAuthorIdsToAuthorLoader(graphql:Context ctx, int[] ids) {
    dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER);
    ids.forEach(function(int id) {
        authorLoader.add(id);
    });
}

isolated function initContext2(http:RequestContext requestContext, http:Request request) returns graphql:Context|error {
    graphql:Context ctx = new;
    ctx.registerDataLoader(AUTHOR_LOADER_2, new dataloader:DefaultDataLoader(authorLoaderFunction2));
    ctx.registerDataLoader(BOOK_LOADER_2, new dataloader:DefaultDataLoader(bookLoaderFunction2));
    return ctx;
}

@graphql:ServiceConfig {
    contextInit: initContext2
}
service /caching_with_dataloader on wrappedListener {
    function preAuthors(graphql:Context ctx, int[] ids) {
        addAuthorIdsToAuthorLoader2(ctx, ids);
    }

    @graphql:ResourceConfig {
        cacheConfig: {
            enabled: true
        }
    }
    resource function get authors(graphql:Context ctx, int[] ids) returns AuthorData2[]|error {
        dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER_2);
        AuthorRow[] authorRows = check trap ids.map(id => check authorLoader.get(id, AuthorRow));
        return from AuthorRow authorRow in authorRows
            select new (authorRow);
    }

    isolated remote function updateAuthorName(graphql:Context ctx, int id, string name, boolean enableEvict = false) returns AuthorData2|error {
        if enableEvict {
            check ctx.invalidate("authors");
        }
        AuthorRow authorRow = {id: id, name};
        lock {
            authorTable2.put(authorRow.cloneReadOnly());
        }
        return new (authorRow);
    }
}

@graphql:ServiceConfig {
    cacheConfig: {
        enabled: true
    },
    contextInit: initContext2
}
service /caching_with_dataloader_operational on wrappedListener {
    function preAuthors(graphql:Context ctx, int[] ids) {
        addAuthorIdsToAuthorLoader2(ctx, ids);
    }

    resource function get authors(graphql:Context ctx, int[] ids) returns AuthorData2[]|error {
        dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER_2);
        AuthorRow[] authorRows = check trap ids.map(id => check authorLoader.get(id, AuthorRow));
        return from AuthorRow authorRow in authorRows
            select new (authorRow);
    }

    isolated remote function updateAuthorName(graphql:Context ctx, int id, string name, boolean enableEvict = false) returns AuthorData2|error {
        if enableEvict {
            check ctx.invalidate("authors");
        }
        AuthorRow authorRow = {id: id, name};
        lock {
            authorTable2.put(authorRow.cloneReadOnly());
        }
        return new (authorRow);
    }
}

function addAuthorIdsToAuthorLoader2(graphql:Context ctx, int[] ids) {
    dataloader:DataLoader authorLoader = ctx.getDataLoader(AUTHOR_LOADER_2);
    ids.forEach(function(int id) {
        authorLoader.add(id);
    });
}

