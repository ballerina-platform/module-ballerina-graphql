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
    types: {
        "int": {
            kind: "SCALAR",
            name: "int",
            fields: {}
        },
        "__Field": {
            kind: "OBJECT",
            name: "__Field",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "OBJECT",
                        name: "__Type",
                        fields: {
                            "kind": {
                                name: "kind",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            fields: {
                                name: "fields",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "args": {
                    name: "args",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "returnType": {
                    name: "returnType",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "__Schema": {
            kind: "OBJECT",
            name: "__Schema",
            fields: {
                "types": {
                    name: "types",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "queryType": {
                    name: "queryType",
                    'type: {
                        kind: "OBJECT",
                        name: "__Type",
                        fields: {
                            "kind": {
                                name: "kind",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            fields: {
                                name: "fields",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "Query": {
            kind: "OBJECT",
            name: "Query",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "PRIMITIVE"
                },
                "id": {
                    name: "id",
                    'type: {
                        kind: "SCALAR",
                        name: "int",
                        fields: {}
                    },
                    args: {},
                    returnType: "PRIMITIVE"
                },
                "birthdate": {
                    name: "birthdate",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {
                        "format": {
                            name: "format",
                            'type: {
                                kind: "SCALAR",
                                name: "string",
                                fields: {}
                            }
                        }
                    },
                    returnType: "PRIMITIVE"
                }
            }
        },
        "__Type": {
            kind: "OBJECT",
            name: "__Type",
            fields: {
                "kind": {
                    name: "kind",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                fields: {
                    name: "fields",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "string": {
            kind: "SCALAR",
            name: "string",
            fields: {}
        },
        "__InputValue": {
            kind: "OBJECT",
            name: "__InputValue",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "OBJECT",
                        name: "__Type",
                        fields: {
                            "kind": {
                                name: "kind",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            fields: {
                                name: "fields",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "defaultValue": {
                    name: "defaultValue",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        }
    },
    "queryType": {
        kind: "OBJECT",
        name: "Query",
        fields: {
            "name": {
                name: "name",
                'type: {
                    kind: "SCALAR",
                    name: "string",
                    fields: {}
                },
                args: {},
                returnType: "PRIMITIVE"
            },
            "id": {
                name: "id",
                'type: {
                    kind: "SCALAR",
                    name: "int",
                    fields: {}
                },
                args: {},
                returnType: "PRIMITIVE"
            },
            "birthdate": {
                name: "birthdate",
                'type: {
                    kind: "SCALAR",
                    name: "string",
                    fields: {}
                },
                args: {
                    "format": {
                        name: "format",
                        'type: {
                            kind: "SCALAR",
                            name: "string",
                            fields: {}
                        }
                    }
                },
                returnType: "PRIMITIVE"
            }
        }
    }
};

__Schema expectedSchemaForResourcesReturningRecords = {
    types: {
        "int": {
            kind: "SCALAR",
            name: "int",
            fields: {}
        },
        "__Field": {
            kind: "OBJECT",
            name: "__Field",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "OBJECT",
                        name: "__Type",
                        fields: {
                            "kind": {
                                name: "kind",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            fields: {
                                name: "fields",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "args": {
                    name: "args",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "returnType": {
                    name: "returnType",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "__Schema": {
            kind: "OBJECT",
            name: "__Schema",
            fields: {
                "types": {
                    name: "types",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "queryType": {
                    name: "queryType",
                    'type: {
                        kind: "OBJECT",
                        name: "__Type",
                        fields: {
                            "kind": {
                                name: "kind",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            fields: {
                                name: "fields",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "Address": {
            kind: "OBJECT",
            name: "Address",
            fields: {
                "number": {
                    name: "number",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "street": {
                    name: "street",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "city": {
                    name: "city",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
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
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "age": {
                                name: "age",
                                'type: {
                                    kind: "SCALAR",
                                    name: "int",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
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
                                                name: "string",
                                                fields: {}
                                            },
                                            args: {},
                                            returnType: "RECORD"
                                        },
                                        "street": {
                                            name: "street",
                                            'type: {
                                                kind: "SCALAR",
                                                name: "string",
                                                fields: {}
                                            },
                                            args: {},
                                            returnType: "RECORD"
                                        },
                                        "city": {
                                            name: "city",
                                            'type: {
                                                kind: "SCALAR",
                                                name: "string",
                                                fields: {}
                                            },
                                            args: {},
                                            returnType: "RECORD"
                                        }
                                    }
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "__Type": {
            kind: "OBJECT",
            name: "__Type",
            fields: {
                "kind": {
                    name: "kind",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                fields: {
                    name: "fields",
                    'type: {
                        kind: "SCALAR",
                        name: "id",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        },
        "string": {
            kind: "SCALAR",
            name: "string",
            fields: {}
        },
        "__InputValue": {
            kind: "OBJECT",
            name: "__InputValue",
            fields: {
                "name": {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "type": {
                    name: "type",
                    'type: {
                        kind: "OBJECT",
                        name: "__Type",
                        fields: {
                            "kind": {
                                name: "kind",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "name": {
                                name: "name",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            fields: {
                                name: "fields",
                                'type: {
                                    kind: "SCALAR",
                                    name: "id",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "defaultValue": {
                    name: "defaultValue",
                    'type: {
                        kind: "SCALAR",
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
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
                        name: "string",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
                },
                "age": {
                    name: "age",
                    'type: {
                        kind: "SCALAR",
                        name: "int",
                        fields: {}
                    },
                    args: {},
                    returnType: "RECORD"
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
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "street": {
                                name: "street",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            },
                            "city": {
                                name: "city",
                                'type: {
                                    kind: "SCALAR",
                                    name: "string",
                                    fields: {}
                                },
                                args: {},
                                returnType: "RECORD"
                            }
                        }
                    },
                    args: {},
                    returnType: "RECORD"
                }
            }
        }
    },
    "queryType": {
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
                                name: "string",
                                fields: {}
                            },
                            args: {},
                            returnType: "RECORD"
                        },
                        "age": {
                            name: "age",
                            'type: {
                                kind: "SCALAR",
                                name: "int",
                                fields: {}
                            },
                            args: {},
                            returnType: "RECORD"
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
                                            name: "string",
                                            fields: {}
                                        },
                                        args: {},
                                        returnType: "RECORD"
                                    },
                                    "street": {
                                        name: "street",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "string",
                                            fields: {}
                                        },
                                        args: {},
                                        returnType: "RECORD"
                                    },
                                    "city": {
                                        name: "city",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "string",
                                            fields: {}
                                        },
                                        args: {},
                                        returnType: "RECORD"
                                    }
                                }
                            },
                            args: {},
                            returnType: "RECORD"
                        }
                    }
                },
                args: {},
                returnType: "RECORD"
            }
        }
    }
};
