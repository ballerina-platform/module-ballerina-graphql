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