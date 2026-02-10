/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.diagnostics;

import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.DOUBLE_UNDERSCORES;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_SUBSCRIBE;

/**
 * Compilation error messages used in Ballerina GraphQL package compiler plugin.
 */
public enum DiagnosticMessage {
    ERROR_101("service class ''{0}'' contains remote method ''{1}''. Remote methods are not allowed inside the service "
                      + "classes returned from GraphQL resources"),
    ERROR_102("invalid GraphQL field Type ''{0}'' provided for the GraphQL field ''{1}''"),
    ERROR_103("invalid input parameter type ''{0}'' used in GraphQL field ''{1}''"),
    ERROR_104("return type not provided for the GraphQL field ''{0}''"),
    ERROR_105("the GraphQL field ''{0}'' has a ballerina union type, but the union does not contain any valid data type"
                      + " to return"),
    ERROR_106("invalid resource method accessor ''{0}'' used in method ''{1}''. Only '''" + RESOURCE_FUNCTION_GET
                      + "''' allowed"),
    ERROR_107("a GraphQL service cannot be attached to multiple listeners"),
    ERROR_108("the GraphQL field ''{0}'' only returns an error type. It must return a data type"),
    ERROR_109("http:Listener and graphql:ListenerConfiguration are mutually exclusive"),
    ERROR_110("invalid GraphQL union type member ''{0}'' found. Only distinct service types are allowed"),
    ERROR_111("the GraphQL field name ''{0}'' is not valid. Name ''{1}'' must not begin with \"" + DOUBLE_UNDERSCORES
                      + "\", which is reserved by GraphQL introspection"),
    ERROR_112("invalid type found in the GraphQL field ''{0}''. A GraphQL field cannot have \"any\" or \"anydata\" as "
                      + "the type, instead use specific types"),
    ERROR_113("a GraphQL service must include at least one resource method with the accessor '''"
                      + RESOURCE_FUNCTION_GET + "''' that does not have the @dataloader:Loader annotation attached"
                      + " to it"),
    ERROR_114("the GraphQL field ''{0}'' uses input type ''{1}'' as an output type. A GraphQL field cannot use an " +
            "input type as an output type"),
    ERROR_115("the GraphQL field ''{0}'' uses output type ''{1}'' as an input type. A GraphQL field cannot use an " +
            "output type as an input type"),
    ERROR_116("non-distinct service class ''{0}'' is used as a GraphQL interface"),
    ERROR_117("found path parameters ''{0}'' in GraphQL resource. Path parameters are not allowed in GraphQL "
                      + "resources"),
    ERROR_118("invalid resource path ''{0}'' found in GraphQL resource"),
    ERROR_119("the graphql:Upload cannot be used as an input type of resource method ''{0}''"),
    ERROR_120("multidimensional graphql:Upload array parameter found in method ''{0}''. GraphQL input cannot have "
                      + "multidimensional graphql:Upload arrays"),
    ERROR_121("the Graphql input type must not be a subtype of '''error?'''"),
    ERROR_122("invalid union type for GraphQL input type"),
    ERROR_123("non-distinct service class ''{0}'' is used as a GraphQL interface implementation"),
    ERROR_124("invalid hierarchical resource path ''{0}'' found in subscribe resource"),
    ERROR_125("invalid return type ''{0}'' found in subscribe resource ''{1}''. GraphQL subscribe resource must return "
                      + "'''stream''' type"),
    ERROR_126("invalid GraphQL resource accessor ''{0}'' found in resource ''{1}''. Only '''" + RESOURCE_FUNCTION_GET
                      + "''' and '''" + RESOURCE_FUNCTION_SUBSCRIBE + "''' are allowed"),
    ERROR_127("failed to generate the schema from the service. {0}"),
    ERROR_128("invalid resource method ''{0}'' found in GraphQL interceptor. GraphQL interceptors can not have resource"
                      + " methods"),
    ERROR_129("invalid remote method ''{0}'' found in interceptor service. Only \"execute\" remote method is allowed"),
    ERROR_130("anonymous record ''{0}'' cannot be used as the type of the field ''{1}''"),
    ERROR_131("anonymous record ''{0}'' cannot be used as an input object type of the field ''{1}''"),
    ERROR_132("invalid return type ''{0}'' provided for the GraphQL field ''{1}''. ''{0}'' is not a service class"),
    ERROR_133("invalid use of reserved remote method name ''{0}''. The field ''{0}'' is reserved for use in "
                      + "GraphQL Federation"),
    ERROR_134("invalid use of reserved resource path ''{0}''. The field ''{0}'' is reserved for use in "
                      + "GraphQL Federation"),
    ERROR_135("the GraphQL field ''{0}'' use ''{1}'' as an output type. The type ''{1}'' is reserved for use in "
                      + "GraphQL Federation."),
    ERROR_136("invalid usage of type ''{0}'' as input object. The type ''{0}'' is reserved for use in "
                      + "GraphQL Federation"),
    ERROR_137("failed to add _entities resolver to the subgraph service"),
    ERROR_138("failed to add _service service to the subgraph service"),
    ERROR_139("failed to generate schema for type ''{0}''. Type alias for type ''{1}'' is not supported"),
    ERROR_140("invalid usage of @graphql:ID annotation. @graphql:ID annotation can only be used with string, "
                      + "int, float, decimal and uuid:Uuid types"),
    ERROR_141("invalid method signature found in ''{0}'' prefetch method. The method requires a parameter of type "
                      + "''graphql:Context''"),
    ERROR_142("invalid parameter ''{0}'' found in prefetch method ''{1}''. No matching parameter found in"
                      + " the GraphQL field ''{2}''"),
    ERROR_143("invalid return type ''{0}'' found in prefetch method ''{1}''. The data loader "
                      + "method must not return any value"),
    ERROR_144("no prefetch method found with name ''{0}'' for the GraphQL field ''{1}''"),
    ERROR_145("invalid usage of ''{0}'' configuration found in subscription resource ''{1}''. ''{0}'' configuration is"
                      + " only supported for 'remote' methods and 'get' resource methods"),
    ERROR_146("invalid empty record type ''{0}'' found for GraphQL object type at field ''{1}''"),
    ERROR_147("invalid empty record type ''{0}'' found for GraphQL input object type at field ''{1}''"),
    ERROR_148("field ''{0}'' in ServiceConfig is not allowed to be modified. "
                      + "The value will be generated automatically by the GraphQL module"),
    ERROR_149("field ''{0}'' is not allowed in stub entity." + " Only key fields can be included"),

