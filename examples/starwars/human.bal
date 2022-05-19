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

# A humanoid creature from the Star Wars universe
distinct service class Human {
    *Character;

    private final readonly & ds:HumanRecord human;

    function init(ds:HumanRecord human) {
        self.human = human.cloneReadOnly();
    }

    # The unique identifier of the human
    # + return - The id
    resource function get id() returns string {
        return self.human.id;
    }

    # The name of the human
    # + return - The name
    resource function get name() returns string {
        return self.human.name;
    }

    # The home planet of the human, or null if unknown
    # + return - The homePlanet
    resource function get homePlanet() returns string? {
        return self.human?.homePlanet;
    }

    # Height in meters, or null if unknown
    # + return - The height
    resource function get height() returns float? {
        return self.human.height;
    }

    # Mass in kilograms, or null if unknown
    # + return - The mass
    resource function get mass() returns int? {
        return self.human.mass;
    }

    # This human's friends, or an empty list if they have none
    # + return - The friends
    resource function get friends() returns Character[] {
        Character[] friends = [];
        ds:FriendsEdgeRecord[] edges = from var edge in ds:friendsEdgeTable
                        join var human in [self.human] on edge.characterId equals human.id
                        select edge;
        friends.push(...from var human in ds:humanTable
                        join var edge in edges on human.id equals edge.friendId
                        select new Human(human));
        friends.push(...from var droid in ds:droidTable
                        join var edge in edges on droid.id equals edge.friendId
                        select new Droid(droid));
        return friends;
    }

    # The episodes this human appears in
    # + return - The episodes
    resource function get appearsIn() returns Episode[] {
        return self.human.appearsIn;
    }

    # A list of starships this person has piloted, or an empty list if none
    # + return - The startships
    resource function get starships() returns Starship[] {
        ds:StarshipEdgeRecord[] edges = from var edge in ds:starshipEdgeTable
                        join var human in [self.human] on edge.characterId equals human.id
                        select edge;
        Starship[] starship = from var ship in ds:starshipTable
                        join var edge in edges on ship.id equals edge.starshipId
                        select new Starship(ship);
        return starship;
    }
}
