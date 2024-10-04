// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/constraint;

public type MovieDetails record {|
    @constraint:String {
        minLength: 1,
        maxLength: 10
    }
    string name;

    @constraint:Int {
        minValue: 18
    }
    int downloads;

    @constraint:Float {
        minValue: 1.5
    }
    float imdb;

    @constraint:Array {
        length: 1
    }
    Reviews?[] reviews;
|};

public type Reviews readonly & record {|
    @constraint:Array {
        maxLength: 2
    }
    string[] comments;

    @constraint:Int {
        minValueExclusive: 0,
        maxValueExclusive: 6
    }
    int stars;
|};

public enum Weekday {
    SUNDAY,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
}
