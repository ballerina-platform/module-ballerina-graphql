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

Document shorthandDocument = {
    operations: [
        {
            name: "<anonymous>",
            kind: "query",
            selections: [
                {
                    name: "name",
                    arguments: [],
                    selections: [],
                    location: {
                        line: 2,
                        column: 5
                    }
                },
                {
                    name: "id",
                    arguments: [],
                    selections: [],
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
        }
    ]
};

Document namedOperation = {
    operations: [
        {
            name: "getData",
            kind: "query",
            selections: [
                {
                    name: "name",
                    arguments: [],
                    selections: [],
                    location: {
                        line: 2,
                        column: 5
                    }
                },
                {
                    name: "id",
                    arguments: [],
                    selections: [],
                    location: {
                        line: 3,
                        column: 5
                    }
                },
                {
                    name: "birthdate",
                    arguments: [],
                    selections: [],
                    location: {
                        line: 4,
                        column: 5
                    }
                }
            ],
            location: {
                line: 1,
                column: 1
            }
        }
    ]
};

Document expectedDocumentWithParameters =
{
    operations: [
        {
            name: "getData",
            kind: "query",
            selections: [
                {
                    name: "name",
                    arguments: [
                        {
                            name: {
                                value: "id",
                                location: {
                                    line: 8,
                                    column: 10
                                }
                            },
                            value: {
                                value: 132,
                                location: {
                                    line: 8,
                                    column: 14
                                }
                            },
                            kind: T_INT
                        },
                        {
                            name: {
                                value: "name",
                                location: {
                                    line: 8,
                                    column: 21
                                }
                            },
                            value: {
                                value: "Prof. Moriarty",
                                location: {
                                    line: 8,
                                    column: 27
                                }
                            },
                            kind: T_STRING
                        },
                        {
                            name: {
                                value: "negative",
                                location: {
                                    line: 8,
                                    column: 45
                                }
                            },
                            value: {
                                value: -123,
                                location: {
                                    line: 8,
                                    column: 55
                                }
                            },
                            kind: T_INT
                        },
                        {
                            name: {
                                value: "weight",
                                location: {
                                    line: 8,
                                    column: 61
                                }
                            },
                            value: {
                                value: 75.4,
                                location: {
                                    line: 8,
                                    column: 69
                                }
                            },
                            kind: T_FLOAT
                        }
                    ],
                    selections: [
                        {
                            name: "first",
                            selections: [],
                            arguments: [],
                            location: {
                                line: 9,
                                column: 9
                            }
                        },
                        {
                            name: "last",
                            selections: [],
                            arguments: [],
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
                    arguments: [],
                    selections: [
                        {
                            name: "prefix",
                            selections: [
                                {
                                    name: "sample",
                                    selections: [],
                                    arguments: [],
                                    location: {
                                        line: 14,
                                        column: 13
                                    }
                                }
                            ],
                            arguments: [],
                            location: {
                                line: 13,
                                column: 9
                            }
                        },
                        {
                            name: "suffix",
                            selections: [],
                            arguments: [],
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
                            name: {
                                value: "format",
                                location: {
                                    line: 18,
                                    column: 16
                                }
                            },
                            value: {
                                value: "DD/MM/YYYY",
                                location: {
                                    line: 18,
                                    column: 24
                                }
                            },
                            kind: T_STRING
                        }
                    ],
                    selections: [],
                    location: {
                        line: 18,
                        column: 5
                    }
                }
            ],
            location: {
                line: 6,
                column: 1
            }
        }
    ]
};

Document documentWithTwoNamedOperations = {
    operations: [
        {
            name: "getName",
            kind: "query",
            selections: [
                {
                    name: "name",
                    arguments: [],
                    selections: [],
                    location: {
                        line: 2,
                        column: 5
                    }
                }
            ],
            location: {
                line: 1,
                column: 1
            }
        },
        {
            name: "getBirthDate",
            kind: "query",
            selections: [
                {
                    name: "birthdate",
                    arguments: [],
                    selections: [],
                    location: {
                        line: 6,
                        column: 5
                    }
                }
            ],
            location: {
                line: 5,
                column: 1
            }
        }
    ]
};
