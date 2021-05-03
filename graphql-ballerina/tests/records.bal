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

type Address record {
    string number;
    string street;
    string city;
};

type Person record {
    string name;
    int age;
    Address address;
};

type Book record {
    string name;
    string author;
};

type Course record {
    string name;
    int code;
    Book[] books;
};

type Student record {
    string name;
    Course[] courses;
};

type Employee record {|
    readonly int id;
    string name;
    decimal salary;
|};

type EmployeeTable table<Employee> key(id);

public enum Weekday {
    SUNDAY,
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
}

type Time record {|
    Weekday weekday;
    string time;
|};

type TLift record {|
    readonly string id;
    string name;
    string status;
    int capacity;
    boolean night;
    int elevationgain;
|};

type TTrail record {|
    readonly string id;
    string name;
    string status;
    string difficulty;
    boolean groomed;
    boolean trees;
    boolean night;
|};

type Edge record {|
    readonly string liftId;
    readonly string trailId;
|};
