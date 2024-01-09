import ballerina/lang.runtime;
import ballerina/graphql;

public function main() returns error? {
    graphql:Service gqlService = service object {
        resource function get greeting() returns string {
            return "Wubba lubba dub dub!!";
        }
    };
    graphql:Listener l = check new(9090);
    check l.attach(gqlService, "graphql");
    check l.'start();
    runtime:registerListener(l);
}