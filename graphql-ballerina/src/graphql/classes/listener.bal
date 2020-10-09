import ballerina/http;
import ballerina/lang.'object;
import ballerina/log;

string basePath = "graphql";

public class Listener {
    *'object:Listener;
    int port;
    http:Listener httpListener;

    public isolated function init(int port, ListenerConfiguration? configs = ()) {
        http:ListenerConfiguration? httpListenerConfigs = ();
        if (configs is ListenerConfiguration) {
            httpListenerConfigs = getHttpListenerConfigs(configs);
        }
        self.httpListener = new(port, httpListenerConfigs);
        self.port = port;
    }

    // Cannot mark as isolated due to global variable usage. Discussion:
    // (https://ballerina-platform.slack.com/archives/C47EAELR1/p1602066015052000)
    public function __attach(service s, string? name = ()) returns error? {
        GraphQlServiceConfiguration? serviceConfig = getServiceAnnotations(s);
        if (serviceConfig is GraphQlServiceConfiguration) {
            basePath = serviceConfig.basePath;
        }
        checkpanic self.httpListener.__attach(httpService);
        checkpanic self.httpListener.__start();
        check attach(self, s, name);
        log:printInfo("started GraphQL listener " + self.port.toString());
    }

    public isolated function __detach(service s) returns error? {
        return detach(self, s);
    }

    public isolated function __start() returns error? {
    }

    public isolated function __gracefulStop() returns error? {
    }

    public isolated function __immediateStop() returns error? {
    }
}