    WARNING_201("invalid usage of @deprecated directive found in ''{0}''. Input object field(s) deprecation "
                        + "is not supported by the current GraphQL spec"),
    WARNING_202("unable to validate ''{0}'' configuration of the GraphQL field ''{1}''. Pass a string literal to "
                        + "the ''{0}'' configuration to resolve this warning"),
    WARNING_203("unable to validate the @subgraph:Entity annotation. This could lead to an invalid generated subgraph"
                        + " schema. Pass key-value pairs in the @subgraph:Entity annotation to resolve this warning"),
    WARNING_204("unable to validate the @subgraph:Entity annotation. This could lead to an invalid generated subgraph"
                        + " schema. Provide a string literal or an array of string literal values for the ''{0}'' field"
                        + " in the @subgraph:Entity annotation to resolve this warning"),
    WARNING_205("unable to infer default value of {0} ''{1}'' at compile time. This could potentially lead to the "
                        + "generation of an incorrect GraphQL schema"),
    WARNING_206(WARNING_205.getMessage() + ". Provide key-value pairs to resolve this warning"),
    WARNING_207(WARNING_205.getMessage() + ". Provide only literal, list, or a mapping "
                        + "constructor expression as the default value to resolve this warning"),
    WARNING_208(WARNING_205.getMessage() + ". Avoid using spread operation to resolve this warning"),
    WARNING_209("unable to validate the default value of field ''{0}'' of input type ''{1}''. Try defining the "
                        + "included types of this type in the same module where the graphql:Service is defined to "
                        + "resolve this warning"),
    WARNING_210("unable to validate the default values of input type ''{0}''. This could potentially lead to the "
                        + "generation of an incorrect GraphQL schema. Try defining this type in the same module where"
                        + " the graphql:Service is defined to resolve this warning");

    private final String message;

    DiagnosticMessage(String message) {
        this.message = message;
    }

    public String getMessage() {
        return this.message;
    }
}
