public enum Status {
    OPEN,
    CLOSED,
    HOLD
}

public type LiftRecord record {|
    readonly string id;
    string name;
    Status status;
    int capacity;
    boolean night;
    int elevationgain;
|};

public type TrailRecord record {|
    readonly string id;
    string name;
    Status status;
    string difficulty;
    boolean groomed;
    boolean trees;
    boolean night;
|};

public type EdgeRecord record {|
    readonly string liftId;
    readonly string trailId;
|};

public table<LiftRecord> key(id) liftTable = table [
    { id: "astra-express", name: "Astra Express", status: OPEN, capacity: 10, night: false, elevationgain: 20},
    { id: "jazz-cat", name: "Jazz Cat", status: CLOSED, capacity: 5, night: true, elevationgain: 30},
    { id: "jolly-roger", name: "Jolly Roger", status: CLOSED, capacity: 8, night: true, elevationgain: 10}
];

public table<TrailRecord> key(id) trailTable = table [
    {id: "blue-bird", name: "Blue Bird", status: OPEN, difficulty: "intermediate", groomed: true, trees: false, night: false},
    {id: "blackhawk", name: "Blackhawk", status: OPEN, difficulty: "intermediate", groomed: true, trees: false, night: false},
    {id: "ducks-revenge", name: "Duck's Revenge", status: CLOSED, difficulty: "expert", groomed: true, trees: false, night: false}
];

public table<EdgeRecord> key(liftId, trailId) edgeTable = table [
    {liftId: "astra-express", trailId: "blue-bird"}
];
