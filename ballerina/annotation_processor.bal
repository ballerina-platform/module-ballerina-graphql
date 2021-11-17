// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

isolated function getMaxQueryDepth(GraphqlServiceConfig? serviceConfig) returns int? {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig?.maxQueryDepth;
    }
    return;
}

isolated function getListenerAuthConfig(GraphqlServiceConfig? serviceConfig) returns ListenerAuthConfig[]? {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig?.auth;
    }
    return;
}

isolated function getContextInit(GraphqlServiceConfig? serviceConfig) returns ContextInit {
    if serviceConfig is GraphqlServiceConfig {
        return serviceConfig.contextInit;
    }
    return initDefaultContext;
}

isolated function getServiceConfig(Service serviceObject) returns GraphqlServiceConfig? {
    typedesc<any> serviceType = typeof serviceObject;
    return serviceType.@ServiceConfig;
}
