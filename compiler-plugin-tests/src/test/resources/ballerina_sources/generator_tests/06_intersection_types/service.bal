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

# Represents a movie.
#
# + name - Name of the movie
# + director - Name of the director of the movie
# + year - Release year of the movie
type Movie readonly & record {
    string name;
    string director;
    int year;
};

# Represents an album.
#
# + name - Name of the album
# + artist - Name of the artist of the album
# + year - Release year of the album
type Album record {
    string name;
    string artist;
    int year;
};

isolated service on new graphql:Listener(9000) {
    isolated resource function get movie() returns Movie {
        return {name: "Inception", director: "Christopher Nolan", year: 2010};
    }

    isolated resource function get readOnlyProfile() returns Album & readonly {
        return {name: "Toxicity", artist: "System of a Down", year: 2001}.cloneReadOnly();
    }
}
