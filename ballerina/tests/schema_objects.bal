// Copyright (c) 2023, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

__Schema schemaWithDefaultDirectives = {
    types: [{kind: SCALAR}],
    queryType: {kind: OBJECT},
    directives: [
        {
            name: "include", 
            locations: [FIELD, FRAGMENT_SPREAD, INLINE_FRAGMENT],
            args: [
                {
                    name: "if",
                    'type: {
                        kind: NON_NULL,
                        ofType: {
                            kind: SCALAR,
                            name: "Boolean"
                        }
                    }
                }
            ]
        },
        {
            name: "skip", 
            locations: [FIELD, FRAGMENT_SPREAD, INLINE_FRAGMENT],
            args: [
                {
                    name: "if",
                    'type: {
                        kind: NON_NULL,
                        ofType: {
                            kind: SCALAR,
                            name: "Boolean"
                        }
                    }
                }
            ]
        },
        {
            name: "deprecated", 
            locations: [FIELD_DEFINITION, ENUM_VALUE],
            args: [
                {
                    name: "reason",
                    'type: {
                        kind: SCALAR,
                        name: "String"
                    }
                }
            ]
        }
    ]
};

__Schema schemaWithInputValues = {
    queryType: {kind: OBJECT},
    "types": [
        {
            "kind": "OBJECT",
            "name": "__Field",
            "fields": [
            {
                "name": "name",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "description",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "args",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "type",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "isDeprecated",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "deprecationReason",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            }
            ]
        },
        {
            "kind": "ENUM",
            "name": "__TypeKind",
            "fields": null
        },
        {
            "kind": "OBJECT",
            "name": "Query",
            "fields": [
            {
                "name": "greet",
                "type": {
                "kind": "NON_NULL"
                },
                "args": [
                {
                    "name": "name",
                    "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "String",
                        "ofType": null
                    }
                    },
                    "defaultValue": null
                }
                ]
            },
            {
                "name": "isLegal",
                "type": {
                "kind": "NON_NULL"
                },
                "args": [
                {
                    "name": "age",
                    "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "Int",
                        "ofType": null
                    }
                    },
                    "defaultValue": null
                }
                ]
            },
            {
                "name": "quote",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "quoteById",
                "type": {
                "kind": "SCALAR"
                },
                "args": [
                {
                    "name": "id",
                    "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "Int",
                        "ofType": null
                    }
                    },
                    "defaultValue": "\"\""
                }
                ]
            },
            {
                "name": "weightInPounds",
                "type": {
                "kind": "NON_NULL"
                },
                "args": [
                {
                    "name": "weightInKg",
                    "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "Float",
                        "ofType": null
                    }
                    },
                    "defaultValue": null
                }
                ]
            },
            {
                "name": "isHoliday",
                "type": {
                "kind": "NON_NULL"
                },
                "args": [
                {
                    "name": "weekday",
                    "type": {
                    "kind": "ENUM",
                    "name": "Weekday",
                    "ofType": null
                    },
                    "defaultValue": null
                }
                ]
            },
            {
                "name": "getDay",
                "type": {
                "kind": "NON_NULL"
                },
                "args": [
                {
                    "name": "isHoliday",
                    "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "Boolean",
                        "ofType": null
                    }
                    },
                    "defaultValue": null
                }
                ]
            }
            ]
        },
        {
            "kind": "OBJECT",
            "name": "__Schema",
            "fields": [
            {
                "name": "description",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "types",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "queryType",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "mutationType",
                "type": {
                "kind": "OBJECT"
                },
                "args": []
            },
            {
                "name": "subscriptionType",
                "type": {
                "kind": "OBJECT"
                },
                "args": []
            },
            {
                "name": "directives",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            }
            ]
        },
        {
            "kind": "OBJECT",
            "name": "__Type",
            "fields": [
            {
                "name": "kind",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "name",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "description",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "fields",
                "type": {
                "kind": "LIST"
                },
                "args": [
                {
                    "name": "includeDeprecated",
                    "type": {
                    "kind": "SCALAR",
                    "name": "Boolean",
                    "ofType": null
                    },
                    "defaultValue": "false"
                }
                ]
            },
            {
                "name": "interfaces",
                "type": {
                "kind": "LIST"
                },
                "args": []
            },
            {
                "name": "possibleTypes",
                "type": {
                "kind": "LIST"
                },
                "args": []
            },
            {
                "name": "enumValues",
                "type": {
                "kind": "LIST"
                },
                "args": [
                {
                    "name": "includeDeprecated",
                    "type": {
                    "kind": "SCALAR",
                    "name": "Boolean",
                    "ofType": null
                    },
                    "defaultValue": "false"
                }
                ]
            },
            {
                "name": "inputFields",
                "type": {
                "kind": "LIST"
                },
                "args": []
            },
            {
                "name": "ofType",
                "type": {
                "kind": "OBJECT"
                },
                "args": []
            }
            ]
        },
        {
            "kind": "OBJECT",
            "name": "__EnumValue",
            "fields": [
            {
                "name": "name",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "description",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "isDeprecated",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "deprecationReason",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            }
            ]
        },
        {
            "kind": "ENUM",
            "name": "__DirectiveLocation",
            "fields": null
        },
        {
            "kind": "SCALAR",
            "name": "String",
            "fields": null
        },
        {
            "kind": "SCALAR",
            "name": "Int",
            "fields": null
        },
        {
            "kind": "SCALAR",
            "name": "Float",
            "fields": null
        },
        {
            "kind": "ENUM",
            "name": "Weekday",
            "fields": null
        },
        {
            "kind": "OBJECT",
            "name": "__InputValue",
            "fields": [
            {
                "name": "name",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "description",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "type",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "defaultValue",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            }
            ]
        },
        {
            "kind": "SCALAR",
            "name": "Boolean",
            "fields": null
        },
        {
            "kind": "OBJECT",
            "name": "__Directive",
            "fields": [
            {
                "name": "name",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "description",
                "type": {
                "kind": "SCALAR"
                },
                "args": []
            },
            {
                "name": "locations",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            },
            {
                "name": "args",
                "type": {
                "kind": "NON_NULL"
                },
                "args": []
            }
            ]
        }
        ],
        "directives": [
        {
            "name": "include",
            "locations": [
            "FIELD",
            "FRAGMENT_SPREAD",
            "INLINE_FRAGMENT"
            ],
            "args": [
            {
                "name": "if",
                "type": {
                "kind": "NON_NULL",
                "ofType": {
                    "name": "Boolean",
                    "kind": "SCALAR"
                }
                }
            }
            ]
        },
        {
            "name": "skip",
            "locations": [
            "FIELD",
            "FRAGMENT_SPREAD",
            "INLINE_FRAGMENT"
            ],
            "args": [
            {
                "name": "if",
                "type": {
                "kind": "NON_NULL",
                "ofType": {
                    "name": "Boolean",
                    "kind": "SCALAR"
                }
                }
            }
            ]
        },
        {
            "name": "deprecated",
            "locations": [
            "FIELD_DEFINITION",
            "ENUM_VALUE"
            ],
            "args": [
            {
                "name": "reason",
                "type": {
                "kind": "SCALAR",
                "ofType": null
                }
            }
            ]
        }
    ]
};
