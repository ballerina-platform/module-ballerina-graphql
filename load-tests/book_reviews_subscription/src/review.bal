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

import book_reviews_subscription.datasource as ds;

# Represents a review of a book.
public isolated distinct service class Review {
    private final readonly & ds:ReviewRow reviewRow;

    isolated function init(ds:ReviewRow reviewRow) {
        self.reviewRow = reviewRow.cloneReadOnly();
    }

    # The unique identifier of the review
    # + return - The id of the review
    resource function get id() returns string {
        return self.reviewRow.id;
    }

    # The author of the review
    # + return - The author/reviewer
    resource function get author() returns string {
        return self.reviewRow.author;
    }

    # The review comment of the book
    # + return - The review comment
    resource function get comment() returns string {
        return self.reviewRow.comment;
    }

    # The book that is reviewed
    # + return - The book
    resource function get book() returns Book|error {
        ds:BookRow bookRow = check ds:getBookById(self.reviewRow.bookId);
        return new (bookRow);
    }
};
