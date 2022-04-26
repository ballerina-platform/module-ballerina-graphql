// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/graphql;

# Represents days of the week
public enum Weekday {
    # Sunday
    SUNDAY,
    # Monday
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    # # Deprecated
    # Saturday is not a weekday :)
    @deprecated
    SATURDAY
}

isolated service on new graphql:Listener(9000) {

    isolated resource function get day() returns Weekday {
        return SUNDAY;
    }

    isolated resource function get optionalDay() returns Weekday? {
        return SUNDAY;
    }
}
