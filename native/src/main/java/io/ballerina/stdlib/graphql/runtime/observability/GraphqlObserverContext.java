package io.ballerina.stdlib.graphql.runtime.observability;

import io.ballerina.runtime.observability.ObserverContext;

public class GraphqlObserverContext extends ObserverContext {
    public GraphqlObserverContext() {
        setObjectName(GraphqlObservabilityConstants.OBJECT_NAME);
        addTag(GraphqlObservabilityConstants.TAG_LISTENER_NAME, GraphqlObservabilityConstants.CONNECTOR_NAME);
    }

    public GraphqlObserverContext(String operationType) {
        setObjectName(GraphqlObservabilityConstants.OBJECT_NAME);
        addTag(GraphqlObservabilityConstants.TAG_LISTENER_NAME, GraphqlObservabilityConstants.CONNECTOR_NAME);
        addTag(GraphqlObservabilityConstants.TAG_KEY_OPERATION_TYPE, operationType);
    }
}
