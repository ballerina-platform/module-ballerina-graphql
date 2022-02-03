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

public enum EpisodeEnum {
    NEWHOPE,
    EMPIRE,
    JEDI
}

public type HumanRecord readonly & record {|
    string id;
    string name;
    string homePlanet?;
    float height?;
    int mass?;
    EpisodeEnum[] appearsIn;
|};

public type DroidRecord readonly & record {|
    string id;
    string name;
    EpisodeEnum[] appearsIn;
    string primaryFunction?;
|};

public type StarshipRecord readonly & record {|
    string id;
    string name;
    float length?;
    float[][] cordinates?;
|};

public type ReviewRecord readonly & record {|
    EpisodeEnum episode;
    int stars;
    string commentary?;
|};

public type FriendsEdgeRecord readonly & record {|
    string characterId;
    string friendId;
|};

public type StarshipEdgeRecord readonly & record {|
    string characterId;
    string starshipId;
|};
