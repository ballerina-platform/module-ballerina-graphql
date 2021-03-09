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
            "enumValues": {
                "SCALAR": "SCALAR",
                "OBJECT": "OBJECT",
                "ENUM": "ENUM"
            }
        },
        "__Field": {
            "kind": "OBJECT",
            "name": "__Field",
            "fields": {
                "args": {
                    "name": "args",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "type": {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            }
        },
        "Query": {
            "kind": "OBJECT",
            "name": "Query",
            "fields": {
                "String": {
                    "name": "String",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                "Int": {
                    "name": "Int",
                    "type": {
                        "kind": "SCALAR",
                        "name": "Int"
                    }
                }
            }
        },
        "__Type": {
            "kind": "OBJECT",
            "name": "__Type",
            "fields": {
                "fields": {
                    "name": "fields",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "enumValues": {
                    "name": "enumValues",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "kind": {
                    "name": "kind",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            }
        },
        "String": {
            "kind": "SCALAR",
            "name": "String"
        },
        "__InputValue": {
            "kind": "OBJECT",
            "name": "__InputValue",
            "fields": {
                "defaultValue": {
                    "name": "defaultValue",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "type": {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            }
        },
        "Int": {
            "kind": "SCALAR",
            "name": "Int"
        }
    },
    "queryType": {
        "kind": "OBJECT",
        "name": "Query",
        "fields": {
            "id": {
                "name": "id",
                "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "SCALAR",
                        "name": "Int"
                    }
                }
            },
            "birthdate": {
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
            "name": {
                "name": "name",
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
    }
};

json expectedSchemaForResourcesReturningRecords = {
    "types": {
        "__TypeKind": {
            "kind": "ENUM",
            "name": "__TypeKind",
            "enumValues": {
                "SCALAR": "SCALAR",
                "OBJECT": "OBJECT",
                "ENUM": "ENUM"
            }
        },
        "__Field": {
            "kind": "OBJECT",
            "name": "__Field",
            "fields": {
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "type": {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "args": {
                    "name": "args",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            }
        },
        "Query": {
            "kind": "OBJECT",
            "name": "Query",
            "fields": {
                "person": {
                    "name": "person",
                    "type": {
                        "kind": "OBJECT",
                        "name": "Person",
                        "fields": {
                            "name": {
                                "name": "name",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            },
                            "age": {
                                "name": "age",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "Int"
                                }
                            },
                            "address": {
                                "name": "address",
                                "type": {
                                    "kind": "OBJECT",
                                    "name": "Address",
                                    "fields": {
                                        "number": {
                                            "name": "number",
                                            "type": {
                                                "kind": "SCALAR",
                                                "name": "String"
                                            }
                                        },
                                        "street": {
                                            "name": "street",
                                            "type": {
                                                "kind": "SCALAR",
                                                "name": "String"
                                            }
                                        },
                                        "city": {
                                            "name": "city",
                                            "type": {
                                                "kind": "SCALAR",
                                                "name": "String"
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
        "Address": {
            "kind": "OBJECT",
            "name": "Address",
            "fields": {
                "number": {
                    "name": "number",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                "street": {
                    "name": "street",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                "city": {
                    "name": "city",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                }
            }
        },
        "__Type": {
            "kind": "OBJECT",
            "name": "__Type",
            "fields": {
                "fields": {
                    "name": "fields",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "kind": {
                    "name": "kind",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "enumValues": {
                    "name": "enumValues",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            }
        },
        "String": {
            "kind": "SCALAR",
            "name": "String"
        },
        "__InputValue": {
            "kind": "OBJECT",
            "name": "__InputValue",
            "fields": {
                "type": {
                    "name": "type",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "defaultValue": {
                    "name": "defaultValue",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                }
            }
        },
        "Person": {
            "kind": "OBJECT",
            "name": "Person",
            "fields": {
                "name": {
                    "name": "name",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                "age": {
                    "name": "age",
                    "type": {
                        "kind": "SCALAR",
                        "name": "Int"
                    }
                },
                "address": {
                    "name": "address",
                    "type": {
                        "kind": "OBJECT",
                        "name": "Address",
                        "fields": {
                            "number": {
                                "name": "number",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            },
                            "street": {
                                "name": "street",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            },
                            "city": {
                                "name": "city",
                                "type": {
                                    "kind": "SCALAR",
                                    "name": "String"
                                }
                            }
                        }
                    }
                }
            }
        },
        "Int": {
            "kind": "SCALAR",
            "name": "Int"
        }
    },
    "queryType": {
        "kind": "OBJECT",
        "name": "Query",
        "fields": {
            "person": {
                "name": "person",
                "type": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                        "kind": "OBJECT",
                        "name": "Person",
                        "fields": {
                            "name": {
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
                            "address": {
                                "name": "address",
                                "type": {
                                    "kind": "NON_NULL",
                                    "name": null,
                                    "ofType": {
                                        "kind": "OBJECT",
                                        "name": "Address",
                                        "fields": {
                                            "number": {
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
                                            "street": {
                                                "name": "street",
                                                "type": {
                                                    "kind": "NON_NULL",
                                                    "name": null,
                                                    "ofType": {
                                                        "kind": "SCALAR",
                                                        "name": "String"
                                                    }
                                                }
                                            },
                                            "city": {
                                                "name": "city",
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
                                    }
                                }
                            },
                            "age": {
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
                        }
                    }
                }
            }
        }
    }
};
