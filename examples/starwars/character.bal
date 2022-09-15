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

# A mechanical character from the Star Wars universe
public type Character distinct service object {

    # The unique identifier of the character
    # + return - The id
    resource function get id() returns string;

    # The name of the character
    # + return - The name
    resource function get name() returns string;

    # This character's friends, or an empty list if they have none
    # + return - The friends
    resource function get friends() returns Character[];

    # The episodes this character appears in
    # + return - The episodes
    resource function get appearsIn() returns Episode[];
};
