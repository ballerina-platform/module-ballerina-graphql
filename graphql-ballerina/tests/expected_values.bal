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

json expectedSchemaForMultipleResources = {
    "types": {
        "__TypeKind": {
            "kind": "ENUM",
            "name": "__TypeKind",
            "enumValues": [
                {
                    "name": "SCALAR"
                },
                {
                    "name": "OBJECT"
                },
                {
                    "name": "ENUM"
                },
                {
                    "name": "NON_NULL"
                },
                {
                    "name": "LIST"
                },
                {
                    "name": "UNION"
                }
            ]
        },
        "__Field": {
            "kind": "OBJECT",
            "name": "__Field",
            "fields": [
                {
                    "name": "args",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            ]
        },
        "Query": {
            "kind": "OBJECT",
            "name": "Query",
            "fields": [
                {
                    "name": "birthdate",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "id",
                    "type": {
                        "kind": "SCALAR",
                        "name": "Int"
                    }
                }
            ]
        },
        "__Type": {
            "kind": "OBJECT",
            "name": "__Type",
            "fields": [
                {
                    "name": "kind",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "fields",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "enumValues",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            ]
        },
        "String": {
            "kind": "SCALAR",
            "name": "String"
        },
        "__InputValue": {
            "kind": "OBJECT",
            "name": "__InputValue",
            "fields": [
                {
                    "name": "defaultValue",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            ]
        },
        "Int": {
            "kind": "SCALAR",
            "name": "Int"
        }
    },
    "queryType": {
        "kind": "OBJECT",
        "name": "Query",
        "fields": [
            {
                "name": "birthdate",
                "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                "args": {
                    "format": {
                        "name": "format",
                        "type": {
                            "kind": "NON_NULL",
                            "name": null,
                            "ofType": {
                                "kind": "SCALAR",
                                "name": "String"
                            }
                        }
                    }
                }
            },
            {
                "name": "name",
                "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                }
            },
            {
                "name": "id",
                "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "Int"
                    }
                }
            }
        ]
    }
};

json expectedSchemaForResourcesReturningRecords = {
    "types": {
        "__TypeKind": {
            "kind": "ENUM",
            "name": "__TypeKind",
            "enumValues": [
                {
                    "name": "SCALAR"
                },
                {
                    "name": "OBJECT"
                },
                {
                    "name": "ENUM"
                },
                {
                    "name": "NON_NULL"
                },
                {
                    "name": "LIST"
                },
                {
                    "name": "UNION"
                }
            ]
        },
        "__Field": {
            "kind": "OBJECT",
            "name": "__Field",
            "fields": [
                {
                    "name": "args",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            ]
        },
        "Query": {
            "kind": "OBJECT",
            "name": "Query",
            "fields": [
                {
                    "name": "person",
                    "type": {
                        "kind": "OBJECT",
                        "name": "Person",
                        "fields": [
                            {
                                "name": "address",
                                "type": {
                                    "kind": "OBJECT",
                                    "name": "Address",
                                    "fields": [
                                        {
                                            "name": "number",
                                            "type": {
                                                "kind": "SCALAR",
                                                "name": "String"
                                            }
                                        },
                                        {
                                            "name": "city",
                                            "type": {
                                                "kind": "SCALAR",
                                                "name": "String"
                                            }
                                        },
                                        {
                                            "name": "street",
                                            "type": {
                                                "kind": "SCALAR",
                                                "name": "String"
                                            }
                                        }
                                    ]
                                }
                            },
                            {
                                "name": "name",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            },
                            {
                                "name": "age",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "Int"
                                }
                            }
                        ]
                    }
                }
            ]
        },
        "Address": {
            "kind": "OBJECT",
            "name": "Address",
            "fields": [
                {
                    "name": "number",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "city",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "street",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                }
            ]
        },
        "__Type": {
            "kind": "OBJECT",
            "name": "__Type",
            "fields": [
                {
                    "name": "kind",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "fields",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "enumValues",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            ]
        },
        "String": {
            "kind": "SCALAR",
            "name": "String"
        },
        "__InputValue": {
            "kind": "OBJECT",
            "name": "__InputValue",
            "fields": [
                {
                    "name": "defaultValue",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            ]
        },
        "Person": {
            "kind": "OBJECT",
            "name": "Person",
            "fields": [
                {
                    "name": "address",
                    "type": {
                        "kind": "OBJECT",
                        "name": "Address",
                        "fields": [
                            {
                                "name": "number",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            },
                            {
                                "name": "city",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            },
                            {
                                "name": "street",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            }
                        ]
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "age",
                    "type": {
                        "kind": "SCALAR",
                        "name": "Int"
                    }
                }
            ]
        },
        "Int": {
            "kind": "SCALAR",
            "name": "Int"
        }
    },
    "queryType": {
        "kind": "OBJECT",
        "name": "Query",
        "fields": [
            {
                "name": "person",
                "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "OBJECT",
                        "name": "Person",
                        "fields": [
                            {
                                "name": "address",
                                "type": {
                                    "kind": "NON_NULL",
                                    "name": null,
                                    "ofType": {
                                        "kind": "OBJECT",
                                        "name": "Address",
                                        "fields": [
                                            {
                                                "name": "number",
                                                "type": {
                                                    "kind": "NON_NULL",
                                                    "name": null,
                                                    "ofType": {
                                                        "kind": "SCALAR",
                                                        "name": "String"
                                                    }
                                                }
                                            },
                                            {
                                                "name": "city",
                                                "type": {
                                                    "kind": "NON_NULL",
                                                    "name": null,
                                                    "ofType": {
                                                        "kind": "SCALAR",
                                                        "name": "String"
                                                    }
                                                }
                                            },
                                            {
                                                "name": "street",
                                                "type": {
                                                    "kind": "NON_NULL",
                                                    "name": null,
                                                    "ofType": {
                                                        "kind": "SCALAR",
                                                        "name": "String"
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                }
                            },
                            {
                                "name": "name",
                                "type": {
                                    "kind": "NON_NULL",
                                    "name": null,
                                    "ofType": {
                                        "kind": "SCALAR",
                                        "name": "String"
                                    }
                                }
                            },
                            {
                                "name": "age",
                                "type": {
                                    "kind": "NON_NULL",
                                    "name": null,
                                    "ofType": {
                                        "kind": "SCALAR",
                                        "name": "Int"
                                    }
                                }
                            }
                        ]
                    }
                }
            }
        ]
    }
};

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
                    "name": "__Type",
                    "fields": [
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
                            "name": "enumValues"
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
                },
                {
                    "name": "__Schema",
                    "fields": [
                        {
                            "name": "types"
                        }
                    ]
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
                            "name": "SCALAR"
                        },
                        {
                            "name": "OBJECT"
                        },
                        {
                            "name": "ENUM"
                        },
                        {
                            "name": "NON_NULL"
                        },
                        {
                            "name": "LIST"
                        },
                        {
                            "name": "UNION"
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
                    "name": "__Type",
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
                },
                {
                    "name": "__Schema",
                    "enumValues": null
                }
            ]
        }
    }
};
