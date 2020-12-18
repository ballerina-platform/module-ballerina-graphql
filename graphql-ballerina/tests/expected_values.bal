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

__Schema expectedSchemaForMultipleResources = {
    "types": {
        "__TypeKind": {
            kind: "ENUM",
            name: "__TypeKind",
            "enumValues": {
                "SCALAR": "SCALAR",
                "OBJECT": "OBJECT",
                "ENUM": "ENUM"
            }
        },
        "__Field": {
            kind: "OBJECT",
            name: "__Field",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "args": {
                    name: "args",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                }
            }
        },
        "String": {
            kind: "SCALAR",
            name: "String"
        },
        "Query": {
            kind: "OBJECT",
            name: "Query",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "String"
                    }
                },
                "id": {
                    name: "id",
                    'type: {
                        kind: "SCALAR",
                        name: "Int"
                    }
                },
                "birthdate": {
                    name: "birthdate",
                    'type: {
                        kind: "SCALAR",
                        name: "String"
                    },
                    "args": {
                        "format": {
                            name: "format",
                            'type: {
                                kind: "SCALAR",
                                name: "String"
                            }
                        }
                    }
                }
            }
        },
        "__Type": {
            kind: "OBJECT",
            name: "__Type",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                kind: {
                    name: "kind",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                fields: {
                    name: "fields",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "enumValues": {
                    name: "enumValues",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                }
            }
        },
        "__InputValue": {
            kind: "OBJECT",
            name: "__InputValue",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "defaultValue": {
                    name: "defaultValue",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                }
            }
        },
        "Int": {
            kind: "SCALAR",
            name: "Int"
        }
    },
    queryType: {
        kind: "OBJECT",
        name: "Query",
        fields: {
            "name": {
                name: "name",
                'type: {
                    kind: "SCALAR",
                    name: "String"
                }
            },
            "id": {
                name: "id",
                'type: {
                    kind: "SCALAR",
                    name: "Int"
                }
            },
            "birthdate": {
                name: "birthdate",
                'type: {
                    kind: "SCALAR",
                    name: "String"
                },
                "args": {
                    "format": {
                        name: "format",
                        'type: {
                            kind: "SCALAR",
                            name: "String"
                        }
                    }
                }
            }
        }
    }
};

__Schema expectedSchemaForResourcesReturningRecords = {
    "types": {
        "__TypeKind": {
            kind: "ENUM",
            name: "__TypeKind",
            "enumValues": {
                "SCALAR": "SCALAR",
                "OBJECT": "OBJECT",
                "ENUM": "ENUM"
            }
        },
        "__Field": {
            kind: "OBJECT",
            name: "__Field",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "args": {
                    name: "args",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                }
            }
        },
        "String": {
            kind: "SCALAR",
            name: "String"
        },
        "Address": {
            kind: "OBJECT",
            name: "Address",
            fields: {
                "number": {
                    name: "number",
                    'type: {
                        kind: "SCALAR",
                        name: "String"
                    }
                },
                "street": {
                    name: "street",
                    'type: {
                        kind: "SCALAR",
                        name: "String"
                    }
                },
                "city": {
                    name: "city",
                    'type: {
                        kind: "SCALAR",
                        name: "String"
                    }
                }
            }
        },
        "Query": {
            kind: "OBJECT",
            name: "Query",
            fields: {
                "person": {
                    name: "person",
                    'type: {
                        kind: "OBJECT",
                        name: "Person",
                        fields: {
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String"
                                }
                            },
                            "age": {
                                name: "age",
                                'type: {
                                    kind: "SCALAR",
                                    name: "Int"
                                }
                            },
                            "address": {
                                name: "address",
                                'type: {
                                    kind: "OBJECT",
                                    name: "Address",
                                    fields: {
                                        "number": {
                                            name: "number",
                                            'type: {
                                                kind: "SCALAR",
                                                name: "String"
                                            }
                                        },
                                        "street": {
                                            name: "street",
                                            'type: {
                                                kind: "SCALAR",
                                                name: "String"
                                            }
                                        },
                                        "city": {
                                            name: "city",
                                            'type: {
                                                kind: "SCALAR",
                                                name: "String"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        "__Type": {
            kind: "OBJECT",
            name: "__Type",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                kind: {
                    name: "kind",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                fields: {
                    name: "fields",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                enumValues: {
                    name: "enumValues",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                }
            }
        },
        "__InputValue": {
            kind: "OBJECT",
            name: "__InputValue",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                },
                "defaultValue": {
                    name: "defaultValue",
                    'type: {
                        kind: "NON_NULL",
                        name: ()
                    }
                }
            }
        },
        "Person": {
            kind: "OBJECT",
            name: "Person",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "String"
                    }
                },
                "age": {
                    name: "age",
                    'type: {
                        kind: "SCALAR",
                        name: "Int"
                    }
                },
                "address": {
                    name: "address",
                    'type: {
                        kind: "OBJECT",
                        name: "Address",
                        fields: {
                            "number": {
                                name: "number",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String"
                                }
                            },
                            "street": {
                                name: "street",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String"
                                }
                            },
                            "city": {
                                name: "city",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String"
                                }
                            }
                        }
                    }
                }
            }
        },
        "Int": {
            kind: "SCALAR",
            name: "Int"
        }
    },
    queryType: {
        kind: "OBJECT",
        name: "Query",
        fields: {
            "person": {
                name: "person",
                'type: {
                    kind: "OBJECT",
                    name: "Person",
                    fields: {
                        "name": {
                            name: "name",
                            'type: {
                                kind: "SCALAR",
                                name: "String"
                            }
                        },
                        "age": {
                            name: "age",
                            'type: {
                                kind: "SCALAR",
                                name: "Int"
                            }
                        },
                        "address": {
                            name: "address",
                            'type: {
                                kind: "OBJECT",
                                name: "Address",
                                fields: {
                                    "number": {
                                        name: "number",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "String"
                                        }
                                    },
                                    "street": {
                                        name: "street",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "String"
                                        }
                                    },
                                    "city": {
                                        name: "city",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "String"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
};
