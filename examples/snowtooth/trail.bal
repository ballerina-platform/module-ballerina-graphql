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

import snowtooth.datasource as ds;

# A `Trail` is a run at a ski resort
public distinct isolated service class Trail {

    private final readonly & ds:TrailRecord trail;

    isolated function init(ds:TrailRecord trail) {
        self.trail = trail.cloneReadOnly();
    }

    # A unique identifier for a `Trail` (id: 'hemmed-slacks')
    # + return - the id
    isolated resource function get id () returns string {
        return self.trail.id;
    }

    # The name of a `Trail`
    # + return - the name
    isolated resource function get name () returns string {
        return self.trail.name;
    }

    # The current status for a `Trail`: OPEN, CLOSED
    # + return - the status
    isolated resource function get status () returns string {
        return self.trail.status;
    }

    # The difficulty rating for a `Trail`
    # + return - the difficulty
    isolated resource function get difficulty () returns string? {
        return self.trail.difficulty;
    }

    # A boolean describing whether or not a `Trail` is groomed
    # + return - the boolean status
    isolated resource function get groomed () returns boolean {
        return self.trail.groomed;
    }

    # A boolean describing whether or not a `Trail` has trees
    # + return - the boolean status
    isolated resource function get trees () returns boolean {
        return self.trail.trees;
    }

    # A boolean describing whether or not a `Trail` is open for night skiing
    # + return - the boolean status
    isolated resource function get night () returns boolean {
        return self.trail.night;
    }

    # A list of Lifts that provide access to this `Trail`
    # + return - the lifts
    isolated resource function get accessByLifts () returns Lift[] {
        ds:TrailRecord[] trails = [self.trail];
        ds:EdgeRecord[] edges = from var edge in ds:edgeTable
                       join var trail in trails on edge.trailId equals trail.id
                       select edge;
        ds:LiftRecord[] lifts = from var lift in ds:liftTable
                      join var edge in edges on lift.id equals edge.liftId
                      select lift;
        return lifts.map(liftRecord => new Lift(liftRecord));
    }
}
