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

public enum Episode {
    NEWHOPE,
    EMPIRE,
    JEDI
}

public type Review record {
    Episode episode?;
    int stars;
    string commentary?;
};

public type ReviewInput record {
    int stars;
    string commentary;
};

# A mechanical character from the Star Wars universe
public type Character distinct service object {

    # The unique identifier of the character
    # + return - The id
    resource function get id() returns string;

    # The name of the character
    # + return - The name
    resource function get name() returns string;

    # The episodes this character appears in
    # + return - The episodes
    resource function get appearsIn() returns Episode[];
};

# A humanoid creature from the Star Wars universe
distinct service class Human {
    *Character;

    # The unique identifier of the human
    # + return - The id
    resource function get id() returns string {
        return "";
    }

    # The name of the human
    # + return - The name
    resource function get name() returns string {
        return "";
    }

    # The home planet of the human, or null if unknown
    # + return - The homePlanet
    resource function get homePlanet() returns string? {
        return;
    }

    # Height in meters, or null if unknown
    # + return - The height
    resource function get height() returns float? {
        return ;
    }

    # Mass in kilograms, or null if unknown
    # + return - The mass
    resource function get mass() returns int? {
        return ;
    }

    # The episodes this human appears in
    # + return - The episodes
    resource function get appearsIn() returns Episode[] {
        return [JEDI];
    }
}

service /graphql on new graphql:Listener(9000) {

    # Fetch the hero of the Star Wars
    # + return - The hero
    resource function get hero(Episode? episode) returns Character {
        return new Human();
    }

    # Returns reviews of the Star Wars
    # + return - The reviews
    resource function get reviews(Episode episode = JEDI) returns Review?[] {
        return [];
    }

    # Returns characters by id, or null if character is not found
    # + return - The characters
    resource function get characters(string[] idList) returns Character?[] {
        Character[] characters = [new Human()];
        return characters;
    }

    # Returns a human by id, or null if human is not found
    # + return - The Human
    resource function get human(string id) returns Human? {
        if id.includes("human") {
            return new Human();
        }
        return;
    }

    # Add new reviews and return the review values
    #
    # + episode - Episode name
    # + reviewInput - Review of the episode
    # + return - The reviews
    remote function createReview(Episode episode, ReviewInput reviewInput) returns Review {
        Review review = {
            stars: reviewInput.stars
        };
        return review;
    }
}
