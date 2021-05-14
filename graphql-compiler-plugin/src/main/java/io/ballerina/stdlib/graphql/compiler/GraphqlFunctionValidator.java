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

import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
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
import io.ballerina.tools.diagnostics.Location;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * Validates functions in Ballerina GraphQL services.
 */
public class GraphqlFunctionValidator {
    private final Set<ClassSymbol> visitedClassSymbols = new HashSet<>();

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
        MethodSymbol methodSymbol = PluginUtils.getMethodSymbol(context, functionDefinitionNode);
        if (Objects.nonNull(methodSymbol)) {
            validateResourceAccessorName(methodSymbol, functionDefinitionNode.location(), context);
            validateReturnType(methodSymbol, functionDefinitionNode.location(), context);
            validateInputParamType(methodSymbol, functionDefinitionNode.location(), context);
        }
    }

    private void validateResourceAccessorName(MethodSymbol methodSymbol, Location location,
                                              SyntaxNodeAnalysisContext context) {
        if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
            Optional<String> methodName = resourceMethodSymbol.getName();
            if (methodName.isPresent()) {
                if (!methodName.get().equals(PluginConstants.RESOURCE_FUNCTION_GET)) {
                    PluginUtils.updateContext(context, CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR, location);
                }
            } else {
                PluginUtils.updateContext(context, CompilationErrors.INVALID_RESOURCE_FUNCTION_ACCESSOR, location);
            }
        }
    }

    private void validateReturnType(MethodSymbol methodSymbol,
                                    Location location, SyntaxNodeAnalysisContext context) {
        Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
        if (returnTypeDesc.isPresent()) {
            // if return type is a union
            if (returnTypeDesc.get().typeKind() == TypeDescKind.UNION) {
                validateReturnTypeUnion(context,
                        ((UnionTypeSymbol) returnTypeDesc.get()).memberTypeDescriptors(), location);
            } else if (returnTypeDesc.get().typeKind() == TypeDescKind.NIL) {
                // nil alone is invalid - must have a return type
                PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE_NIL, location);
            } else if (returnTypeDesc.get().typeKind() == TypeDescKind.ERROR) {
                // error alone is invalid
                PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE_ERROR, location);
            } else if (hasInvalidReturnType(returnTypeDesc.get(), location, context)) {
                PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
            }
        }
    }

    private void validateInputParamType(MethodSymbol methodSymbol, Location location,
                                        SyntaxNodeAnalysisContext context) {
        if (methodSymbol.typeDescriptor().typeKind() == TypeDescKind.FUNCTION) {
            FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
            if (functionTypeSymbol.params().isPresent()) {
                List<ParameterSymbol> parameterSymbols = functionTypeSymbol.params().get();
                // can have any number of valid input params
                for (ParameterSymbol param : parameterSymbols) {
                    if (hasInvalidInputParamType(param.typeDescriptor())) {
                        PluginUtils.updateContext(context, CompilationErrors.INVALID_RESOURCE_INPUT_PARAM, location);
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
            for (TypeSymbol member : members) {
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

    private boolean hasInvalidReturnType(TypeSymbol returnTypeSymbol, Location location,
                                         SyntaxNodeAnalysisContext context) {
        boolean hasInvalidReturnType = false;
        if (returnTypeSymbol.typeKind() == TypeDescKind.MAP || returnTypeSymbol.typeKind() == TypeDescKind.JSON ||
                returnTypeSymbol.typeKind() == TypeDescKind.BYTE) {
            return true;
        } else if (returnTypeSymbol.typeKind() == TypeDescKind.ARRAY) {
            // check member type
            return hasInvalidReturnType(((ArrayTypeSymbol) returnTypeSymbol).memberTypeDescriptor(), location, context);
        } else if (returnTypeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            // only service object types and records are allowed
            if ((((TypeReferenceTypeSymbol) returnTypeSymbol).definition()).kind() == SymbolKind.TYPE_DEFINITION) {
                if (!isRecordType(returnTypeSymbol)) {
                    hasInvalidReturnType = true;
                }
            } else if (((TypeReferenceTypeSymbol) returnTypeSymbol).definition().kind() == SymbolKind.CLASS) {
                ClassSymbol classSymbol = (ClassSymbol) ((TypeReferenceTypeSymbol) returnTypeSymbol).definition();
                if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                    hasInvalidReturnType = true;
                } else {
                    validateServiceClassDefinition(classSymbol, location, context);
                }
            }
        } else if (returnTypeSymbol.typeKind() == TypeDescKind.OBJECT) {
            hasInvalidReturnType = true;
        }
        return hasInvalidReturnType;
    }

    private void validateServiceClassDefinition(ClassSymbol classSymbol, Location location,
                                                SyntaxNodeAnalysisContext context) {
        if (!visitedClassSymbols.contains(classSymbol)) {
            Map<String, MethodSymbol> methods = classSymbol.methods();
            for (Map.Entry<String, MethodSymbol> method : methods.entrySet()) {
                MethodSymbol methodSymbol = method.getValue();
                if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                    validateResourceAccessorName(methodSymbol, location, context);
                    validateReturnType(methodSymbol, location, context);
                    validateInputParamType(methodSymbol, location, context);
                } else if (methodSymbol.qualifiers().contains(Qualifier.REMOTE)) {
                    PluginUtils.updateContext(context, CompilationErrors.INVALID_FUNCTION, location);
                }
            }
            visitedClassSymbols.add(classSymbol);
        }
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

    private void validateReturnTypeUnion(SyntaxNodeAnalysisContext context, List<TypeSymbol> returnTypeMembers,
                                         Location location) {
        // for cases like returning (float|decimal) - only one scalar type is allowed
        int primitiveType = 0;
        // for cases with only error?
        int type = 0;
        // for union types with multiple services
        int serviceTypes = 0;
        // for union types with multiple records
        int recordTypes = 0;
        // only validated if serviceTypes > 1
        boolean distinctServices = true;

        for (TypeSymbol returnType : returnTypeMembers) {
            if (returnType.typeKind() != TypeDescKind.NIL && returnType.typeKind() != TypeDescKind.ERROR) {
                if (returnType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
                    // only service object types and records are allowed
                    if ((((TypeReferenceTypeSymbol) returnType).definition()).kind() == SymbolKind.TYPE_DEFINITION) {
                        if (!isRecordType(returnType)) {
                            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
                        } else {
                            recordTypes++;
                        }
                    } else if (((TypeReferenceTypeSymbol) returnType).definition().kind() == SymbolKind.CLASS) {
                        ClassSymbol classSymbol = (ClassSymbol) ((TypeReferenceTypeSymbol) returnType).definition();
                        if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
                        } else {
                            validateServiceClassDefinition(classSymbol, location, context);
                            // if distinctServices is false (one of the services is not distinct), skip setting it again
                            if (distinctServices) {
                                distinctServices = classSymbol.qualifiers().contains(Qualifier.DISTINCT);
                            }
                            serviceTypes++;
                        }
                    }
                } else {
                    if (hasInvalidReturnType(returnType, location, context)) {
                        PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
                    }
                }

                if (hasPrimitiveType(returnType)) {
                    primitiveType++;
                } else {
                    type++;
                }
            } // nil in a union in valid, no validation
        }

        // has multiple services and if at least one of them are not distinct
        if (serviceTypes > 1 && !distinctServices) {
            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE_MULTIPLE_SERVICES, location);
        }
        if (recordTypes > 1) {
            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
        }
        if (type == 0 && primitiveType == 0) { // error? - invalid
            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE_ERROR_OR_NIL, location);
        } else if (primitiveType > 0 && type > 0) { // Person|string - invalid
            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
        } else if (primitiveType > 1) { // string|int - invalid
            PluginUtils.updateContext(context, CompilationErrors.INVALID_RETURN_TYPE, location);
        }
    }
}
