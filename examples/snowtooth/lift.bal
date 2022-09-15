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

# A `Lift` is a chairlift, gondola, tram, funicular, pulley, rope tow, or other means of ascending a mountain.
public distinct isolated service class Lift {

    private final readonly & ds:LiftRecord lift;

    isolated function init(ds:LiftRecord lift) {
        self.lift = lift.cloneReadOnly();
    }

    # The unique identifier for a `Lift` (id: "panorama")
    # + return - the id
    isolated resource function get id () returns string {
        return self.lift.id;
    }

    # The name of a `Lift`
    # + return - the name
    isolated resource function get name () returns string {
        return self.lift.name;
    }

    # The current status for a `Lift`: `OPEN`, `CLOSED`, `HOLD`
    # + return - the status
    isolated resource function get status () returns string {
        return self.lift.status;
    }

    # The number of people that a `Lift` can hold
    # + return - the capcasity
    isolated resource function get capacity () returns int {
        return self.lift.capacity;
    }

    # A boolean describing whether a `Lift` is open for night skiing
    # + return - the boolean
    isolated resource function get night () returns boolean {
        return self.lift.night;
    }

    # The number of feet in elevation that a `Lift` ascends
    # + return - the elevationgain
    isolated resource function get elevationgain () returns int {
        return self.lift.elevationgain;
    }

    # A list of trails that this `Lift` serves
    # + return - the trails
    isolated resource function get trailAccess () returns Trail[] {
        ds:LiftRecord[] lifts = [self.lift];
        ds:EdgeRecord[] edges = from var edge in ds:edgeTable
                       join var lift in lifts on edge.liftId equals lift.id
                       select edge;
        ds:TrailRecord[] trails = from var trail in ds:trailTable
                      join var edge in edges on trail.id equals edge.trailId
                      select trail;
        return trails.map(trailRecord => new Trail(trailRecord));
    }
}
