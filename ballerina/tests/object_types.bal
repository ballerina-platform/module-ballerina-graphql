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

isolated service class Name {
    isolated resource function get first() returns string {
        return "Sherlock";
    }

    isolated resource function get last() returns string {
        return "Holmes";
    }
}

isolated service class Profile {
    isolated resource function get name() returns Name {
        return new;
    }
}

isolated service class GeneralGreeting {
    isolated resource function get generalGreeting() returns string {
        return "Hello, world";
    }
}

distinct isolated service class HierarchicalName {
    isolated resource function get name/first() returns string {
        return "Sherlock";
    }

    isolated resource function get name/last() returns string {
        return "Holmes";
    }
}

type SearchResult Lift|Trail;

distinct isolated service class Lift {
    private final readonly & LiftRecord lift;

    isolated function init(LiftRecord lift) {
        self.lift = lift.cloneReadOnly();
    }

    isolated resource function get id () returns string {
        return self.lift.id;
    }

    isolated resource function get name () returns string {
        return self.lift.name;
    }

    isolated resource function get status () returns string {
        return self.lift.status;
    }

    isolated resource function get capacity () returns int {
        return self.lift.capacity;
    }

    isolated resource function get night () returns boolean {
        return self.lift.night;
    }

    isolated resource function get elevationgain () returns int {
        return self.lift.elevationgain;
    }

    isolated resource function get trailAccess () returns Trail[] {
        LiftRecord[] lifts = [self.lift];
        EdgeRecord[] edges = from var edge in edgeTable
                       join var lift in lifts on edge.liftId equals lift.id
                       select edge;
        TrailRecord[] trails = from var trail in trailTable
                      join var edge in edges on trail.id equals edge.trailId
                      select trail;
        return trails.map(trailRecord => new Trail(trailRecord));
    }
}

distinct isolated service class Trail {
    private final readonly & TrailRecord trail;

    isolated function init(TrailRecord trail) {
        self.trail = trail.cloneReadOnly();
    }

    isolated resource function get id () returns string {
        return self.trail.id;
    }

    isolated resource function get name () returns string {
        return self.trail.name;
    }

    isolated resource function get status () returns string {
        return self.trail.status;
    }

    isolated resource function get difficulty () returns string? {
        return self.trail.difficulty;
    }

    isolated resource function get groomed () returns boolean {
        return self.trail.groomed;
    }

    isolated resource function get trees () returns boolean {
        return self.trail.trees;
    }

    isolated resource function get night () returns boolean {
        return self.trail.night;
    }

    isolated resource function get accessByLifts () returns Lift[] {
        TrailRecord[] trails = [self.trail];
        EdgeRecord[] edges = from var edge in edgeTable
                       join var trail in trails on edge.trailId equals trail.id
                       select edge;
        LiftRecord[] lifts = from var lift in liftTable
                      join var edge in edges on lift.id equals edge.liftId
                      select lift;
        return lifts.map(liftRecord => new Lift(liftRecord));
    }
}

distinct isolated service class StudentService {
    private final int id;
    private final string name;

    public isolated function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get name() returns string {
        return self.name;
    }
}

public distinct isolated service class TeacherService {
    private final int id;
    private string name;
    private string subject;

    public isolated function init(int id, string name, string subject) {
        self.id = id;
        self.name = name;
        self.subject = subject;
    }

    isolated resource function get id() returns int {
        return self.id;
    }

    isolated resource function get name() returns string {
        lock {
            return self.name;
        }
    }

    isolated function setName(string name) {
        lock {
            self.name = name;
        }
    }

    isolated resource function get subject() returns string {
        lock {
            return self.subject;
        }
    }

    isolated function setSubject(string subject) {
        lock {
            self.subject = subject;
        }
    }
}
