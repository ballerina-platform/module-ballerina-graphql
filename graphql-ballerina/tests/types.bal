// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

type SearchResult Lift|Trail;

service class Lift {

    private TLift tLift;

    isolated function init(TLift tLift) {
        self.tLift = tLift;
    }

    isolated resource function get id () returns string {
        return self.tLift.id;
    }

    isolated resource function get name () returns string {
        return self.tLift.name;
    }

    isolated resource function get status () returns string {
        return self.tLift.status;
    }

    isolated resource function get capacity () returns int {
        return self.tLift.capacity;
    }

    isolated resource function get night () returns boolean {
        return self.tLift.night;
    }

    isolated resource function get elevationgain () returns int {
        return self.tLift.elevationgain;
    }

    resource function get trailAccess () returns Trail {
        TLift[] lifts = [self.tLift];
        Edge[] edges = from var edge in edgeTable
                       join var lift in lifts on edge.liftId equals lift.id
                       select edge;
        TTrail[] trails = from var trail in trailTabel
                      join var edge in edges on trail.id equals edge.trailId
                      select trail;
        return new Trail(trails[0]);
    }
}

service class Trail {

    private TTrail tTrail;

    isolated function init(TTrail tTrail) {
        self.tTrail = tTrail;
    }

    isolated resource function get id () returns string {
        return self.tTrail.id;
    }

    isolated resource function get name () returns string {
        return self.tTrail.name;
    }

    isolated resource function get status () returns string {
        return self.tTrail.status;
    }

    isolated resource function get difficulty () returns string? {
        return self.tTrail.difficulty;
    }

    isolated resource function get groomed () returns boolean {
        return self.tTrail.groomed;
    }

    isolated resource function get trees () returns boolean {
        return self.tTrail.trees;
    }

    isolated resource function get night () returns boolean {
        return self.tTrail.night;
    }

    resource function get accessByLifts () returns Lift {
        TTrail[] trails = [self.tTrail];
        Edge[] edges = from var edge in edgeTable
                       join var trail in trails on edge.trailId equals trail.id
                       select edge;
        TLift[] lifts = from var lift in liftTable
                      join var edge in edges on lift.id equals edge.liftId
                      select lift;
        return new Lift(lifts[0]);
    }
}
