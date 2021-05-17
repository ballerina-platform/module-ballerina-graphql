// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
import ballerina/lang.array;
import snowtooth.datasource as ds;

type SearchResult Lift|Trail;

service /graphql on new graphql:Listener(9000) {

    # A list of all `Lift` objects
    # + return - the lifts
    resource function get allLifts(ds:Status? status) returns Lift[] {
        ds:LiftRecord[] lifts = from var lift in ds:liftTable where lift.status == status select lift;
        return lifts.map(function (ds:LiftRecord liftRecord) returns Lift => new Lift(liftRecord));  
    }

    # A list of all `Trail` objects
    # + return - the trails
    resource function get allTrails(ds:Status? status) returns Trail[] {
        ds:TrailRecord[] trails = from var trail in ds:trailTable where trail.status == status select trail;
        return trails.map(function (ds:TrailRecord trailRecord) returns Trail => new Trail(trailRecord));  
    }

    # Returns a `Lift` by `id` (id: "panorama")
    # + return - the lift
    resource function get Lift(string id) returns Lift? {
        ds:LiftRecord[] lifts = from var lift in ds:liftTable where lift.id == id select lift;
        if array:length(lifts) > 0 {
            return new Lift(lifts[0]);
        } else {
            return ();
        }
    }

    # Returns a `Trail` by `id` (id: "old-witch")
    # + return - the trail
    resource function get Trail(string id) returns Trail? {
        ds:TrailRecord[] trails = from var trail in ds:trailTable where trail.id == id select trail;
        if array:length(trails) > 0 {
            return new Trail(trails[0]);
        } else {
            return ();
        }
    }

    # Returns an `Int` of `Lift` objects with optional `LiftStatus` filter
    # + return - the liftcount
    resource function get liftCount(ds:Status status) returns int {
        ds:LiftRecord[] lifts = from var lift in ds:liftTable where lift.status == status select lift;
        return array:length(lifts);
    }

    # Returns an `Int` of `Trail` objects with optional `TrailStatus` filter
    # + return - the trailcount
    resource function get trailCount(ds:Status status) returns int {
        ds:TrailRecord[] trails = from var trail in ds:trailTable where trail.status == status select trail;
        return array:length(trails);
    }

    # Returns a list of `SearchResult` objects based on `term` or `status`
    # + return - the search result
    resource function get search (ds:Status status) returns SearchResult[] {
        ds:TrailRecord[] trails = from var trail in ds:trailTable where trail.status == status select trail;
        SearchResult[] searchResults = trails.map(function (ds:TrailRecord trail) returns Trail => new Trail(trail));

        ds:LiftRecord[] lifts = from var lift in ds:liftTable where lift.status == status select lift;
        lifts.forEach(function (ds:LiftRecord lift) returns () => searchResults.push(new Lift(lift)));

        return searchResults;
    }
}
