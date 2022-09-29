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

import starwars.datasource as ds;

# A ship from the Star Wars universe
public distinct isolated service class Starship {

    private final readonly & ds:StarshipRecord starship;

    isolated function init(ds:StarshipRecord starship) {
        self.starship = starship.cloneReadOnly();
    }

    # The unique identifier of the starship
    # + return - The id
    isolated resource function get id() returns string {
        return self.starship.id;
    }

    # The name of the starship
    # + return - The name
    isolated resource function get name() returns string {
        return self.starship.name;
    }

    # The length of the starship, or null if unknown
    # + return - The length
    isolated resource function get length() returns float? {
        return self.starship?.length;
    }

    # Cordinates of the starship, or null if unknown
    # + return - The cordinates
    isolated resource function get cordinates() returns float[][]? {
        return self.starship?.cordinates;
    }
}
