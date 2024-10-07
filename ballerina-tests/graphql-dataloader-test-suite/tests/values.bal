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

const AUTHOR_LOADER = "authorLoader";
const AUTHOR_UPDATE_LOADER = "authorUpdateLoader";
const BOOK_LOADER = "bookLoader";

const AUTHOR_LOADER_2 = "authorLoader2";
const BOOK_LOADER_2 = "bookLoader2";

final isolated table<AuthorRow> key(id) authorTable = table [
    {id: 1, name: "Author 1"},
    {id: 2, name: "Author 2"},
    {id: 3, name: "Author 3"},
    {id: 4, name: "Author 4"},
    {id: 5, name: "Author 5"}
];

final isolated table<BookRow> key(id) bookTable = table [
    {id: 1, title: "Book 1", author: 1},
    {id: 2, title: "Book 2", author: 1},
    {id: 3, title: "Book 3", author: 1},
    {id: 4, title: "Book 4", author: 2},
    {id: 5, title: "Book 5", author: 2},
    {id: 6, title: "Book 6", author: 3},
    {id: 7, title: "Book 7", author: 3},
    {id: 8, title: "Book 8", author: 4},
    {id: 9, title: "Book 9", author: 5}
];

final isolated table<AuthorRow> key(id) authorTable2 = table [
    {id: 1, name: "Author 1"},
    {id: 2, name: "Author 2"},
    {id: 3, name: "Author 3"},
    {id: 4, name: "Author 4"},
    {id: 5, name: "Author 5"}
];

final isolated table<BookRow> key(id) bookTable2 = table [
    {id: 1, title: "Book 1", author: 1},
    {id: 2, title: "Book 2", author: 1},
    {id: 3, title: "Book 3", author: 1},
    {id: 4, title: "Book 4", author: 2},
    {id: 5, title: "Book 5", author: 2},
    {id: 6, title: "Book 6", author: 3},
    {id: 7, title: "Book 7", author: 3},
    {id: 8, title: "Book 8", author: 4},
    {id: 9, title: "Book 9", author: 5}
];
