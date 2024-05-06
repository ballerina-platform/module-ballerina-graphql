// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;
import ballerina/observe;

type TraceObserverContext record {|
    Context context;
    string serviceName = "graphql:Document";
    string operationType = "Document";
    string operationName;
    string moduleName = "graphql";
    string fileName = "listener_utils.bal";
    int startLine = 78;
    int startColumn = 5;
|};

type TraceInformation record {|
    Context context;
    string serviceName;
    string operationType;
|};

isolated function addFieldMetric(Field 'field) {
    if metricsEnabled {
        checkpanic observe:addTagToMetrics(GRAPHQL_FIELD_NAME, 'field.getQualifiedName());
    }
}

isolated function addObservabilityMetricsTags(string key, string value) {
    if metricsEnabled {
        checkpanic observe:addTagToMetrics(key, value);
    }
}

isolated function addTracingInfomation(TraceObserverContext|TraceInformation traceInformation) {
    if !tracingEnabled {
        return;
    }
    if traceInformation is TraceObserverContext {
        createAndStartObserverContext(traceInformation.context, traceInformation.serviceName,
                traceInformation.operationType, traceInformation.operationName, traceInformation.moduleName,
                traceInformation.fileName, traceInformation.startLine, traceInformation.startColumn);
    } else {
        createObserverContext(traceInformation.context, traceInformation.serviceName, traceInformation.operationType);
    }
}

isolated function stopTracing(Context context, error? err = ()) {
    if tracingEnabled {
        if err is () {
            stopObserverContext(context);
        } else {
            stopObserverContextWithError(context, err);
        }
    }
}

isolated function createObserverContext(Context context, string serviceName, string operationType) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;

isolated function createAndStartObserverContext(Context context, string serviceName, string operationType, string operationName,
        string moduleName, string fileName, int startLine, int startColumn) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;

isolated function stopObserverContext(Context context) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;

isolated function stopObserverContextWithError(Context context, error err) = @java:Method {
    'class: "io.ballerina.stdlib.graphql.runtime.engine.ListenerUtils"
} external;
