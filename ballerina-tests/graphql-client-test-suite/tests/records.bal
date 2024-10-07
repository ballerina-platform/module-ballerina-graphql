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

import ballerina/graphql;

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

public type Student readonly & record {
    string name;
    Course[] courses;
};

type Course readonly & record {
    string name;
    int code;
    Book[] books;
};

public type Book readonly & record {
    string name;
    string author;
};

public type Time record {|
    Weekday weekday;
    string time;
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

type ProfileResponseWithErrors record {|
    *graphql:GenericResponseWithErrors;
    ProfileResponse data;
|};

type ProfileResponse record {|
    ProfileData one;
|};

type ProfileData record {
    string name;
};

type GreetingResponse record {|
    map<json?> extensions?;
    record {|
        string greet;
    |} data;
|};

type GenericGreetingResponse record {|
    map<json?> extensions?;
    map<json?> data?;
|};

type GreetingResponseWithErrors record {|
    map<json?> extensions?;
    record {|
        string greet;
    |} data;
    graphql:ErrorDetail[] errors?;
|};

type GenericGreetingResponseWithErrors record {|
    map<json?> extensions?;
    map<json?> data?;
    graphql:ErrorDetail[] errors?;
|};

type SetNameResponse record {|
    map<json?> extensions?;
    record {|
        record {|
            string name;
        |} setName;
    |} data;
|};

type SetNameResponseWithErrors record {|
    map<json?> extensions?;
    record {|
        record {|
            string name;
        |} setName;
    |} data;
    graphql:ErrorDetail[] errors?;
|};

type PersonResponse record {|
    map<json?> extensions?;
    PersonDataResponse data;
|};

type PersonResponseWithErrors record {|
    map<json?> extensions?;
    PersonDataResponse data;
    graphql:ErrorDetail[] errors?;
|};

type PersonDataResponse record {|
    DetectiveResponse detective;
|};

type DetectiveResponse record {|
    string name;
    AddressResponse address;
|};

type AddressResponse record {|
    string street;
|};

type PeopleResponse record {|
    map<json?> extensions?;
    PeopleDataResponse data;
|};

type PeopleResponseWithErrors record {|
    map<json?> extensions?;
    PeopleDataResponse data;
    graphql:ErrorDetail[] errors?;
|};

type PeopleDataResponse record {|
    PersonInfoResponse[] people;
|};

type PersonInfoResponse record {|
    string name;
    AddressInfoResponse address;
|};

type AddressInfoResponse record {|
    string city;
|};
