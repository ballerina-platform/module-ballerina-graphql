import snowtooth.datasource as ds;

# A `Trail` is a run at a ski resort
distinct service class Trail {

    private ds:TrailRecord trail;

    function init(ds:TrailRecord trail) {
        self.trail = trail;
    }

    # A unique identifier for a `Trail` (id: 'hemmed-slacks')
    # + return - the id
    resource function get id () returns string {
        return self.trail.id;
    }

    # The name of a `Trail`
    # + return - the name
    resource function get name () returns string {
        return self.trail.name;
    }

    # The current status for a `Trail`: OPEN, CLOSED
    # + return - the status
    resource function get status () returns string {
        return self.trail.status;
    }

    # The difficulty rating for a `Trail`
    # + return - the difficulty
    resource function get difficulty () returns string? {
        return self.trail.difficulty;
    }

    # A boolean describing whether or not a `Trail` is groomed
    # + return - the boolean status
    resource function get groomed () returns boolean {
        return self.trail.groomed;
    }

    # A boolean describing whether or not a `Trail` has trees
    # + return - the boolean status
    resource function get trees () returns boolean {
        return self.trail.trees;
    }

    # A boolean describing whether or not a `Trail` is open for night skiing
    # + return - the boolean status
    resource function get night () returns boolean {
        return self.trail.night;
    }

    # A list of Lifts that provide access to this `Trail`
    # + return - the lifts
    resource function get accessByLifts () returns Lift[] {
        ds:TrailRecord[] trails = [self.trail];
        ds:EdgeRecord[] edges = from var edge in ds:edgeTable
                       join var trail in trails on edge.trailId equals trail.id
                       select edge;
        ds:LiftRecord[] lifts = from var lift in ds:liftTable
                      join var edge in edges on lift.id equals edge.liftId
                      select lift;
        return lifts.map(function (ds:LiftRecord liftRecord) returns Lift => new Lift(liftRecord));
    }
}