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
    ERROR_113("a GraphQL service must have at least one resource method with a '''" + RESOURCE_FUNCTION_GET + "''' "
                      + "accessor"),
    ERROR_114("the GraphQL field ''{0}'' use input type ''{1}'' as an output type. A GraphQL field cannot use an input "
                      + "type as an output type"),
    ERROR_115("the GraphQL field ''{0}'' use output type ''{1}'' as an input type. A GraphQL field cannot use an output"
                      + " type as an input type"),
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
    ERROR_132("invalid return type ''{0}'' provided for the GraphQL field ''{1}''. ''{0}'' is not a service class");

    private final String message;

    DiagnosticMessage(String message) {
        this.message = message;
    }

    public String getMessage() {
        return this.message;
    }
}
