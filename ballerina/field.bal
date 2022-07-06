import graphql.parser;

# Stores the information about a particular field in a GraphQL document.
public class Field {
    private final parser:FieldNode internalNode;
    private final service object {} serviceObject;
    private final RequestInfo requestInfo;

    isolated function init(parser:FieldNode fieldNode, service object {} serviceObject, RequestInfo reqInfo) {
        self.internalNode = fieldNode;
        self.serviceObject = serviceObject;
        self.requestInfo = reqInfo;
    }

    # Returns the name of the field
    # + return - The name of the field
    public isolated function getName() returns string {
        return self.internalNode.getName();
    }

    # Returns the alias of the field
    # + return - If the field has an alias, returns the alias, otherwise returns the name
    public isolated function getAlias() returns string {
        return self.internalNode.getAlias();
    }

    isolated function getInternalNode() returns parser:FieldNode {
        return self.internalNode;
    }

    isolated function getServiceObject() returns service object {} {
        return self.serviceObject;
    }

    isolated function getRequestInfo() returns RequestInfo {
        return self.requestInfo;
    }
}
