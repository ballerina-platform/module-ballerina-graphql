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

public enum Status {
    OPEN,
    CLOSED,
    HOLD
}

public type LiftRecord readonly & record {|
    readonly string id;
    string name;
    Status status;
    int capacity;
    boolean night;
    int elevationgain;
|};

public type TrailRecord readonly & record {|
    readonly string id;
    string name;
    Status status;
    string difficulty;
    boolean groomed;
    boolean trees;
    boolean night;
|};

public type EdgeRecord readonly & record {|
    readonly string liftId;
    readonly string trailId;
|};

public final readonly & table<LiftRecord> key(id) liftTable = table [
    { id: "astra-express", name: "Astra Express", status: OPEN, capacity: 10, night: false, elevationgain: 20},
    { id: "jazz-cat", name: "Jazz Cat", status: CLOSED, capacity: 5, night: true, elevationgain: 30},
    { id: "jolly-roger", name: "Jolly Roger", status: CLOSED, capacity: 8, night: true, elevationgain: 10}
];

public final readonly & table<TrailRecord> key(id) trailTable = table [
    {id: "blue-bird", name: "Blue Bird", status: OPEN, difficulty: "intermediate", groomed: true, trees: false, night: false},
    {id: "blackhawk", name: "Blackhawk", status: OPEN, difficulty: "intermediate", groomed: true, trees: false, night: false},
    {id: "ducks-revenge", name: "Duck's Revenge", status: CLOSED, difficulty: "expert", groomed: true, trees: false, night: false}
];

public final readonly & table<EdgeRecord> key(liftId, trailId) edgeTable = table [
    {liftId: "astra-express", trailId: "blue-bird"},
    {liftId: "astra-express", trailId: "ducks-revenge"},
    {liftId: "jazz-cat", trailId: "blue-bird"},
    {liftId: "jolly-roger", trailId: "blackhawk"},
    {liftId: "jolly-roger", trailId: "ducks-revenge"}
];
