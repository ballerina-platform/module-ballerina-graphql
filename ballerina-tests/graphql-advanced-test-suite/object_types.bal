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

public type Device distinct service object {
    isolated resource function get id() returns @graphql:ID int;

    @graphql:ResourceConfig {
        complexity: 1
    }
    isolated resource function get brand() returns string;

    isolated resource function get model() returns string;

    @graphql:ResourceConfig {
        complexity: 4
    }
    isolated resource function get price() returns float;
};

type Mobile Phone|Tablet;

public isolated distinct service class Phone {
    *Device;

    private final int id;
    private final string brand;
    private final string model;
    private final float price;
    private final OS os;
    private final Device[] connectedDevices;

    isolated function init(int id, string brand, string model, float price, OS os) {
        self.id = id;
        self.brand = brand;
        self.model = model;
        self.price = price;
        self.os = os;
    }

    isolated resource function get id() returns @graphql:ID int => self.id;

    isolated resource function get brand() returns string => self.brand;

    isolated resource function get model() returns string => self.model;

    isolated resource function get price() returns float => self.price;

    isolated resource function get os() returns OS => self.os;
}

public isolated distinct service class Laptop {
    *Device;

    private final int id;
    private final string brand;
    private final string model;
    private final float price;
    private final string processor;
    private final int ram;

    isolated function init(int id, string brand, string model, float price, string processor, int ram) {
        self.id = id;
        self.brand = brand;
        self.model = model;
        self.price = price;
        self.processor = processor;
        self.ram = ram;
    }

    isolated resource function get id() returns @graphql:ID int => self.id;

    isolated resource function get brand() returns string => self.brand;

    isolated resource function get model() returns string => self.model;

    isolated resource function get price() returns float => self.price;

    isolated resource function get processor() returns string => self.processor;

    isolated resource function get ram() returns int => self.ram;
}

public isolated distinct service class Tablet {
    *Device;

    private final int id;
    private final string brand;
    private final string model;
    private final float price;
    private final boolean hasCellular;

    isolated function init(int id, string brand, string model, float price, boolean hasCellular) {
        self.id = id;
        self.brand = brand;
        self.model = model;
        self.price = price;
        self.hasCellular = hasCellular;
    }

    isolated resource function get id() returns @graphql:ID int => self.id;

    isolated resource function get brand() returns string => self.brand;

    isolated resource function get model() returns string => self.model;

    isolated resource function get price() returns float => self.price;

    isolated resource function get hasCellular() returns boolean => self.hasCellular;
}

service class Rating {
    private final RatingData data;

    isolated function init(RatingData data) {
        self.data = data;
    }

    isolated resource function get id() returns @graphql:ID int => self.data.id;

    @graphql:ResourceConfig {
        complexity: 1
    }
    isolated resource function get title() returns string => self.data.title;

    @graphql:ResourceConfig {
        complexity: 1
    }
    isolated resource function get stars() returns int => self.data.stars;

    isolated resource function get description() returns string => self.data.description;

    @graphql:ResourceConfig {
        complexity: 10
    }
    isolated resource function get author() returns DeviceUserProfile|error {
        lock {
            if profileTable.hasKey(self.data.authorId) {
                return new DeviceUserProfile(profileTable.get(self.data.authorId));
            }
        }
        return error("Author not found");
    }
}

service class DeviceUserProfile {
    private final DeviceUserProfileData data;

    isolated function init(DeviceUserProfileData data) {
        self.data = data;
    }

    isolated resource function get id() returns @graphql:ID int => self.data.id;

    isolated resource function get name() returns string => self.data.name;

    isolated resource function get age() returns int => self.data.age;
}
