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

import ballerina/graphql;
import book_reviews_subscription.datasource as ds;
import xlibb/pubsub;

service /graphql on new graphql:Listener(9000) {
    private final pubsub:PubSub pubsub;

    function init() {
        self.pubsub = new;
    }

    # A simple resource that returns a welcome message
    # + return - greeting message
    isolated resource function get geeting() returns string {
        return "Welcome to Book Review Service";
    }

    # Add review to a book
    # + input - represents a review input
    # + return - the newly added Review
    isolated remote function addReview(ReviewInput input) returns Review|error {
        ds:ReviewRow reviewRow = check ds:addReview(input);
        check self.pubsub.publish("Reviews", reviewRow, timeout = -1);
        return new (reviewRow);
    }

    # Get real time reviews for a book
    # + return - review stream in real time
    isolated resource function subscribe review(string bookId) returns stream<Review, error?>|error {
        stream<ds:ReviewRow, error?> reviewStream = check self.pubsub.subscribe("Reviews", timeout = -1);
        return reviewStream.filter(review => review.bookId == bookId).'map(review => new Review(review));
    }
}

# Represents a book review input
public type ReviewInput readonly & record {|
    *ds:ReviewData;
|};
