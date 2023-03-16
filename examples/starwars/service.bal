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
import xlibb/pubsub;

import starwars.datasource as ds;

type SearchResult Human|Droid|Starship;

public enum Episode {
    NEWHOPE,
    EMPIRE,
    JEDI
}

public type Review record {|
    Episode episode;
    int stars;
    string commentary?;
|};

public type ReviewInput record {|
    int stars;
    string commentary?;
|};

@graphql:ServiceConfig {
    graphiql: {
        enabled: true
    }
}
service /graphql on new graphql:Listener(9090) {
    private final pubsub:PubSub pubsub = new;

    # Fetch the hero of the Star Wars
    # + return - The hero
    resource function get hero(Episode? episode) returns Character {
        if episode == EMPIRE {
            return new Human(ds:humanTable.get("1000"));
        }
        return new Droid(ds:droidTable.get("2001"));
    }

    # Returns reviews of the Star Wars
    # + return - The reviews
    resource function get reviews(Episode episode) returns Review?[] {
        return ds:getReviews(episode);
    }

    # Returns characters by id, or null if character is not found
    # + return - The characters
    resource function get characters(string[] idList) returns Character?[] {
        Character?[] characters = [];
        foreach string id in idList {
            if ds:humanTable.hasKey(id) {
                characters.push(new Human(ds:humanTable.get(id)));
            } else if ds:droidTable.hasKey(id) {
                characters.push(new Droid(ds:droidTable.get(id)));
            } else {
                characters.push(());
            }
        }
        return characters;
    }

    # Returns a droid by id, or null if droid is not found
    # + return - The Droid
    resource function get droid(string id = "2000") returns Droid? {
        if ds:droidTable.hasKey(id) {
            return new Droid(ds:droidTable.get(id));
        }
        return;
    }

    # Returns a human by id, or null if human is not found
    # + return - The Human
    resource function get human(string id) returns Human? {
        if ds:humanTable.hasKey(id) {
            return new Human(ds:humanTable.get(id));
        }
        return;
    }

    # Returns a starship by id, or null if starship is not found
    # + return - The Starship
    resource function get starship(string id) returns Starship? {
        if ds:starshipTable.hasKey(id) {
            return new Starship(ds:starshipTable.get(id));
        }
        return;
    }

    # Returns search results by text, or null if search item is not found
    # + return - The SearchResult
    resource function get search(string text) returns SearchResult[]? {
        SearchResult[] searchResult = [];
        if text.includes("human") {
            ds:HumanRecord[] humans = from var human in ds:humanTable
                select human;
            foreach ds:HumanRecord human in humans {
                searchResult.push(new Human(human));
            }
        }
        if text.includes("droid") {
            ds:DroidRecord[] droids = from var droid in ds:droidTable
                select droid;
            foreach ds:DroidRecord droid in droids {
                searchResult.push(new Droid(droid));
            }
        }
        if text.includes("starship") {
            ds:StarshipRecord[] starships = from var ship in ds:starshipTable
                select ship;
            foreach ds:StarshipRecord ship in starships {
                searchResult.push(new Starship(ship));
            }
        }
        if searchResult.length() > 0 {
            return searchResult;
        }
        return;
    }

    # Add new reviews and return the review values
    # + episode - Episode name
    # + reviewInput - Review of the episode
    # + return - The reviews
    remote function createReview(Episode episode, ReviewInput reviewInput) returns Review|error {
        ds:ReviewRecord newReview = {episode, ...reviewInput};
        ds:updateReviews(newReview);
        string topic = string `reviews-${episode}`;
        check self.pubsub.publish(topic, newReview, timeout = 5);
        return {...newReview};
    }

    # Subscribe to review updates
    # + episode - Episode name
    # + return - The reviews
    resource function subscribe reviewAdded(Episode episode) returns stream<Review, error?>|error {
        string topic = string `reviews-${episode}`;
        return self.pubsub.subscribe(topic, timeout = 5);
    }
}
