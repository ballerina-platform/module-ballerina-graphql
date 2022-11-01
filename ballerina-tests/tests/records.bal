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

type Information Address|Person;

public type Account record {
    int number;
    Contact? contact;
};

public type Pet record {
    string name;
    string ownerName;
    Animal animal;
};

public type Animal readonly & record {
    string commonName;
    Species species;
};

type Species record {
    string genus;
    string specificName;
};

type Details record {
    Information information;
};

public type Address readonly & record {
    string number;
    string street;
    string city;
};

public type Person readonly & record {
    string name;
    int age;
    Address address;
};

public type Book readonly & record {
    string name;
    string author;
};

type Course readonly & record {
    string name;
    int code;
    Book[] books;
};

public type Student readonly & record {
    string name;
    Course[] courses;
};

type Employee readonly & record {|
    readonly int id;
    string name;
    decimal salary;
|};

public type Contact readonly & record {
    string number;
};

public type Worker readonly & record {|
    string id;
    string name;
    map<Contact> contacts;
|};

public type Company readonly & record {|
    map<Worker> workers;
    map<Contact> contacts;
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

public type Time record {|
    Weekday weekday;
    string time;
|};

public enum Status {
    OPEN,
    CLOSED,
    HOLD
}

public type LiftRecord readonly & record {|
    readonly string id;
    string name;
    Status status;
    int capacity;
    boolean night;
    int elevationgain;
|};

public type TrailRecord readonly & record {|
    readonly string id;
    string name;
    Status status;
    string difficulty;
    boolean groomed;
    boolean trees;
    boolean night;
|};

public type EdgeRecord readonly & record {|
    readonly string liftId;
    readonly string trailId;
|};

public type Movie record {
    string movieName;
    string director?;
};

public type ProfileDetail record {
    string name;
    int age?;
};

public type Info record {
    string bookName;
    int edition;
    ProfileDetail author;
    Movie movie?;
};

public type Date record {
    Weekday day;
};

public type Weight record {
    float weightInKg;
};

public type WeightInKg record {
    int weight;
};

public type Author record {
    string? name;
    int id;
};

public type TvSeries record {
    string name;
    string director?;
    Episode[] episodes?;
};

public type Episode record {
    string title;
    int timeDuration?;
    string[] newCharacters?;
};

public type FileInfo record {
    string fileName;
    string mimeType;
    string encoding;
    string content;
};

public type Item record {
    string name;
    decimal price;
};

# Represents a shape
#
# + name - Name of the shape
# + edges - Number of edges in the shape
public type Shape record {
    string name;
    int edges;
};

# Represents an instrument
#
# + name - Name of the instrument
# + type - The type of the musical instrument
public type Instrument readonly & record {
    string name;
    InstrumentType 'type;
};

# Represents the types of musical instruments.
public enum InstrumentType {
    # Instruments with strings
    STRINGS = "Strings Instruments",
    # Instruments with wooden pipes
    WOODWIND,
    # Instruments with keyboards
    KEYBOARD,
    # Brass instruments
    # # Deprecated
    # Not used in this band
    @deprecated
    BRASS,
    # Instruments with leather, wooden or metal surfaces
    PERCUSSION
}

type WSPayload record {|
    string 'type;
    string id?;
    json payload?;
|};

public type Languages record {|
    map<string> name;
|};

public type CovidEntry record {|
    string isoCode;
|};

public type Review record {|
  Product product;
  int score;
  string description;
|};

public type AccountRecords record {|
    map<AccountDetails> details;
|};