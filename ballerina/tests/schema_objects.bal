// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

__Schema schemaWithInputValues = {
  "queryType": {
    "kind": "OBJECT",
    "name": "Query"
  },
  "mutationType": null,
  "subscriptionType": null,
  "types": [
    {
      "kind": "OBJECT",
      "name": "__Field",
      "fields": [
        {
          "name": "name",
          "args": [],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        fieldDescription,
        {
          "name": "args",
          "args": [],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "OBJECT",
                  "name": "__InputValue",
                  "ofType": null
                }
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "type",
          "args": [],
          "type": nonNullTypeWithObject,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "isDeprecated",
          "args": [],
          "type": nonNullTypeWithBoolean,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "deprecationReason",
          "args": [],
          "type": scalarStringType,
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "ENUM",
      "name": "__TypeKind",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": typeKinds,
      "possibleTypes": null
    },
    {
      "kind": "OBJECT",
      "name": "Query",
      "fields": [
        {
          "name": "greet",
          "args": [
            {
              "name": "name",
              "type": nonNullTypeWithString,
              "defaultValue": null
            }
          ],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "name",
          "args": [
            {
              "name": "name",
              "type": nonNullTypeWithString,
              "defaultValue": "\"\""
            }
          ],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "isLegal",
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
          ],
          "type": nonNullTypeWithBoolean,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "quoteById",
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
          ],
          "type": scalarStringType,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "weightInPounds",
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
          ],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "SCALAR",
              "name": "Float",
              "ofType": null
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "isHoliday",
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
          ],
          "type": nonNullTypeWithBoolean,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "getDay",
          "args": [
            {
              "name": "isHoliday",
              "type": nonNullTypeWithBoolean,
              "defaultValue": null
            }
          ],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "ENUM",
                  "name": "Weekday",
                  "ofType": null
                }
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "sendEmail",
          "args": [
            {
              "name": "message",
              "type": nonNullTypeWithString,
              "defaultValue": null
            }
          ],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "type",
          "args": [
            {
              "name": "version",
              "type": nonNullTypeWithString,
              "defaultValue": null
            }
          ],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "version",
          "args": [
            {
              "name": "name",
              "type": nonNullTypeWithString,
              "defaultValue": null
            }
          ],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "convertDecimalToFloat",
          "args": [
            {
              "name": "value",
              "type": nonNullTypeWithDecimal,
              "defaultValue": null
            }
          ],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "SCALAR",
              "name": "Float",
              "ofType": null
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "getTotalInDecimal",
          "args": [
            {
              "name": "prices",
              "type": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "LIST",
                  "name": null,
                  "ofType": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                      "kind": "LIST",
                      "name": null,
                      "ofType": nonNullTypeWithDecimal
                    }
                  }
                }
              },
              "defaultValue": null
            }
          ],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": nonNullTypeWithDecimal
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "getSubTotal",
          "args": [
            {
              "name": "items",
              "type": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "LIST",
                  "name": null,
                  "ofType": {
                    "kind": "NON_NULL",
                    "name": null,
                    "ofType": {
                      "kind": "INPUT_OBJECT",
                      "name": "Item",
                      "ofType": null
                    }
                  }
                }
              },
              "defaultValue": null
            }
          ],
          "type": nonNullTypeWithDecimal,
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "OBJECT",
      "name": "__Schema",
      "fields": [
        fieldDescription,
        {
          "name": "types",
          "args": [],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": nonNullTypeWithObject
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "queryType",
          "args": [],
          "type": nonNullTypeWithObject,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "mutationType",
          "args": [],
          "type": objectType,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "subscriptionType",
          "args": [],
          "type": objectType,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "directives",
          "args": [],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "OBJECT",
                  "name": "__Directive",
                  "ofType": null
                }
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "OBJECT",
      "name": "__Type",
      "fields": [
        {
          "name": "kind",
          "args": [],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "ENUM",
              "name": "__TypeKind",
              "ofType": null
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "name",
          "args": [],
          "type": scalarStringType,
          "isDeprecated": false,
          "deprecationReason": null
        },
        fieldDescription,
        {
          "name": "fields",
          "args": [
            {
              "name": "includeDeprecated",
              "type": scalarBooleanType,
              "defaultValue": "false"
            }
          ],
          "type": {
            "kind": "LIST",
            "name": null,
            "ofType": {
              "kind": "NON_NULL",
              "name": null,
              "ofType": {
                "kind": "OBJECT",
                "name": "__Field",
                "ofType": null
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "interfaces",
          "args": [],
          "type": {
            "kind": "LIST",
            "name": null,
            "ofType": nonNullTypeWithObject
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "possibleTypes",
          "args": [],
          "type": {
            "kind": "LIST",
            "name": null,
            "ofType": nonNullTypeWithObject
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "enumValues",
          "args": [
            {
              "name": "includeDeprecated",
              "type": scalarBooleanType,
              "defaultValue": "false"
            }
          ],
          "type": {
            "kind": "LIST",
            "name": null,
            "ofType": {
              "kind": "NON_NULL",
              "name": null,
              "ofType": {
                "kind": "OBJECT",
                "name": "__EnumValue",
                "ofType": null
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "inputFields",
          "args": [],
          "type": {
            "kind": "LIST",
            "name": null,
            "ofType": {
              "kind": "NON_NULL",
              "name": null,
              "ofType": {
                "kind": "OBJECT",
                "name": "__InputValue",
                "ofType": null
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "ofType",
          "args": [],
          "type": objectType,
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "OBJECT",
      "name": "__EnumValue",
      "fields": [
        {
          "name": "name",
          "args": [],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        fieldDescription,
        {
          "name": "isDeprecated",
          "args": [],
          "type": nonNullTypeWithBoolean,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "deprecationReason",
          "args": [],
          "type": scalarStringType,
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "ENUM",
      "name": "__DirectiveLocation",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": directiveLocations,
      "possibleTypes": null
    },
    {
      "kind": "SCALAR",
      "name": "String",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "SCALAR",
      "name": "Int",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "SCALAR",
      "name": "Float",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "ENUM",
      "name": "Weekday",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "INPUT_OBJECT",
      "name": "Item",
      "fields": null,
      "inputFields": [
        {
          "name": "name",
          "type": nonNullTypeWithString,
          "defaultValue": null
        },
        {
          "name": "price",
          "type": nonNullTypeWithDecimal,
          "defaultValue": null
        }
      ],
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "SCALAR",
      "name": "Decimal",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "OBJECT",
      "name": "__InputValue",
      "fields": [
        {
          "name": "name",
          "args": [],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        fieldDescription,
        {
          "name": "type",
          "args": [],
          "type": nonNullTypeWithObject,
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "defaultValue",
          "args": [],
          "type": scalarStringType,
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "SCALAR",
      "name": "Boolean",
      "fields": null,
      "inputFields": null,
      "interfaces": null,
      "enumValues": null,
      "possibleTypes": null
    },
    {
      "kind": "OBJECT",
      "name": "__Directive",
      "fields": [
        {
          "name": "name",
          "args": [],
          "type": nonNullTypeWithString,
          "isDeprecated": false,
          "deprecationReason": null
        },
        fieldDescription,
        {
          "name": "locations",
          "args": [],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "ENUM",
                  "name": "__DirectiveLocation",
                  "ofType": null
                }
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        },
        {
          "name": "args",
          "args": [],
          "type": {
            "kind": "NON_NULL",
            "name": null,
            "ofType": {
              "kind": "LIST",
              "name": null,
              "ofType": {
                "kind": "NON_NULL",
                "name": null,
                "ofType": {
                  "kind": "OBJECT",
                  "name": "__InputValue",
                  "ofType": null
                }
              }
            }
          },
          "isDeprecated": false,
          "deprecationReason": null
        }
      ],
      "inputFields": null,
      "interfaces": [],
      "enumValues": null,
      "possibleTypes": null
    }
  ],
  "directives": directives
};

__Type scalarStringType = {
  "kind": "SCALAR",
  "name": "String",
  "ofType": null
};

__Type scalarBooleanType = {
  "kind": "SCALAR",
  "name": "Boolean",
  "ofType": null
};

__Type scalarDecimalType = {
  "kind": "SCALAR",
  "name": "Decimal",
  "ofType": null
};

__Type objectType = {
  "kind": "OBJECT",
  "name": "__Type",
  "ofType": null
};

__Type nonNullTypeWithString = {
  "kind": "NON_NULL",
  "name": null,
  "ofType": scalarStringType
};

__Type nonNullTypeWithBoolean = {
  "kind": "NON_NULL",
  "name": null,
  "ofType": scalarBooleanType
};

__Type nonNullTypeWithDecimal = {
  "kind": "NON_NULL",
  "name": null,
  "ofType": scalarDecimalType
};

__Type nonNullTypeWithObject = {
  "kind": "NON_NULL",
  "name": null,
  "ofType": objectType
};

__Field fieldDescription = {
  "name": "description",
  "args": [],
  "type": scalarStringType,
  "isDeprecated": false,
  "deprecationReason": null
};

__Directive[] directives = [
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
        "type": nonNullTypeWithBoolean,
        "defaultValue": null
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
        "type": nonNullTypeWithBoolean,
        "defaultValue": null
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
        "type": scalarStringType,
        "defaultValue": null
      }
    ]
  }
];

__EnumValue[] typeKinds = [
  {
    "name": "SCALAR",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "OBJECT",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "INTERFACE",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "UNION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "ENUM",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "INPUT_OBJECT",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "LIST",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "NON_NULL",
    "isDeprecated": false,
    "deprecationReason": null
  }
];

__EnumValue[] directiveLocations = [
  {
    "name": "QUERY",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "MUTATION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "SUBSCRIPTION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "FIELD",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "FRAGMENT_DEFINITION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "FRAGMENT_SPREAD",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "INLINE_FRAGMENT",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "VARIABLE_DEFINITION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "SCHEMA",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "SCALAR",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "OBJECT",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "FIELD_DEFINITION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "ARGUMENT_DEFINITION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "INTERFACE",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "UNION",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "ENUM",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "ENUM_VALUE",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "INPUT_OBJECT",
    "isDeprecated": false,
    "deprecationReason": null
  },
  {
    "name": "INPUT_FIELD_DEFINITION",
    "isDeprecated": false,
    "deprecationReason": null
  }
];
