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

# An autonomous mechanical character in the Star Wars universe
distinct service class Droid {
    *Character;

    private final readonly & ds:DroidRecord droid;

    function init(ds:DroidRecord droid) {
        self.droid = droid.cloneReadOnly();
    }

    # The unique identifier of the droid
    # + return - The id
    resource function get id() returns string {
        return self.droid.id;
    }

    # The name of the droid
    # + return - The name
    resource function get name() returns string {
        return self.droid.name;
    }

    # This droid's friends, or an empty list if they have none
    # + return - The friends
    resource function get friends() returns Character[] {
        Character[] friends = [];
        ds:FriendsEdgeRecord[] edges = from var edge in ds:friendsEdgeTable
                        join var droid in [self.droid] on edge.characterId equals droid.id
                        select edge;
        friends.push(...from var human in ds:humanTable
                        join var edge in edges on human.id equals edge.friendId
                        select new Human(human));
        friends.push(...from var droid in ds:droidTable
                        join var edge in edges on droid.id equals edge.friendId
                        select new Droid(droid));
        return friends;
    }

    # The episodes this droid appears in
    # + return - The episodes
    resource function get appearsIn() returns Episode[] {
        return self.droid.appearsIn;
    }

    # This droid's primary function
    # + return - The primaryFunction
    resource function get primaryFunction() returns string? {
        return self.droid?.primaryFunction;
    }
}
