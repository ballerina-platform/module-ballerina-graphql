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

import ballerina/graphql;
import starwars.datasource as ds;

type Character Human|Droid;

type SearchResult Human|Droid|Starship;

public enum Episode {
    NEWHOPE,
    EMPIRE,
    JEDI
}

type Starship record {
    readonly string id;
    string name;
    float length?;
    float[][] cordinates?;
};

public type Review record {
    Episode episode?;
    int stars;
    string commentary?;
};

public type ReviewInput record {
    int stars;
    string commentary;
};

service /graphql on new graphql:Listener(9000) {

    # Fetch the hero of the Star Wars
    # + return - The hero
    resource function get hero(Episode? episode) returns Character {
        if episode == EMPIRE {
            return new Human(<ds:HumanRecord> ds:humanTable["1000"]);
        }
        return new Droid(<ds:DroidRecord> ds:droidTable["2001"]);
    }

    # Returns reviews of the Star Wars
    # + return - The reviews
    resource function get reviews(Episode episode) returns Review?[] {
        return ds:getReviews(episode);
    }

    # Returns characters by id, or null if character is not found
    # + return - The characters
    resource function get characters(string[] idList) returns Character?[] {
        Character[] characters = [];
        foreach string id in idList {
            if ds:humanTable[id] is ds:HumanRecord {
                characters.push(new Human(<ds:HumanRecord> ds:humanTable[id]));
            } else if ds:droidTable[id] is ds:DroidRecord {
                characters.push(new Droid(<ds:DroidRecord> ds:droidTable[id]));
            }
        }
        return characters;
    }

    # Returns a droid by id, or null if droid is not found
    # + return - The Droid
    resource function get droid(string id = "2000") returns Droid? {
        if ds:droidTable[id] is ds:DroidRecord {
            return new Droid(<ds:DroidRecord> ds:droidTable[id]);
        }
        return;
    }

    # Returns a human by id, or null if human is not found
    # + return - The Human
    resource function get human(string id) returns Human? {
        if ds:humanTable[id] is ds:HumanRecord {
            return new Human(<ds:HumanRecord> ds:humanTable[id]);
        }
        return;
    }

    # Returns a starship by id, or null if starship is not found
    # + return - The Starship
    resource function get starship(string id) returns Starship? {
        return ds:starshipTable[id];
    }

    # Returns search results by text, or null if search item is not found
    # + return - The SearchResult
    resource function get search(string text) returns SearchResult[]? {
        SearchResult[] searchResult = [];
        if text.includes("human") {
            ds:HumanRecord[] humans = from var human in ds:humanTable select human;
            foreach ds:HumanRecord human in humans {
                searchResult.push(new Human(human));
            }
        }
        if text.includes("droid") {
            ds:DroidRecord[] droids = from var droid in ds:droidTable select droid;
            foreach ds:DroidRecord droid in droids {
                searchResult.push(new Droid(droid));
            }
        }
        if text.includes("starship") {
            ds:StarshipRecord[] starships = from var ship in ds:starshipTable select ship;
            foreach ds:StarshipRecord ship in starships {
                searchResult.push(ship);
            }
        }
        if searchResult.length() > 0 {
            return searchResult;
        }
        return;
    }

    # Add new reviews and return the review values
    #
    # + episode - Episode name  
    # + reviewInput - Review of the episode
    # + return - The reviews
    remote function createReview(Episode episode, ReviewInput reviewInput) returns Review[] {
        ds:ReviewRecord newReview = {
            episode: episode,
            stars: reviewInput.stars,
            commentary: reviewInput.commentary
        };
        return ds:updateReviews(episode, newReview);
    }
}
