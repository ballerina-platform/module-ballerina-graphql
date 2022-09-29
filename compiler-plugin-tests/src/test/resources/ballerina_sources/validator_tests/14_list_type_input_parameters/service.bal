// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

type Profile record {
    string name;
    int age;
    string[] otherNames?;
};

enum Weekday {
    SUNDAY,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
}

service graphql:Service on new graphql:Listener(4000) {
    isolated resource function get concat(string[] words) returns string {
        string result = "";
        if words.length() > 0 {
            foreach string word in words {
                result += word;
            }
        }
        return "Word list is empty";
    }

    isolated resource function get getTotal(float[][] prices) returns boolean {
        foreach float[] nested in prices {
            foreach float price in nested {
                if price > 50.5 {
                    return true;
                }
            }
        }
        return false;
    }

    isolated resource function get searchProfile(Profile[] profiles) returns string {
        foreach Profile profile in profiles {
            if profile?.otherNames is string[] {
                return profile.name;
            }
        }
        return "";
    }

    isolated resource function get isHoliday(Weekday[] days) returns boolean {
        if days.indexOf(<Weekday> SUNDAY) != () {
            return true;
        }
        return false;
    }
}
