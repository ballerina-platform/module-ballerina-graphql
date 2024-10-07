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

public type Person readonly & record {
    string name;
    int age?;
    Address address;
};

public type Address readonly & record {
    string number;
    string street;
    string city;
};

public type FileInfo record {
    string fileName;
    string mimeType;
    string encoding;
    string content;
};

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

type Friend record {|
    readonly string name;
    int age;
    boolean isMarried;
|};

type Enemy record {|
    readonly string name;
    int age;
    boolean isMarried;
|};

type Associate record {|
    readonly string name;
    string status;
|};

type EnemyInput record {|
    readonly string name = "Enemy6";
    int age = 12;
|};

type ProfileInfo record {|
    string name;
    int age;
    string contact;
|};

type User record {|
    int id?;
    string name?;
    int age?;
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
