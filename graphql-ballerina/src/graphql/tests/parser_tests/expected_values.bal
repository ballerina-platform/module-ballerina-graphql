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

//DocumentNode shorthandDocument = {
//    firstOperation: {
//        name: "<anonymous>",
//        kind: "query",
//        firstField: {
//            name: "name",
//            location: {
//                line: 2,
//                column: 5
//            },
//            firstArgument: (),
//            firstSelection: (),
//            nextField: ()
//        },
//        location: {
//            line: 1,
//            column: 1
//        },
//        nextOperation: ()
//    }
//};
//
//DocumentNode namedOperation = {
//    firstOperation: {
//        name: "getData",
//        kind: "query",
//        firstField: {
//            name: "name",
//            location: {
//                line: 2,
//                column: 5
//            },
//            firstArgument: (),
//            firstSelection: (),
//            nextField: {
//                name: "birthdate",
//                location: {
//                    line: 4,
//                    column: 5
//                },
//                firstArgument: (),
//                firstSelection: (),
//                nextField: ()
//            }
//        },
//        location: {
//            line: 1,
//            column: 7
//        },
//        nextOperation: ()
//    }
//};
//
//DocumentNode expectedDocumentWithParameters = {
//    firstOperation: {
//        name: "getData",
//        kind: "query",
//        firstField: {
//            name: "name",
//            location: {
//                line: 8,
//                column: 5
//            },
//            firstArgument: {
//                name: {
//                    value: "id",
//                    location: {
//                        line: 8,
//                        column: 10
//                    }
//                },
//                value: {
//                    value: 132,
//                    location: {
//                        line: 8,
//                        column: 14
//                    }
//                },
//                kind: 3,
//                nextArgument: {
//                    name: {
//                        value: "name",
//                        location: {
//                            line: 8,
//                            column: 21
//                        }
//                    },
//                    value: {
//                        value: "Prof. Moriarty",
//                        location: {
//                            line: 8,
//                            column: 27
//                        }
//                    },
//                    kind: 2,
//                    nextArgument: {
//                        name: {
//                            value: "negative",
//                            location: {
//                                line: 8,
//                                column: 45
//                            }
//                        },
//                        value: {
//                            value: -123,
//                            location: {
//                                line: 8,
//                                column: 55
//                            }
//                        },
//                        kind: 3,
//                        nextArgument: {
//                            name: {
//                                value: "weight",
//                                location: {
//                                    line: 8,
//                                    column: 61
//                                }
//                            },
//                            value: {
//                                value: 75.4,
//                                location: {
//                                    line: 8,
//                                    column: 69
//                                }
//                            },
//                            kind: 4,
//                            nextArgument: ()
//                        }
//                    }
//                }
//            },
//            firstSelection: {
//                name: "first",
//                location: {
//                    line: 9,
//                    column: 9
//                },
//                firstArgument: (),
//                firstSelection: (),
//                nextField: ()
//            },
//            nextField: {
//                name: "id",
//                location: {
//                    line: 12,
//                    column: 5
//                },
//                firstArgument: (),
//                firstSelection: {
//                    name: "prefix",
//                    location: {
//                        line: 13,
//                        column: 9
//                    },
//                    firstArgument: (),
//                    firstSelection: {
//                        name: "sample",
//                        location: {
//                            line: 14,
//                            column: 13
//                        },
//                        firstArgument: (),
//                        firstSelection: (),
//                        nextField: ()
//                    },
//                    nextField: {
//                        name: "suffix",
//                        location: {
//                            line: 16,
//                            column: 9
//                        },
//                        firstArgument: (),
//                        firstSelection: (),
//                        nextField: ()
//                    }
//                },
//                nextField: {
//                    name: "birthdate",
//                    location: {
//                        line: 18,
//                        column: 5
//                    },
//                    firstArgument: {
//                        name: {
//                            value: "format",
//                            location: {
//                                line: 18,
//                                column: 16
//                            }
//                        },
//                        value: {
//                            value: "DD/MM/YYYY",
//                            location: {
//                                line: 18,
//                                column: 24
//                            }
//                        },
//                        kind: 2,
//                        nextArgument: ()
//                    },
//                    firstSelection: (),
//                    nextField: ()
//                }
//            }
//        },
//        location: {
//            line: 6,
//            column: 7
//        },
//        nextOperation: ()
//    }
//};
//
//DocumentNode documentWithTwoNamedOperations = {
//    firstOperation: {
//        name: "getName",
//        kind: "query",
//        firstField: {
//            name: "name",
//            location: {
//                line: 2,
//                column: 5
//            },
//            firstArgument: (),
//            firstSelection: (),
//            nextField: ()
//        },
//        location: {
//            line: 1,
//            column: 7
//        },
//        nextOperation: {
//            name: "getBirthDate",
//            kind: "query",
//            firstField: {
//                name: "birthdate",
//                location: {
//                    line: 6,
//                    column: 5
//                },
//                firstArgument: (),
//                firstSelection: (),
//                nextField: ()
//            },
//            location: {
//                line: 5,
//                column: 7
//            },
//            nextOperation: ()
//        }
//    }
//};
