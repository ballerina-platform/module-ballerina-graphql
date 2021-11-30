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
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
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
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.graphql.compiler.Utils.CONTEXT_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.Utils.CompilationError;
import static io.ballerina.stdlib.graphql.compiler.Utils.PACKAGE_ORG;
import static io.ballerina.stdlib.graphql.compiler.Utils.PACKAGE_PREFIX;
import static io.ballerina.stdlib.graphql.compiler.Utils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.Utils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.Utils.getMethodSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.updateContext;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class FunctionValidator {
    private final Set<ClassSymbol> visitedClassSymbols = new HashSet<>();
    private final List<TypeSymbol> existingInputObjectTypes = new ArrayList<>();
    private final List<TypeSymbol> existingReturnTypes = new ArrayList<>();

    public void validate(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        NodeList<Node> memberNodes = serviceDeclarationNode.members();
        boolean resourceFunctionFound = false;
        for (Node node : memberNodes) {
            if (node.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                resourceFunctionFound = true;
                FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
                // resource functions are valid - validate function signature
                validateResourceFunction(functionDefinitionNode, context);
            } else if (node.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
                // Validate remote methods
                if (Utils.isRemoteFunction(context, functionDefinitionNode)) {
                    validateRemoteFunction(functionDefinitionNode, context);
                }
            }
        }
        existingInputObjectTypes.clear();
        existingReturnTypes.clear();
        if (!resourceFunctionFound) {
            updateContext(context, CompilationError.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
    }

    private void validateResourceFunction(FunctionDefinitionNode functionDefinitionNode,
                                          SyntaxNodeAnalysisContext context) {
        MethodSymbol methodSymbol = getMethodSymbol(context, functionDefinitionNode);
        if (Objects.nonNull(methodSymbol)) {
            validateResourceAccessorName(methodSymbol, functionDefinitionNode.location(), context);
            validateResourcePath(methodSymbol, functionDefinitionNode.location(), context);
            Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
            returnTypeDesc.ifPresent
                    (typeSymbol -> validateReturnType(typeSymbol, functionDefinitionNode.location(), context));
            validateInputParamType(methodSymbol, functionDefinitionNode.location(), context);
        }
    }

    private void validateRemoteFunction(FunctionDefinitionNode functionDefinitionNode,
                                        SyntaxNodeAnalysisContext context) {
        MethodSymbol methodSymbol = getMethodSymbol(context, functionDefinitionNode);
        if (Objects.nonNull(methodSymbol)) {
            Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
            returnTypeDesc.ifPresent(
                    typeSymbol -> validateReturnType(typeSymbol, functionDefinitionNode.location(), context));
            validateInputParamType(methodSymbol, functionDefinitionNode.location(), context);
        }
    }

    private void validateResourceAccessorName(MethodSymbol methodSymbol, Location location,
                                              SyntaxNodeAnalysisContext context) {
        if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
            Optional<String> methodName = resourceMethodSymbol.getName();
            if (methodName.isPresent()) {
                if (!methodName.get().equals(RESOURCE_FUNCTION_GET)) {
                    Location accessorLocation = getLocation(resourceMethodSymbol, location);
                    updateContext(context, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
                }
            } else {
                Location accessorLocation = getLocation(resourceMethodSymbol, location);
                updateContext(context, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
            }
        }
    }

    private void validateResourcePath(MethodSymbol methodSymbol, Location location, SyntaxNodeAnalysisContext context) {
        if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
            if (Utils.isInvalidFieldName(resourceMethodSymbol.resourcePath().signature())) {
                updateContext(context, CompilationError.INVALID_FIELD_NAME, location);
            }
        }
    }

    private void validateReturnType(TypeSymbol returnTypeDesc,
                                    Location location, SyntaxNodeAnalysisContext context) {
        if (existingInputObjectTypes.contains(returnTypeDesc)) {
            updateContext(context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.ANY || returnTypeDesc.typeKind() == TypeDescKind.ANYDATA) {
            updateContext(context, CompilationError.INVALID_RETURN_TYPE_ANY, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.UNION) {
            validateReturnTypeUnion(((UnionTypeSymbol) returnTypeDesc).memberTypeDescriptors(), location, context);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.ARRAY) {
            // check member type
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) returnTypeDesc;
            validateReturnType(arrayTypeSymbol.memberTypeDescriptor(), location, context);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateReturnTypeDefinitions((TypeReferenceTypeSymbol) returnTypeDesc, location, context);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.NIL) {
            // nil alone is invalid - must have a return type
            updateContext(context, CompilationError.INVALID_RETURN_TYPE_NIL, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.ERROR) {
            // error alone is invalid
            updateContext(context, CompilationError.INVALID_RETURN_TYPE_ERROR, location);
        } else if (hasInvalidReturnType(returnTypeDesc)) {
            updateContext(context, CompilationError.INVALID_RETURN_TYPE, location);
        }
    }

    private void validateReturnTypeDefinitions(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location,
                                               SyntaxNodeAnalysisContext context) {
        if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.TYPE_DEFINITION) {
            TypeDefinitionSymbol typeDefinitionSymbol =
                    (TypeDefinitionSymbol) typeReferenceTypeSymbol.definition();
            if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
                if (existingInputObjectTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                    updateContext(context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
                } else {
                    existingReturnTypes.add(typeReferenceTypeSymbol.typeDescriptor());
                }
                validateRecordFields(context, (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor(), location);
            }
            validateReturnType(typeDefinitionSymbol.typeDescriptor(), location, context);
        } else if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.CLASS) {
            ClassSymbol classSymbol = (ClassSymbol) typeReferenceTypeSymbol.definition();
            Location classSymbolLocation = getLocation(classSymbol, location);
            if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                updateContext(context, CompilationError.INVALID_RETURN_TYPE, classSymbolLocation);
            } else {
                validateServiceClassDefinition(classSymbol, classSymbolLocation, context);
            }
        }
    }

    public FunctionValidator() {
        super();
    }

    private void validateInputParamType(MethodSymbol methodSymbol, Location location,
                                        SyntaxNodeAnalysisContext context) {
        if (methodSymbol.typeDescriptor().typeKind() == TypeDescKind.FUNCTION) {
            FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
            if (functionTypeSymbol.params().isPresent()) {
                List<ParameterSymbol> parameterSymbols = functionTypeSymbol.params().get();
                for (int i = 0; i < parameterSymbols.size(); i++) {
                    ParameterSymbol param = parameterSymbols.get(i);
                    if (isContextParameter(param.typeDescriptor())) {
                        if (i != 0) {
                            Location inputLocation = getLocation(param, location);
                            updateContext(context, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER,
                                          inputLocation);
                        }
                        continue;
                    }
                    if (hasInvalidInputParamType(param.typeDescriptor())) {
                        Location inputLocation = getLocation(param, location);
                        addInputTypeErrorIntoContext(param.typeDescriptor(), inputLocation, context);
                    }
                }
            }
        }
    }

    private boolean hasInvalidInputParamType(TypeSymbol inputTypeSymbol) {
        if (inputTypeSymbol.typeKind() == TypeDescKind.UNION) {
            List<TypeSymbol> members = ((UnionTypeSymbol) inputTypeSymbol).userSpecifiedMemberTypes();
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
            } else if ((((TypeReferenceTypeSymbol) inputTypeSymbol).definition()).kind() ==
                    SymbolKind.TYPE_DEFINITION) {
                TypeDefinitionSymbol typeDefinitionSymbol =
                        (TypeDefinitionSymbol) ((TypeReferenceTypeSymbol) inputTypeSymbol).definition();
                if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.UNION) {
                    return true;
                } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
                    if (existingReturnTypes.contains(typeDefinitionSymbol.typeDescriptor())) {
                        return true;
                    } else {
                        existingInputObjectTypes.add(typeDefinitionSymbol.typeDescriptor());
                    }
                    Map<String, RecordFieldSymbol> memberMap = ((RecordTypeSymbol) typeDefinitionSymbol
                            .typeDescriptor()).fieldDescriptors();
                    boolean hasInvalidMember = true;
                    for (RecordFieldSymbol fields : memberMap.values()) {
                        if (fields.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE) {
                            hasInvalidMember =
                                    hasInvalidInputObjectField((TypeReferenceTypeSymbol) fields.typeDescriptor());
                        } else {
                            hasInvalidMember = hasInvalidReturnType(fields.typeDescriptor());
                        }
                    }
                    return hasInvalidMember;
                }
                return false;
            }
        }
        if (inputTypeSymbol.typeKind() == TypeDescKind.ARRAY) {
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) inputTypeSymbol;
            TypeSymbol typeSymbol = arrayTypeSymbol.memberTypeDescriptor();
            return hasInvalidInputParamType(typeSymbol);
        }
        return !hasPrimitiveType(inputTypeSymbol);
    }

    private void addInputTypeErrorIntoContext(TypeSymbol typeSymbol, Location inputLocation,
                                              SyntaxNodeAnalysisContext context) {
        if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            Symbol symbol = ((TypeReferenceTypeSymbol) typeSymbol).definition();
            if (symbol.kind() == SymbolKind.CLASS) {
                updateContext(context, CompilationError.INVALID_RESOURCE_INPUT_PARAM, inputLocation);
            } else {
                TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) symbol;
                if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
                    updateContext(context, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM,
                            inputLocation);
                } else {
                    updateContext(context, CompilationError.INVALID_RESOURCE_INPUT_PARAM, inputLocation);
                }
            }
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) typeSymbol;
            TypeSymbol ofTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
            addInputTypeErrorIntoContext(ofTypeSymbol, inputLocation, context);
        } else {
            updateContext(context, CompilationError.INVALID_RESOURCE_INPUT_PARAM, inputLocation);
        }
    }

    private boolean hasInvalidReturnType(TypeSymbol returnTypeSymbol) {
        return returnTypeSymbol.typeKind() == TypeDescKind.MAP || returnTypeSymbol.typeKind() == TypeDescKind.JSON ||
                returnTypeSymbol.typeKind() == TypeDescKind.BYTE || returnTypeSymbol.typeKind() == TypeDescKind.OBJECT;
    }

    private boolean hasInvalidInputObjectField(TypeReferenceTypeSymbol typeSymbol) {
        if (typeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            if (existingReturnTypes.contains(typeSymbol.typeDescriptor())) {
                return true;
            }
            existingInputObjectTypes.add(typeSymbol.typeDescriptor());
            return false;
        }
        return hasInvalidReturnType(typeSymbol.typeDescriptor());
    }

    private void validateServiceClassDefinition(ClassSymbol classSymbol, Location location,
                                                SyntaxNodeAnalysisContext context) {
        if (!visitedClassSymbols.contains(classSymbol)) {
            visitedClassSymbols.add(classSymbol);
            boolean resourceMethodFound = false;
            Map<String, MethodSymbol> methods = classSymbol.methods();
            for (MethodSymbol methodSymbol : methods.values()) {
                Location methodLocation = getLocation(methodSymbol, location);
                if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                    resourceMethodFound = true;
                    validateResourceAccessorName(methodSymbol, methodLocation, context);
                    validateResourcePath(methodSymbol, methodLocation, context);
                    Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
                    returnTypeDesc.ifPresent
                            (typeSymbol -> validateReturnType(typeSymbol, methodLocation, context));
                    validateInputParamType(methodSymbol, methodLocation, context);
                } else if (methodSymbol.qualifiers().contains(Qualifier.REMOTE)) {
                    updateContext(context, CompilationError.INVALID_FUNCTION, methodLocation);
                }
            }
            if (!resourceMethodFound) {
                updateContext(context, CompilationError.MISSING_RESOURCE_FUNCTIONS, location);
            }
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

    private void validateReturnTypeUnion(List<TypeSymbol> returnTypeMembers, Location location,
                                         SyntaxNodeAnalysisContext context) {
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
                            updateContext(context, CompilationError.INVALID_RETURN_TYPE, location);
                        } else {
                            if (existingInputObjectTypes.contains(returnType)) {
                                updateContext(context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
                            } else {
                                existingReturnTypes.add(returnType);
                            }
                            TypeDefinitionSymbol typeDefinitionSymbol =
                                    (TypeDefinitionSymbol) ((TypeReferenceTypeSymbol) returnType).definition();
                            Map<String, RecordFieldSymbol> memberMap = ((RecordTypeSymbol) typeDefinitionSymbol
                                    .typeDescriptor()).fieldDescriptors();
                            for (RecordFieldSymbol fields : memberMap.values()) {
                                if (fields.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE) {
                                    if (existingInputObjectTypes.contains(fields.typeDescriptor())) {
                                        updateContext(context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT,
                                                      location);
                                    } else {
                                        existingReturnTypes.add(fields.typeDescriptor());
                                    }
                                }
                            }
                            recordTypes++;
                        }
                    } else if (((TypeReferenceTypeSymbol) returnType).definition().kind() == SymbolKind.CLASS) {
                        ClassSymbol classSymbol = (ClassSymbol) ((TypeReferenceTypeSymbol) returnType).definition();
                        Location classSymbolLocation = getLocation(classSymbol, location);
                        if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                            updateContext(context, CompilationError.INVALID_RETURN_TYPE, classSymbolLocation);
                        } else {
                            validateServiceClassDefinition(classSymbol, classSymbolLocation, context);
                            // if distinctServices is false (one of the services is not distinct), skip setting it again
                            if (distinctServices) {
                                distinctServices = classSymbol.qualifiers().contains(Qualifier.DISTINCT);
                            }
                            serviceTypes++;
                        }
                    }
                } else {
                    if (hasInvalidReturnType(returnType)) {
                        updateContext(context, CompilationError.INVALID_RETURN_TYPE, location);
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
            updateContext(context, CompilationError.INVALID_RETURN_TYPE_MULTIPLE_SERVICES, location);
        }
        if (recordTypes > 1) {
            updateContext(context, CompilationError.INVALID_RETURN_TYPE, location);
        }
        if (type == 0 && primitiveType == 0) { // error? - invalid
            updateContext(context, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, location);
        } else if (primitiveType > 0 && type > 0) { // Person|string - invalid
            updateContext(context, CompilationError.INVALID_RETURN_TYPE, location);
        } else if (primitiveType > 1) { // string|int - invalid
            updateContext(context, CompilationError.INVALID_RETURN_TYPE, location);
        }
    }

    private void validateRecordFields(SyntaxNodeAnalysisContext context, RecordTypeSymbol recordTypeSymbol,
                                      Location location) {
        Map<String, RecordFieldSymbol> recordFieldSymbolMap = recordTypeSymbol.fieldDescriptors();
        for (RecordFieldSymbol recordField : recordFieldSymbolMap.values()) {
            if (recordField.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE ||
                    recordField.typeDescriptor().typeKind() == TypeDescKind.UNION) {
                Location fieldLocation = getLocation(recordField, location);
                validateReturnType(recordField.typeDescriptor(), fieldLocation, context);
            } else {
                if (Utils.isInvalidFieldName(recordField.getName().orElse(""))) {
                    Location fieldLocation = getLocation(recordField, location);
                    updateContext(context, CompilationError.INVALID_FIELD_NAME, fieldLocation);
                }
            }
        }
    }

    private boolean isContextParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getModule().isPresent()) {
            ModuleSymbol moduleSymbol = typeSymbol.getModule().get();
            if (typeSymbol.getName().isPresent()) {
                return moduleSymbol.id().moduleName().equals(PACKAGE_PREFIX) && moduleSymbol.id().orgName().equals(
                        PACKAGE_ORG) && typeSymbol.getName().get().equals(CONTEXT_IDENTIFIER);
            }
        }
        return false;
    }
}
