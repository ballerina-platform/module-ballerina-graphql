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
import starwars.datasource as ds;

public type Character Human|Droid;

public enum Episode {
    NEWHOPE,
    EMPIRE,
    JEDI
}

public type Starship record {|
    readonly string id;
    string name;
    float length?;
    float[][] cordinates?;
|};

public type Review record {|
    Episode episode?;
    int stars;
    string commentary?;
|};

public type ReviewInput record {|
    int stars;
    string commentary;
|};

service /graphql on new graphql:Listener(9000) {

    # Fetch the hero of the Star Wars
    # + return - the hero  
    resource function get hero(Episode? episode) returns Character {
        if episode == EMPIRE {
            return new Human(<ds:HumanRecord> ds:humanTable["1000"]);
        }
        return new Droid(<ds:DroidRecord> ds:droidTable["2001"]);
    }

    # Returns reviews of the Star Wars
    # + return - the reviews 
    resource function get reviews(Episode episode) returns Review?[] {
        ds:ReviewRecord[] reviews = from var review in ds:reviewTable where review.episode == episode select review;
        return reviews;
    }

    # Returns a character by id, or null if character is not found
    # + return - the characters
    resource function get characters(string[] idList) returns Character?[] {
        Character?[] characters = [];
        foreach string id in idList {
            if ds:humanTable[id] is ds:HumanRecord {
                characters.push(new Human(<ds:HumanRecord> ds:humanTable[id]));
            } else if ds:droidTable[id] is ds:DroidRecord {
                characters.push(new Droid(<ds:DroidRecord> ds:droidTable[id]));
            }
            characters.push(null);
        }
        return characters;
    }

    # Returns a droid by id, or null if droid is not found
    # + return - the Droid  
    resource function get droid(string id = "2000") returns Droid? {
        if ds:droidTable[id] is ds:DroidRecord {
            return new Droid(<ds:DroidRecord> ds:droidTable[id]);
        }
        return;
    }

    # Returns a human by id, or null if human is not found
    # + return - the Human  
    resource function get human(string id) returns Human? {
        if ds:humanTable[id] is ds:HumanRecord {
            return new Human(<ds:HumanRecord> ds:humanTable[id]);
        }
        return;
    }

    # Returns a starship by id, or null if starship is not found
    # + return - the Starship  
    resource function get starship(string id) returns Starship? {
        return ds:starshipTable[id];
    }

    # Add new reviews and return the review values
    #
    # + episode - Episode name  
    # + reviewInput - Review of the episode
    # + return - the reviews
    remote function createReview(Episode episode, ReviewInput reviewInput) returns Review[] {
        ds:ReviewRecord newReview = {
            episode: episode,
            stars: reviewInput.stars,
            commentary: reviewInput.commentary
        };
        ds:reviewTable.add(newReview);
        ds:ReviewRecord[] reviews = from var review in ds:reviewTable where review.episode == episode select review;
        return reviews;
    }
}
