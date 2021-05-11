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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.PluginConstants.CompilationErrors;

import java.util.List;
import java.util.Optional;

/**
 * Validates functions in Ballerina GraphQL services.
 */
public class GraphqlFunctionValidator {

    public void validate(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        NodeList<Node> memberNodes = serviceDeclarationNode.members();
        for (Node node : memberNodes) {
            FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
            if (functionDefinitionNode.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                // resource functions are valid - validate function signature
                validateResourceFunction(functionDefinitionNode, context);
            } else if (functionDefinitionNode.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                // object methods are valid, object methods that are remote functions are invalid
                if (PluginUtils.isRemoteFunction(context, functionDefinitionNode)) {
                    PluginUtils.updateContext(context, CompilationErrors.INVALID_FUNCTION,
                                              functionDefinitionNode.location());
                }
            }
        }
    }

    private void validateResourceFunction(FunctionDefinitionNode functionDefinitionNode,
                                          SyntaxNodeAnalysisContext context) {
        validateResourceAccessorName(functionDefinitionNode, context);
        validateReturnType(functionDefinitionNode, context);
        validateInputParamType(functionDefinitionNode, context);
    }

    private void validateResourceAccessorName(FunctionDefinitionNode functionDefinitionNode,
                                              SyntaxNodeAnalysisContext context) {
        SemanticModel semanticModel = context.semanticModel();
        Optional<Symbol> symbolOptional = semanticModel.symbol(functionDefinitionNode);
        if (symbolOptional.isPresent()) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) symbolOptional.get();
            Optional<String> methodName = resourceMethodSymbol.getName();
            if (methodName.isPresent()) {
                if (!methodName.get().equals(PluginConstants.RESOURCE_FUNCTION_GET)) {
                    PluginUtils.updateContext(context, CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR,
                                              functionDefinitionNode.location());
                }
            } else {
                PluginUtils.updateContext(context,
                                          CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR,
                                          functionDefinitionNode.location());
            }
        }
    }

    private void validateReturnType(FunctionDefinitionNode functionDefinitionNode, SyntaxNodeAnalysisContext context) {
        MethodSymbol methodSymbol = PluginUtils.getMethodSymbol(context, functionDefinitionNode);
        if (methodSymbol != null) {
            Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
            if (returnTypeDesc.isPresent()) {
                // if return type is a union
                if (returnTypeDesc.get().typeKind() == TypeDescKind.UNION) {
                    List<TypeSymbol> returnTypeMembers =
                            ((UnionTypeSymbol) returnTypeDesc.get()).memberTypeDescriptors();

                    // for cases like returning (float|decimal) - only one scalar type is allowed
                    int primitiveType = 0;
                    // for cases with only error?
                    int type = 0;

                    for (TypeSymbol returnType : returnTypeMembers) {
                        if (returnType.typeKind() != TypeDescKind.NIL && returnType.typeKind() != TypeDescKind.ERROR) {
                            if (hasInvalidReturnType(returnType)) {
                                PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE
                                        , functionDefinitionNode.location());
                            }
                            if (hasPrimitiveType(returnType)) {
                                primitiveType++;
                            } else {
                                type++;
                            }
                        } // nil in a union in valid, no validation
                    }
                    if (type == 0 && primitiveType == 0) { // error? - invalid
                        PluginUtils.updateContext(context,
                                                  CompilationErrors.INVALID_RETURN_TYPE_ERROR_OR_NIL,
                                                  functionDefinitionNode.location());
                    } else if (primitiveType > 0 && type > 0) { // Person|string - invalid
                        PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE
                                , functionDefinitionNode.location());
                    } else if (primitiveType > 1) { // string|int - invalid
                        PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE
                                , functionDefinitionNode.location());
                    } // type > 1 is valid - Person|Student
                } else {
                    // if return type not a union
                    // nil alone is invalid - must have a return type
                    if (returnTypeDesc.get().typeKind() == TypeDescKind.NIL) {
                        PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE_NIL,
                                                  functionDefinitionNode.location());
                    } else if (returnTypeDesc.get().typeKind() == TypeDescKind.ERROR) {
                        PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE_ERROR,
                                                  functionDefinitionNode.location());
                    } else {
                        if (hasInvalidReturnType(returnTypeDesc.get())) {
                            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE,
                                                      functionDefinitionNode.location());
                        }
                    }
                }
            }
        }
    }

    private void validateInputParamType(FunctionDefinitionNode functionDefinitionNode,
                                        SyntaxNodeAnalysisContext context) {
        MethodSymbol methodSymbol = PluginUtils.getMethodSymbol(context, functionDefinitionNode);
        if (methodSymbol != null) {
            if (methodSymbol.typeDescriptor().typeKind() == TypeDescKind.FUNCTION) {
                FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
                if (functionTypeSymbol.params().isPresent()) {
                    List<ParameterSymbol> parameterSymbols = functionTypeSymbol.params().get();
                    // can have any number of valid input params
                    for (ParameterSymbol param : parameterSymbols) {
                        if (hasInvalidInputParamType(param.typeDescriptor())) {
                            PluginUtils.updateContext(context, CompilationErrors.INVALID_RESOURCE_INPUT_PARAM,
                                                      functionDefinitionNode.location());
                        }
                    }
                }
            }
        }
    }

    private boolean hasInvalidInputParamType(TypeSymbol inputTypeSymbol) {
        if (inputTypeSymbol.typeKind() == TypeDescKind.UNION) {
            List<TypeSymbol> members = ((UnionTypeSymbol) inputTypeSymbol).memberTypeDescriptors();
            boolean hasInvalidMember = false;
            int hasType = 0;
            for (TypeSymbol member: members) {
                if (member.typeKind() != TypeDescKind.NIL) {
                    hasInvalidMember = hasInvalidInputParamType(member);
                    hasType++;
                }
            }
            if (hasType > 1) {
                hasInvalidMember = true;
            }
            return hasInvalidMember;
        }
        if (inputTypeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            if ((((TypeReferenceTypeSymbol) inputTypeSymbol).definition()).kind() == SymbolKind.ENUM) {
                return false;
            }
        }
        return !hasPrimitiveType(inputTypeSymbol);
    }

    private boolean hasInvalidReturnType(TypeSymbol returnTypeSymbol) {
        boolean hasInvalidReturnType = false;
        if (returnTypeSymbol.typeKind() == TypeDescKind.MAP || returnTypeSymbol.typeKind() == TypeDescKind.JSON ||
            returnTypeSymbol.typeKind() == TypeDescKind.BYTE) {
            return true;
        } else if (returnTypeSymbol.typeKind() == TypeDescKind.ARRAY) {
            // check member type
            return hasInvalidReturnType(((ArrayTypeSymbol) returnTypeSymbol).memberTypeDescriptor());
        } else if (returnTypeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            // only service object types and records are allowed
            if ((((TypeReferenceTypeSymbol) returnTypeSymbol).definition()).kind() == SymbolKind.TYPE_DEFINITION) {
                if (!isRecordType(returnTypeSymbol)) {
                    hasInvalidReturnType = true;
                }
            } else if (((TypeReferenceTypeSymbol) returnTypeSymbol).definition().kind() == SymbolKind.CLASS) {
                if (!isValidServiceType(returnTypeSymbol)) {
                    hasInvalidReturnType = true;
                }
            }
        } else if (returnTypeSymbol.typeKind() == TypeDescKind.OBJECT) {
            hasInvalidReturnType = true;
        }
        return hasInvalidReturnType;
    }

    private boolean isRecordType(TypeSymbol returnTypeSymbol) {
        TypeDefinitionSymbol definitionSymbol =
                (TypeDefinitionSymbol) ((TypeReferenceTypeSymbol) returnTypeSymbol).definition();
        return definitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD;
    }

    private boolean hasPrimitiveType(TypeSymbol returnType) {
        return returnType.typeKind() == TypeDescKind.STRING ||
               returnType.typeKind() == TypeDescKind.INT ||
               returnType.typeKind() == TypeDescKind.FLOAT ||
               returnType.typeKind() == TypeDescKind.BOOLEAN ||
               returnType.typeKind() == TypeDescKind.DECIMAL;
    }

    private boolean isValidServiceType(TypeSymbol returnTypeSymbol) {
        ClassSymbol classSymbol = (ClassSymbol) ((TypeReferenceTypeSymbol) returnTypeSymbol).definition();
        return classSymbol.qualifiers().contains(Qualifier.SERVICE) && classSymbol.getName().isPresent();
    }
}
