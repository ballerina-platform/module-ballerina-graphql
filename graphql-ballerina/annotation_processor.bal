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

isolated function getMaxQueryDepth(Service serviceObject) returns int|InvalidConfigurationError {
    GraphqlServiceConfiguration? serviceConfig = getServiceConfiguration(serviceObject);
    if (serviceConfig is GraphqlServiceConfiguration) {
        if (serviceConfig?.maxQueryDepth is int) {
            int maxQueryDepth = <int>serviceConfig?.maxQueryDepth;
            if (maxQueryDepth < 1) {
                string message = "Maximum query depth should be an integer greater than 0";
                return error InvalidConfigurationError(message);
            }
            return maxQueryDepth;
        }
    }
    return 0;
}

isolated function getServiceConfiguration(Service serviceObject) returns GraphqlServiceConfiguration? {
    typedesc<any> serviceType = typeof serviceObject;
    var serviceConfiguration = serviceType.@ServiceConfiguration;
    return serviceConfiguration;
}
