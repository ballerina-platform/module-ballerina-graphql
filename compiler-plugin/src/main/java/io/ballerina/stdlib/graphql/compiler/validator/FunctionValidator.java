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

package io.ballerina.stdlib.graphql.compiler.validator;

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
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.Utils;
import io.ballerina.stdlib.graphql.compiler.validator.errors.CompilationError;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.graphql.compiler.Utils.CONTEXT_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.Utils.FILE_UPLOAD_IDENTIFIER;
import static io.ballerina.stdlib.graphql.compiler.Utils.PACKAGE_ORG;
import static io.ballerina.stdlib.graphql.compiler.Utils.PACKAGE_PREFIX;
import static io.ballerina.stdlib.graphql.compiler.Utils.getMethodSymbol;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.isInvalidFieldName;
import static io.ballerina.stdlib.graphql.compiler.validator.ValidatorUtils.updateContext;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class FunctionValidator {
    private final Set<ClassSymbol> visitedClassSymbols = new HashSet<>();
    private final List<TypeSymbol> existingInputObjectTypes = new ArrayList<>();
    private final List<TypeSymbol> existingReturnTypes = new ArrayList<>();
    private SyntaxNodeAnalysisContext context;

    public void initialize(SyntaxNodeAnalysisContext context) {
        this.context = context;
    }

    public void validate() {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) this.context.node();
        NodeList<Node> memberNodes = serviceDeclarationNode.members();
        boolean resourceFunctionFound = false;
        for (Node node : memberNodes) {
            if (node.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                resourceFunctionFound = true;
                FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
                // resource functions are valid - validate function signature
                validateResourceFunction(functionDefinitionNode);
            } else if (node.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
                // Validate remote methods
                if (Utils.isRemoteFunction(this.context, functionDefinitionNode)) {
                    validateRemoteFunction(functionDefinitionNode);
                }
            }
        }
        this.existingInputObjectTypes.clear();
        this.existingReturnTypes.clear();
        if (!resourceFunctionFound) {
            updateContext(this.context, CompilationError.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
    }

    private void validateResourceFunction(FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = getMethodSymbol(this.context, functionDefinitionNode);
        if (Objects.nonNull(methodSymbol)) {
            validateResourceAccessorName(methodSymbol, functionDefinitionNode.location());
            validateResourcePath(methodSymbol, functionDefinitionNode.location());
            Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
            returnTypeDesc.ifPresent
                    (typeSymbol -> validateReturnType(typeSymbol, functionDefinitionNode.location()));
            validateInputParameters(methodSymbol, functionDefinitionNode.location());
        }
    }

    private void validateRemoteFunction(FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = getMethodSymbol(this.context, functionDefinitionNode);
        if (Objects.nonNull(methodSymbol)) {
            Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
            returnTypeDesc.ifPresent(
                    typeSymbol -> validateReturnType(typeSymbol, functionDefinitionNode.location()));
            validateInputParameters(methodSymbol, functionDefinitionNode.location());
        }
    }

    private void validateResourceAccessorName(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
            Optional<String> methodName = resourceMethodSymbol.getName();
            if (methodName.isPresent()) {
                if (!methodName.get().equals(RESOURCE_FUNCTION_GET)) {
                    Location accessorLocation = getLocation(resourceMethodSymbol, location);
                    updateContext(this.context, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
                }
            } else {
                Location accessorLocation = getLocation(resourceMethodSymbol, location);
                updateContext(this.context, CompilationError.INVALID_RESOURCE_FUNCTION_ACCESSOR, accessorLocation);
            }
        }
    }

    private void validateResourcePath(MethodSymbol methodSymbol, Location location) {
        if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
            ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
            validateResourcePath(resourceMethodSymbol, location);
        }
    }

    private void validateResourcePath(ResourceMethodSymbol resourceMethodSymbol, Location location) {
        ResourcePath resourcePath = resourceMethodSymbol.resourcePath();
        if (resourcePath.kind() == ResourcePath.Kind.PATH_SEGMENT_LIST) {
            PathSegmentList pathSegmentList = (PathSegmentList) resourcePath;
            for (PathSegment pathSegment : pathSegmentList.list()) {
                if (pathSegment.pathSegmentKind() == PathSegment.Kind.NAMED_SEGMENT) {
                    if (isInvalidFieldName(pathSegment.signature())) {
                        updateContext(this.context, CompilationError.INVALID_FIELD_NAME, location);
                    }
                } else {
                    updateContext(this.context, CompilationError.INVALID_PATH_PARAMETERS, location);
                }
            }
        } else {
            updateContext(this.context, CompilationError.MISSING_RESOURCE_NAME, location);
        }
    }

    private void validateReturnType(TypeSymbol returnTypeDesc, Location location) {
        if (this.existingInputObjectTypes.contains(returnTypeDesc)) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.ANY || returnTypeDesc.typeKind() == TypeDescKind.ANYDATA) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ANY, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.UNION) {
            validateReturnTypeUnion(((UnionTypeSymbol) returnTypeDesc).memberTypeDescriptors(), location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.ARRAY) {
            // check member type
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) returnTypeDesc;
            validateReturnType(arrayTypeSymbol.memberTypeDescriptor(), location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateReturnTypeDefinitions((TypeReferenceTypeSymbol) returnTypeDesc, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.NIL) {
            // nil alone is invalid - must have a return type
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_NIL, location);
        } else if (returnTypeDesc.typeKind() == TypeDescKind.ERROR) {
            // error alone is invalid
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ERROR, location);
        } else if (hasInvalidReturnType(returnTypeDesc)) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
        }
    }

    private void validateReturnTypeDefinitions(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location) {
        if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.TYPE_DEFINITION) {
            TypeDefinitionSymbol typeDefinitionSymbol =
                    (TypeDefinitionSymbol) typeReferenceTypeSymbol.definition();
            if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
                if (this.existingInputObjectTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                    updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
                } else {
                    this.existingReturnTypes.add(typeReferenceTypeSymbol.typeDescriptor());
                }
                validateRecordFields((RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor(), location);
            } else {
                validateReturnType(typeDefinitionSymbol.typeDescriptor(), location);
            }
        } else if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.CLASS) {
            ClassSymbol classSymbol = (ClassSymbol) typeReferenceTypeSymbol.definition();
            Location classSymbolLocation = getLocation(classSymbol, location);
            if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, classSymbolLocation);
            } else {
                validateServiceClassDefinition(classSymbol, classSymbolLocation);
            }
        }
    }

    private void validateInputParameters(MethodSymbol methodSymbol, Location location) {
        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        if (functionTypeSymbol.params().isPresent()) {
            int i = 0;
            for (ParameterSymbol parameterSymbol : functionTypeSymbol.params().get()) {
                Location inputLocation = getLocation(parameterSymbol, location);
                TypeSymbol parameterTypeSymbol = parameterSymbol.typeDescriptor();
                if (isContextParameter(parameterTypeSymbol)) {
                    if (i != 0) {
                        updateContext(this.context, CompilationError.INVALID_LOCATION_FOR_CONTEXT_PARAMETER,
                                      inputLocation);
                    }
                } else {
                    validateInputParameterType(parameterSymbol.typeDescriptor(), inputLocation);
                }
                i++;
            }
        }
    }

    private void validateInputParameterType(TypeSymbol typeSymbol, Location location) {
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateUnionTypeInputParameter((UnionTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateTypeReferenceInputParameterType((TypeReferenceTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) typeSymbol;
            validateInputParameterType(arrayTypeSymbol.memberTypeDescriptor(), location);
        } else if (!isPrimitiveType(typeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_INPUT_PARAMETER_TYPE, location,
                          typeSymbol.getName().orElse(typeSymbol.typeKind().getName()));
        }
    }

    private void validateTypeReferenceInputParameterType(TypeReferenceTypeSymbol typeSymbol, Location location) {
        TypeSymbol typeDescriptor = typeSymbol.typeDescriptor();
        Symbol typeDefinition = typeSymbol.definition();
        if (typeSymbol.getName().isPresent()) {
            String typeName = typeSymbol.getName().get();
            if (typeDefinition.kind() == SymbolKind.ENUM) {
                return;
            }
            if (typeDescriptor.typeKind() == TypeDescKind.RECORD) {
                validateInputRecordType((RecordTypeSymbol) typeDescriptor, location);
            } else if (typeDescriptor.typeKind() == TypeDescKind.UNION) {
                validateUnionTypeInputParameter((UnionTypeSymbol) typeDescriptor, location);
            } else if (!isPrimitiveType(typeDescriptor)) {
                updateContext(this.context, CompilationError.INVALID_INPUT_PARAMETER_TYPE, location, typeName);
            }
        }
    }

    private void validateUnionTypeInputParameter(UnionTypeSymbol unionTypeSymbol, Location location) {
        boolean foundDataType = false;
        int dataTypeCount = 0;
        for (TypeSymbol memberType : unionTypeSymbol.userSpecifiedMemberTypes()) {
            if (memberType.typeKind() != TypeDescKind.ERROR && memberType.typeKind() != TypeDescKind.NIL) {
                foundDataType = true;
                dataTypeCount++;
                if (memberType.typeKind() != TypeDescKind.SINGLETON) {
                    validateInputParameterType(memberType, location);
                }
            }
        }
        if (!foundDataType) {
            updateContext(this.context, CompilationError.INVALID_INPUT_TYPE, location);
        } else if (dataTypeCount > 1) {
            updateContext(this.context, CompilationError.INVALID_INPUT_TYPE_UNION, location);
        }
    }

    private void validateInputRecordType(RecordTypeSymbol recordTypeSymbol, Location location) {
        if (this.existingReturnTypes.contains(recordTypeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, location);
        } else {
            this.existingInputObjectTypes.add(recordTypeSymbol);
            for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
                validateInputParameterType(recordFieldSymbol.typeDescriptor(), location);
            }
        }
    }

    private boolean hasInvalidReturnType(TypeSymbol returnTypeSymbol) {
        return returnTypeSymbol.typeKind() == TypeDescKind.MAP || returnTypeSymbol.typeKind() == TypeDescKind.JSON ||
                returnTypeSymbol.typeKind() == TypeDescKind.BYTE || returnTypeSymbol.typeKind() == TypeDescKind.OBJECT;
    }

    private void validateServiceClassDefinition(ClassSymbol classSymbol, Location location) {
        if (!this.visitedClassSymbols.contains(classSymbol)) {
            this.visitedClassSymbols.add(classSymbol);
            boolean resourceMethodFound = false;
            Map<String, MethodSymbol> methods = classSymbol.methods();
            for (MethodSymbol methodSymbol : methods.values()) {
                Location methodLocation = getLocation(methodSymbol, location);
                if (methodSymbol.kind() == SymbolKind.RESOURCE_METHOD) {
                    resourceMethodFound = true;
                    validateResourceAccessorName(methodSymbol, methodLocation);
                    validateResourcePath(methodSymbol, methodLocation);
                    Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
                    returnTypeDesc.ifPresent
                            (typeSymbol -> validateReturnType(typeSymbol, methodLocation));
                    validateInputParameters(methodSymbol, methodLocation);
                } else if (methodSymbol.qualifiers().contains(Qualifier.REMOTE)) {
                    updateContext(this.context, CompilationError.INVALID_FUNCTION, methodLocation);
                }
            }
            if (!resourceMethodFound) {
                updateContext(this.context, CompilationError.MISSING_RESOURCE_FUNCTIONS, location);
            }
        }
    }

    private boolean isRecordType(TypeSymbol returnTypeSymbol) {
        TypeDefinitionSymbol definitionSymbol =
                (TypeDefinitionSymbol) ((TypeReferenceTypeSymbol) returnTypeSymbol).definition();
        return definitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD;
    }

    private boolean isPrimitiveType(TypeSymbol returnType) {
        return returnType.typeKind().isStringType() ||
                returnType.typeKind() == TypeDescKind.INT ||
                returnType.typeKind() == TypeDescKind.FLOAT ||
                returnType.typeKind() == TypeDescKind.BOOLEAN ||
                returnType.typeKind() == TypeDescKind.DECIMAL;
    }

    private void validateReturnTypeUnion(List<TypeSymbol> returnTypeMembers, Location location) {
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
                            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
                        } else {
                            if (this.existingInputObjectTypes.contains(returnType)) {
                                updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT,
                                              location);
                            } else {
                                this.existingReturnTypes.add(returnType);
                            }
                            TypeDefinitionSymbol typeDefinitionSymbol =
                                    (TypeDefinitionSymbol) ((TypeReferenceTypeSymbol) returnType).definition();
                            Map<String, RecordFieldSymbol> memberMap = ((RecordTypeSymbol) typeDefinitionSymbol
                                    .typeDescriptor()).fieldDescriptors();
                            for (RecordFieldSymbol fields : memberMap.values()) {
                                if (fields.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE) {
                                    if (this.existingInputObjectTypes.contains(fields.typeDescriptor())) {
                                        updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT,
                                                      location);
                                    } else {
                                        this.existingReturnTypes.add(fields.typeDescriptor());
                                    }
                                }
                            }
                            recordTypes++;
                        }
                    } else if (((TypeReferenceTypeSymbol) returnType).definition().kind() == SymbolKind.CLASS) {
                        ClassSymbol classSymbol = (ClassSymbol) ((TypeReferenceTypeSymbol) returnType).definition();
                        Location classSymbolLocation = getLocation(classSymbol, location);
                        if (!classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, classSymbolLocation);
                        } else {
                            validateServiceClassDefinition(classSymbol, classSymbolLocation);
                            // if distinctServices is false (one of the services is not distinct), skip setting it again
                            if (distinctServices) {
                                distinctServices = classSymbol.qualifiers().contains(Qualifier.DISTINCT);
                            }
                            serviceTypes++;
                        }
                    }
                } else {
                    if (hasInvalidReturnType(returnType)) {
                        updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
                    }
                }

                if (isPrimitiveType(returnType)) {
                    primitiveType++;
                } else {
                    type++;
                }
            } // nil in a union in valid, no validation
        }

        // has multiple services and if at least one of them are not distinct
        if (serviceTypes > 1 && !distinctServices) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_MULTIPLE_SERVICES, location);
        }
        if (recordTypes > 1) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
        }
        if (type == 0 && primitiveType == 0) { // error? - invalid
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ERROR_OR_NIL, location);
        } else if (primitiveType > 0 && type > 0) { // Person|string - invalid
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
        } else if (primitiveType > 1) { // string|int - invalid
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
        }
    }

    private void validateRecordFields(RecordTypeSymbol recordTypeSymbol, Location location) {
        Map<String, RecordFieldSymbol> recordFieldSymbolMap = recordTypeSymbol.fieldDescriptors();
        for (RecordFieldSymbol recordField : recordFieldSymbolMap.values()) {
            if (recordField.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE ||
                    recordField.typeDescriptor().typeKind() == TypeDescKind.UNION) {
                Location fieldLocation = getLocation(recordField, location);
                validateReturnType(recordField.typeDescriptor(), fieldLocation);
            } else {
                if (isInvalidFieldName(recordField.getName().orElse(""))) {
                    Location fieldLocation = getLocation(recordField, location);
                    updateContext(this.context, CompilationError.INVALID_FIELD_NAME, fieldLocation);
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

    private boolean isFileUploadParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getModule().isPresent()) {
            ModuleSymbol moduleSymbol = typeSymbol.getModule().get();
            if (typeSymbol.getName().isPresent()) {
                return moduleSymbol.id().moduleName().equals(PACKAGE_PREFIX) && moduleSymbol.id().orgName().equals(
                        PACKAGE_ORG) && typeSymbol.getName().get().equals(FILE_UPLOAD_IDENTIFIER);
            }
        }
        return false;
    }
}
