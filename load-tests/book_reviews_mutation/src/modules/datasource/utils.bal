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

isolated function getNextReviewId() returns string {
    lock {
        lastReviewId += 1;
        return lastReviewId.toString();
    }
}

public isolated function getReviewsByBookId(string bookId) returns ReviewRow[] {
    lock {
        return reviews.filter(row => row.bookId == bookId).clone().toArray();
    }
}

public isolated function addReview(readonly & ReviewData review) returns ReviewRow|error {
    if !books.hasKey(review.bookId) {
        return error(string `No books found with bookId: ${review.bookId}`);
    }
    lock {
        ReviewRow reviewRow = {id: getNextReviewId(), ...review};
        reviews.add(reviewRow);
        return reviewRow.cloneReadOnly();
    }
}

public isolated function getBookById(string id) returns BookRow|error {
    if (!books.hasKey(id)) {
        return error("Book not found for id: " + id);
    }
    return books.get(id);
}
