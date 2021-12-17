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
import snowtooth.datasource as ds;

type SearchResult Lift|Trail;

service /graphql on new graphql:Listener(9000) {

    # A list of all `Lift` objects
    # + return - the lifts
    resource function get allLifts(ds:LiftStatus? status) returns Lift[] {
        if status is ds:LiftStatus {
            return from ds:LiftRecord lift in ds:liftTable where lift.status == status select new(lift);
        } else {
            return from ds:LiftRecord lift in ds:liftTable select new(lift);
        }
    }

    # A list of all `Trail` objects
    # + return - the trails
    resource function get allTrails(ds:TrailStatus? status) returns Trail[] {
        if status is ds:TrailStatus {
            return from ds:TrailRecord trail in ds:trailTable where trail.status == status select new(trail);
        } else {
            return from ds:TrailRecord trail in ds:trailTable select new(trail);
        }
    }

    # Returns a `Lift` by `id` (id: "panorama")
    # + return - the lift
    resource function get Lift(string id) returns Lift? {
        ds:LiftRecord[] lifts = from ds:LiftRecord lift in ds:liftTable where lift.id == id select lift;
        if lifts.length() == 1 {
            return new Lift(lifts[0]);
        }
        return;
    }

    # Returns a `Trail` by `id` (id: "old-witch")
    # + return - the trail
    resource function get Trail(string id) returns Trail? {
        ds:TrailRecord[] trails = from ds:TrailRecord trail in ds:trailTable where trail.id == id select trail;
        if trails.length() == 1 {
            return new Trail(trails[0]);
        }
        return;
    }

    # Returns an `Int` of `Lift` objects with optional `LiftStatus` filter
    # + return - the liftcount
    resource function get liftCount(ds:LiftStatus status) returns int {
        ds:LiftRecord[] lifts = from var lift in ds:liftTable where lift.status == status select lift;
        return lifts.length();
    }

    # Returns an `Int` of `Trail` objects with optional `TrailStatus` filter
    # + return - the trailcount
    resource function get trailCount(ds:TrailStatus status) returns int {
        ds:TrailRecord[] trails = from var trail in ds:trailTable where trail.status == status select trail;
        return trails.length();
    }

    # Returns a list of `SearchResult` objects based on `term` or `status`
    # + return - the search result
    resource function get search(ds:LiftStatus status) returns SearchResult[] {
        Trail[] trails = from var trail in ds:trailTable where trail.status == status select new(trail);
        Lift[] lifts = from var lift in ds:liftTable where lift.status == status select new(lift);

        SearchResult[] searchResults = [];
        foreach Trail trail in trails {
            searchResults.push(trail);
        }
        foreach Lift lift in lifts {
            searchResults.push(lift);
        }
        return searchResults;
    }

    remote function setLiftStatus(string id, ds:LiftStatus status) returns Lift|error? {
        ds:LiftRecord[] lifts = from ds:LiftRecord lift in ds:liftTable where lift.id == id select lift;
        if lifts.length() == 1 {
            ds:LiftRecord oldLift = lifts[0];
            ds:LiftRecord newLift = {
                id: oldLift.id,
                name: oldLift.name,
                status: status,
                capacity: oldLift.capacity,
                night: oldLift.night,
                elevationGain: oldLift.elevationGain
            };
            return new(newLift);
        }
        return;
    }

    remote function setTrailStatus(string id, ds:TrailStatus status) returns Trail|error? {
        ds:TrailRecord[] trails = from ds:TrailRecord trail in ds:trailTable where trail.id == id select trail;
        if trails.length() == 1 {
            ds:TrailRecord oldTrail = trails[0];
            ds:TrailRecord newTrail = {
                id: oldTrail.id,
                name: oldTrail.name,
                status: status,
                difficulty: oldTrail.difficulty,
                groomed: oldTrail.groomed,
                trees: oldTrail.trees,
                night: oldTrail.night
            };
            return new(newTrail);
        }
        return;
    }
}
