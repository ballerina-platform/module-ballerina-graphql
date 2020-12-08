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
    types: [
        {
            kind: "SCALAR",
            name: "Integer",
            fields: []
        },
        {
            kind: "SCALAR",
            name: "String",
            fields: []
        }
    ],
    queryType: {
        kind: "OBJECT",
        name: "Query",
        fields: [
            {
                name: "name",
                'type: {
                    kind: "SCALAR",
                    name: "String",
                    fields: []
                },
                args: []
            },
            {
                name: "id",
                'type: {
                    kind: "SCALAR",
                    name: "Integer",
                    fields: []
                },
                args: []
            },
            {
                name: "birthdate",
                'type: {
                    kind: "SCALAR",
                    name: "String",
                    fields: []
                },
                args: [
                    {
                        name: "format",
                        'type: {
                            kind: "SCALAR",
                            name: "String",
                            fields: []
                        }
                    }
                ]
            }
        ]
    }
};

__Schema expectedSchemaForResourcesReturningRecords = {
    types: [
        {
            kind: "SCALAR",
            name: "Integer",
            fields: []
        },
        {
            kind: "OBJECT",
            name: "Address",
            fields: [
                {
                    name: "number",
                    'type: {
                        kind: "SCALAR",
                        name: "String",
                        fields: []
                    },
                    args: []
                },
                {
                    name: "street",
                    'type: {
                        kind: "SCALAR",
                        name: "String",
                        fields: []
                    },
                    args: []
                },
                {
                    name: "city",
                    'type: {
                        kind: "SCALAR",
                        name: "String",
                        fields: []
                    },
                    args: []
                }
            ]
        },
        {
            kind: "SCALAR",
            name: "String",
            fields: []
        },
        {
            kind: "OBJECT",
            name: "Person",
            fields: [
                {
                    name: "name",
                    'type: {
                        kind: "SCALAR",
                        name: "String",
                        fields: []
                    },
                    args: []
                },
                {
                    name: "age",
                    'type: {
                        kind: "SCALAR",
                        name: "Integer",
                        fields: []
                    },
                    args: []
                },
                {
                    name: "address",
                    'type: {
                        kind: "OBJECT",
                        name: "Address",
                        fields: [
                            {
                                name: "number",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String",
                                    fields: []
                                },
                                args: []
                            },
                            {
                                name: "street",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String",
                                    fields: []
                                },
                                args: []
                            },
                            {
                                name: "city",
                                'type: {
                                    kind: "SCALAR",
                                    name: "String",
                                    fields: []
                                },
                                args: []
                            }
                        ]
                    },
                    args: []
                }
            ]
        }
    ],
    queryType: {
        kind: "OBJECT",
        name: "Query",
        fields: [
            {
                name: "person",
                'type: {
                    kind: "OBJECT",
                    name: "Person",
                    fields: [
                        {
                            name: "name",
                            'type: {
                                kind: "SCALAR",
                                name: "String",
                                fields: []
                            },
                            args: []
                        },
                        {
                            name: "age",
                            'type: {
                                kind: "SCALAR",
                                name: "Integer",
                                fields: []
                            },
                            args: []
                        },
                        {
                            name: "address",
                            'type: {
                                kind: "OBJECT",
                                name: "Address",
                                fields: [
                                    {
                                        name: "number",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "String",
                                            fields: []
                                        },
                                        args: []
                                    },
                                    {
                                        name: "street",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "String",
                                            fields: []
                                        },
                                        args: []
                                    },
                                    {
                                        name: "city",
                                        'type: {
                                            kind: "SCALAR",
                                            name: "String",
                                            fields: []
                                        },
                                        args: []
                                    }
                                ]
                            },
                            args: []
                        }
                    ]
                },
                args: []
            }
        ]
    }
};
