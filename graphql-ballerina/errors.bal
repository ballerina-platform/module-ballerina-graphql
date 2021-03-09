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

# Represents any error related to the Ballerina GraphQL module
public type Error distinct error;

# Represents a non-implemented feature error
public type NotImplementedError distinct Error;

# Represents an error due to invalid type in GraphQL service
public type InvalidTypeError distinct Error;

# Represents an unsupported functionality error
public type NotSupportedError distinct Error;

# Represents an error due to invalid configurations
public type InvalidConfigurationError distinct Error;

# Represents an error occurred in the listener while handling a service
public type ServiceHandlingError distinct Error;
