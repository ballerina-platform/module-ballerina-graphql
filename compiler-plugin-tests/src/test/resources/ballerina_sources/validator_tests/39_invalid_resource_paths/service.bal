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

type Status record {
    int capacity;
    int __elevationgain;
    boolean night;
};

type Lift record {
    string __id;
    Status getStatus;
};

service class Trail {

    resource function get id() returns string {
        return "T1";
    }

    resource function get __name() returns string {
        return "Trail1";
    }
}

service /graphql on new graphql:Listener(4000) {
    resource function get __liftCount() returns int{
        return 3;
    }

    resource function get trailCount() returns int {
        return 3;
    }

    resource function get lift() returns Lift {
        return {
            __id:"L1",
            getStatus: {
                capacity:10,
                __elevationgain:20,
                night:false
            }
        };
    }

    resource function get mountain/name/__first() returns string {
        return "MountainFirst";
    }

    resource function get mountain/__name/last() returns string {
        return "MountainLast";
    }

    resource function get __mountain/id() returns string {
        return "M1";
    }

    resource function get mountain/getTrail() returns Trail {
        return new;
    }

    remote function __addTrail() returns string {
        return "added";
    }
}
