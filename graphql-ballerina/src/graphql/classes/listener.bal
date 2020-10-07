import ballerina/lang.'object;

public class Listener {
    *'object:Listener;
    int port;

    public isolated function init(int port, string url = "graphql", Configurations? configs = ()) {
        self.port = port;
    }

    public isolated function __attach(service s, string? name = ()) returns error? {
        return attach(self, s, name);
    }

    public isolated function __detach(service s) returns error? {
    }

    public isolated function __start() returns error? {
    }

    public isolated function __gracefulStop() returns error? {
    }

    public isolated function __immediateStop() returns error? {
    }
}
