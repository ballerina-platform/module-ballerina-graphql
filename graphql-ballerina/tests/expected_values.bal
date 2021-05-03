// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

json hierarchicalResourcePathIntrospectionResult = {
    "data": {
        "__schema": {
            "types": [
                {
                    "name": "__TypeKind",
                    "fields": null
                },
                {
                    "name": "__Field",
                    "fields": [
                        {
                            "name": "args"
                        },
                        {
                            "name": "name"
                        },
                        {
                            "name": "type"
                        }
                    ]
                },
                {
                    "name": "Query",
                    "fields": [
                        {
                            "name": "profile"
                        }
                    ]
                },
                {
                    "name": "__Schema",
                    "fields": [
                        {
                            "name": "types"
                        }
                    ]
                },
                {
                    "name": "__Type",
                    "fields": [
                        {
                            "name": "possibleTypes"
                        },
                        {
                            "name": "kind"
                        },
                        {
                            "name": "name"
                        },
                        {
                            "name": "fields"
                        },
                        {
                            "name": "ofType"
                        },
                        {
                            "name": "enumValues"
                        }
                    ]
                },
                {
                    "name": "__EnumValue",
                    "fields": [
                        {
                            "name": "name"
                        }
                    ]
                },
                {
                    "name": "profile",
                    "fields": [
                        {
                            "name": "name"
                        },
                        {
                            "name": "age"
                        }
                    ]
                },
                {
                    "name": "name",
                    "fields": [
                        {
                            "name": "last"
                        },
                        {
                            "name": "first"
                        }
                    ]
                },
                {
                    "name": "String",
                    "fields": null
                },
                {
                    "name": "__InputValue",
                    "fields": [
                        {
                            "name": "defaultValue"
                        },
                        {
                            "name": "name"
                        },
                        {
                            "name": "type"
                        }
                    ]
                },
                {
                    "name": "Int",
                    "fields": null
                }
            ]
        }
    }
};

json enumTypeInspectionResult = {
    "data": {
        "__schema": {
            "types": [
                {
                    "name": "Weekday",
                    "enumValues": [
                        {
                            "name": "SATURDAY"
                        },
                        {
                            "name": "FRIDAY"
                        },
                        {
                            "name": "THURSDAY"
                        },
                        {
                            "name": "WEDNESDAY"
                        },
                        {
                            "name": "TUESDAY"
                        },
                        {
                            "name": "MONDAY"
                        },
                        {
                            "name": "SUNDAY"
                        }
                    ]
                },
                {
                    "name": "__TypeKind",
                    "enumValues": [
                        {
                            "name": "UNION"
                        },
                        {
                            "name": "LIST"
                        },
                        {
                            "name": "NON_NULL"
                        },
                        {
                            "name": "ENUM"
                        },
                        {
                            "name": "OBJECT"
                        },
                        {
                            "name": "SCALAR"
                        }
                    ]
                },
                {
                    "name": "__Field",
                    "enumValues": null
                },
                {
                    "name": "Query",
                    "enumValues": null
                },
                {
                    "name": "__Schema",
                    "enumValues": null
                },
                {
                    "name": "__Type",
                    "enumValues": null
                },
                {
                    "name": "__EnumValue",
                    "enumValues": null
                },
                {
                    "name": "Time",
                    "enumValues": null
                },
                {
                    "name": "String",
                    "enumValues": null
                },
                {
                    "name": "__InputValue",
                    "enumValues": null
                },
                {
                    "name": "Int",
                    "enumValues": null
                }
            ]
        }
    }
};
