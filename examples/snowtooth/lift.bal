import snowtooth.datasource as ds;

# A `Lift` is a chairlift, gondola, tram, funicular, pulley, rope tow, or other means of ascending a mountain.
distinct service class Lift {

    private ds:LiftRecord lift;

    function init(ds:LiftRecord lift) {
        self.lift = lift;
    }

    # The unique identifier for a `Lift` (id: "panorama")
    # + return - the id
    resource function get id () returns string {
        return self.lift.id;
    }

    # The name of a `Lift`
    # + return - the name
    resource function get name () returns string {
        return self.lift.name;
    }

    # The current status for a `Lift`: `OPEN`, `CLOSED`, `HOLD`
    # + return - the status
    resource function get status () returns string {
        return self.lift.status;
    }

    # The number of people that a `Lift` can hold
    # + return - the capcasity
    resource function get capacity () returns int {
        return self.lift.capacity;
    }

    # A boolean describing whether a `Lift` is open for night skiing
    # + return - the boolean
    resource function get night () returns boolean {
        return self.lift.night;
    }

    # The number of feet in elevation that a `Lift` ascends
    # + return - the elevationgain
    resource function get elevationgain () returns int {
        return self.lift.elevationgain;
    }

    # A list of trails that this `Lift` serves
    # + return - the trails
    resource function get trailAccess () returns Trail {
        ds:LiftRecord[] lifts = [self.lift];
        ds:EdgeRecord[] edges = from var edge in ds:edgeTable
                       join var lift in lifts on edge.liftId equals lift.id
                       select edge;
        ds:TrailRecord[] trails = from var trail in ds:trailTable
                      join var edge in edges on trail.id equals edge.trailId
                      select trail;
        return new Trail(trails[0]);
    }
}

