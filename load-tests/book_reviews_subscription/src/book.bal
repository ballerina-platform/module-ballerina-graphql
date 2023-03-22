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

# Represents a book.
public isolated distinct service class Book {
    private final ds:BookRow bookRow;

    function init(ds:BookRow bookRow) {
        self.bookRow = bookRow;
    }

    # The unique identifier of the book
    # + return - the id
    resource function get id() returns string {
        return self.bookRow.id;
    }

    # The title of the book
    # + return - the title
    resource function get title() returns string {
        return self.bookRow.title;
    }

    # The author of the book
    # + return - the author
    resource function get author() returns string {
        return self.bookRow.author;
    }

    # The reviews of the book
    # + return - the reviews
    resource function get reviews() returns Review[] {
        ds:ReviewRow[] reviewRows = ds:getReviewsByBookId(self.bookRow.id);
        return from var reviewRow in reviewRows
            select new Review(reviewRow);
    }
};
