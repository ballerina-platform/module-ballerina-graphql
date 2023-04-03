// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

final readonly & table<BookRow> key(id) books = table [
    {id: "1", title: "The Alchemist", author: "Paulo Coelho"},
    {id: "2", title: "The Lord of the Rings", author: "J.R.R. Tolkien"}
];

isolated final table<ReviewRow> key(id) reviews = table [
    {id: "01edc8a2-be38-1bd6-9234-6f5c8109f616", author: "John", comment: "Good", bookId: "1"},
    {id: "01edc8a2-c729-18ee-8479-87e51fdf9389", author: "Peter", comment: "Excellent", bookId: "1"},
    {id: "01edc8a2-cbee-1428-9740-220e68a4dbb6", author: "John", comment: "Good", bookId: "2"},
    {id: "01edc8a2-d0b2-1f68-8ed3-f5469c33a27d", author: "Peter", comment: "Excellent", bookId: "2"}
];
