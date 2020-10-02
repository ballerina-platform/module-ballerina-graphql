import ballerina/io;
import ballerina/lang.'object;

public class Listener {
    *'object:Listener;

    public function init(int port, string url = "graphql", Configurations? configs = ()) {
        io:println("init");
    }

    public function __attach(service s, string? name = ()) returns error? {
        return attach(self, s, name);
    }

    public function __detach(service s) returns error? {
        io:println("attach");
    }

    public function __start() returns error? {
        io:println("start");
    }

    public function __gracefulStop() returns error? {
        io:println("gracefulStop");
    }

    public function __immediateStop() returns error? {
        io:println("immediateStop");
    }
}
