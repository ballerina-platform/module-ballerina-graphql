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

Operation shorthandOperation = {
    name: ANONYMOUS_OPERATION,
    'type: QUERY,
    fields: [
        {
            name: "name",
            location: {
                line: 2,
                column: 5
            }
        },
        {
            name: "birthdate",
            location: {
                line: 3,
                column: 5
            }
        }
    ],
    location: {
        line: 1,
        column: 1
    }
};

Operation namedOperation = {
    name: "getData",
    'type: QUERY,
    fields: [
        {
            name: "name",
            location: {
                line: 2,
                column: 5
            }
        },
        {
            name: "id",
            location: {
                line: 3,
                column: 5
            }
        },
        {
            name: "birthdate",
            location: {
                line: 4,
                column: 5
            }
        }
    ],
    location: {
        line: 1,
        column: 7
    }
};

Document expectedDocumentWithParameters =
{
    operations: [
        {
            name: "getData",
            'type: "query",
            fields: [
                {
                    name: "name",
                    arguments: [
                        {
                            name: "id",
                            value: 132,
                            'type: T_INT,
                            nameLocation: {
                                line: 8,
                                column: 10
                            },
                            valueLocation: {
                                line: 8,
                                column: 14
                            }
                        },
                        {
                            name: "name",
                            value: "Prof. Moriarty",
                            'type: T_STRING,
                            nameLocation: {
                                line: 8,
                                column: 19
                            },
                            valueLocation: {
                                line: 8,
                                column: 25
                            }
                        },
                        {
                            name: "negative",
                            value: -123,
                            'type: T_INT,
                            nameLocation: {
                                line: 8,
                                column: 43
                            },
                            valueLocation: {
                                line: 8,
                                column: 53
                            }
                        },
                        {
                            name: "weight",
                            value: 75.4,
                            'type: T_FLOAT,
                            nameLocation: {
                                line: 8,
                                column: 59
                            },
                            valueLocation: {
                                line: 8,
                                column: 67
                            }
                        }
                    ],
                    selections: [
                        {
                            name: "first",
                            location: {
                                line: 9,
                                column: 9
                            }
                        },
                        {
                            name: "last",
                            location: {
                                line: 10,
                                column: 9
                            }
                        }
                    ],
                    location: {
                        line: 8,
                        column: 5
                    }
                },
                {
                    name: "id",
                    selections: [
                        {
                            name: "prefix",
                            selections: [
                                {
                                    name: "sample",
                                    location: {
                                        line: 14,
                                        column: 13
                                    }
                                }
                            ],
                            location: {
                                line: 13,
                                column: 9
                            }
                        },
                        {
                            name: "suffix",
                            location: {
                                line: 16,
                                column: 9
                            }
                        }
                    ],
                    location: {
                        line: 12,
                        column: 5
                    }
                },
                {
                    name: "birthdate",
                    arguments: [
                        {
                            name: "format",
                            value: "DD/MM/YYYY",
                            'type: T_STRING,
                            nameLocation: {
                                line: 18,
                                column: 16
                            },
                            valueLocation: {
                                line: 18,
                                column: 24
                            }
                        }
                    ],
                    location: {
                        line: 18,
                        column: 5
                    }
                }
            ],
            location: {
                line: 6,
                column: 7
            }
        }
    ]
};

Document documentWithTwoNamedOperations = {
    operations: [
        {
            name: "getName",
            'type: "query",
            fields: [
                {
                    name: "name",
                    location: {
                        line: 2,
                        column: 5
                    }
                }
            ],
            location: {
                line: 1,
                column: 7
            }
        },
        {
            name: "getBirthDate",
            'type: "query",
            fields: [
                {
                    name: "birthdate",
                    location: {
                        line: 6,
                        column: 5
                    }
                }
            ],
            location: {
                line: 5,
                column: 7
            }
        }
    ]
};
