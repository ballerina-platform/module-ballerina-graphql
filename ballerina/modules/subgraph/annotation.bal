// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
// specific language gove

# The annotation to designate a GraphQL service as a federated GraphQL subgraph.
public annotation Subgraph on service;

# Describes the shape of the `graphql:Entity` annotation
# + key - GraphQL fields and subfields that contribute to the entity's primary key/keys
# + resolveReference - Function pointer to resolve the entity. if set to nil, indicates the graph router that this
#                      subgraph does not define a reference resolver for this entity
public type FederatedEntity record {|
    string|string[] key;
    ReferenceResolver? resolveReference = ();
|};

# The annotation to designate a GraphQL object type as a federated entity.
public annotation FederatedEntity Entity on class, type;
