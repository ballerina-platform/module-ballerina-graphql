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
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
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
    private int arrayDimension = 0;

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
            validateInputParameters(methodSymbol, functionDefinitionNode.location(), true);
        }
    }

    private void validateRemoteFunction(FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = getMethodSymbol(this.context, functionDefinitionNode);
        if (Objects.nonNull(methodSymbol)) {
            Optional<TypeSymbol> returnTypeDesc = methodSymbol.typeDescriptor().returnTypeDescriptor();
            returnTypeDesc.ifPresent(
                    typeSymbol -> validateReturnType(typeSymbol, functionDefinitionNode.location()));
            validateInputParameters(methodSymbol, functionDefinitionNode.location(), false);
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

    private void validateReturnType(TypeSymbol typeSymbol, Location location) {
        if (this.existingInputObjectTypes.contains(typeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ANY || typeSymbol.typeKind() == TypeDescKind.ANYDATA) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ANY, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateReturnTypeUnion((UnionTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            // check member type
            ArrayTypeSymbol arrayTypeSymbol = (ArrayTypeSymbol) typeSymbol;
            validateReturnType(arrayTypeSymbol.memberTypeDescriptor(), location);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateReturnTypeDefinitions((TypeReferenceTypeSymbol) typeSymbol, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            TypeSymbol effectiveType = getEffectiveType((IntersectionTypeSymbol) typeSymbol, location);
            if (effectiveType != null) {
                validateReturnType(effectiveType, location);
            }
        } else if (typeSymbol.typeKind() == TypeDescKind.NIL) {
            // nil alone is invalid - must have a return type
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_NIL, location);
        } else if (typeSymbol.typeKind() == TypeDescKind.ERROR) {
            // error alone is invalid
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_ERROR, location);
        } else if (hasInvalidReturnType(typeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
        }
    }

    private void validateReturnTypeDefinitions(TypeReferenceTypeSymbol typeReferenceTypeSymbol, Location location) {
        if (typeReferenceTypeSymbol.definition().kind() == SymbolKind.TYPE_DEFINITION) {
            TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) typeReferenceTypeSymbol.definition();
            if (typeReferenceTypeSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
                if (this.existingInputObjectTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                    updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
                } else {
                    if (this.existingReturnTypes.contains(typeReferenceTypeSymbol.typeDescriptor())) {
                        return;
                    }
                    this.existingReturnTypes.add(typeReferenceTypeSymbol.typeDescriptor());
                    validateRecordFields((RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor(), location);
                }
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

    private void validateInputParameters(MethodSymbol methodSymbol, Location location, boolean isResourceMethod) {
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
                    validateInputParameterType(parameterSymbol.typeDescriptor(), inputLocation, isResourceMethod);
                }
                i++;
            }
        }
    }

    private void validateInputParameterType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        if (isFileUploadParameter(typeSymbol)) {
            if (this.arrayDimension > 1) {
                updateContext(this.context, CompilationError.MULTI_DIMENSIONAL_UPLOAD_ARRAY, location);
            }
            if (isResourceMethod) {
                updateContext(this.context, CompilationError.INVALID_FILE_UPLOAD_IN_RESOURCE_FUNCTION, location);
            }
        } else {
            validateInputType(typeSymbol, location, isResourceMethod);
        }
    }

    private void validateInputType(TypeSymbol typeSymbol, Location location, boolean isResourceMethod) {
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateInputParameterType((UnionTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            validateInputParameterType((TypeReferenceTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.ARRAY) {
            validateInputParameterType((ArrayTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            validateInputParameterType((IntersectionTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.RECORD) {
            validateInputParameterType((RecordTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            validateInputParameterType((UnionTypeSymbol) typeSymbol, location, isResourceMethod);
        } else if (!isPrimitiveType(typeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_INPUT_PARAMETER_TYPE, location,
                          typeSymbol.getName().orElse(typeSymbol.typeKind().getName()));
        }
    }

    private void validateInputParameterType(ArrayTypeSymbol arrayTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        this.arrayDimension++;
        TypeSymbol memberTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
        validateInputParameterType(memberTypeSymbol, location, isResourceMethod);
        this.arrayDimension--;
    }

    private void validateInputParameterType(TypeReferenceTypeSymbol typeSymbol, Location location,
                                            boolean isResourceMethod) {
        TypeSymbol typeDescriptor = typeSymbol.typeDescriptor();
        Symbol typeDefinition = typeSymbol.definition();
        if (typeDefinition.kind() == SymbolKind.ENUM) {
            return;
        }
        validateInputParameterType(typeDescriptor, location, isResourceMethod);
    }

    private void validateInputParameterType(UnionTypeSymbol unionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        boolean foundDataType = false;
        int dataTypeCount = 0;
        for (TypeSymbol memberType : unionTypeSymbol.userSpecifiedMemberTypes()) {
            if (memberType.typeKind() != TypeDescKind.ERROR && memberType.typeKind() != TypeDescKind.NIL) {
                foundDataType = true;
                dataTypeCount++;
                if (memberType.typeKind() != TypeDescKind.SINGLETON) {
                    validateInputParameterType(memberType, location, isResourceMethod);
                }
            }
        }
        if (!foundDataType) {
            updateContext(this.context, CompilationError.INVALID_INPUT_TYPE, location);
        } else if (dataTypeCount > 1) {
            updateContext(this.context, CompilationError.INVALID_INPUT_TYPE_UNION, location);
        }
    }

    private void validateInputParameterType(IntersectionTypeSymbol intersectionTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol, location);
        if (effectiveType != null) {
            validateInputParameterType(effectiveType, location, isResourceMethod);
        }
    }

    private TypeSymbol getEffectiveType(IntersectionTypeSymbol intersectionTypeSymbol, Location location) {
        List<TypeSymbol> effectiveTypes = new ArrayList<>();
        for (TypeSymbol typeSymbol : intersectionTypeSymbol.memberTypeDescriptors()) {
            if (typeSymbol.typeKind() == TypeDescKind.READONLY) {
                continue;
            }
            effectiveTypes.add(typeSymbol);
        }
        if (effectiveTypes.size() == 1) {
            return effectiveTypes.get(0);
        }
        updateContext(this.context, CompilationError.INVALID_INTERSECTION_Type, location);
        return null;
    }

    private void validateInputParameterType(RecordTypeSymbol recordTypeSymbol, Location location,
                                            boolean isResourceMethod) {
        if (this.existingReturnTypes.contains(recordTypeSymbol)) {
            updateContext(this.context, CompilationError.INVALID_RESOURCE_INPUT_OBJECT_PARAM, location);
        } else {
            if (this.existingInputObjectTypes.contains(recordTypeSymbol)) {
                return;
            }
            this.existingInputObjectTypes.add(recordTypeSymbol);
            for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
                validateInputType(recordFieldSymbol.typeDescriptor(), location, isResourceMethod);
            }
        }
    }

    private boolean hasInvalidReturnType(TypeSymbol typeSymbol) {
        return typeSymbol.typeKind() == TypeDescKind.MAP || typeSymbol.typeKind() == TypeDescKind.JSON ||
                typeSymbol.typeKind() == TypeDescKind.BYTE || typeSymbol.typeKind() == TypeDescKind.OBJECT ||
                typeSymbol.typeKind() == TypeDescKind.STREAM;
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
                    validateInputParameters(methodSymbol, methodLocation, true);
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

    private void validateReturnTypeUnion(UnionTypeSymbol unionTypeSymbol, Location location) {
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

        for (TypeSymbol memberType : unionTypeSymbol.memberTypeDescriptors()) {
            if (memberType.typeKind() == TypeDescKind.NIL || memberType.typeKind() == TypeDescKind.ERROR) {
                continue;
            }
            if (memberType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
                TypeReferenceTypeSymbol typeSymbol = (TypeReferenceTypeSymbol) memberType;
                Symbol typeDefinition = typeSymbol.definition();
                if (typeDefinition.kind() == SymbolKind.TYPE_DEFINITION) {
                    TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) typeDefinition;
                    if (!isRecordType(memberType)) {
                        updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
                    } else {
                        RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
                        if (this.existingInputObjectTypes.contains(memberType)) {
                            updateContext(this.context, CompilationError.INVALID_RETURN_TYPE_INPUT_OBJECT, location);
                        } else {
                            this.existingReturnTypes.add(memberType);
                        }
                        validateRecordFields(recordTypeSymbol, location);
                        recordTypes++;
                    }
                } else if (typeDefinition.kind() == SymbolKind.CLASS) {
                    ClassSymbol classSymbol = (ClassSymbol) ((TypeReferenceTypeSymbol) memberType).definition();
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
                if (hasInvalidReturnType(memberType)) {
                    updateContext(this.context, CompilationError.INVALID_RETURN_TYPE, location);
                }
            }

            if (isPrimitiveType(memberType)) {
                primitiveType++;
            } else {
                type++;
            }
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
            validateReturnType(recordField.typeDescriptor(), location);
            if (isInvalidFieldName(recordField.getName().orElse(""))) {
                updateContext(this.context, CompilationError.INVALID_FIELD_NAME, location);
            }
        }
    }

    private boolean isContextParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (isNonGraphqlPackageSymbol(typeSymbol)) {
            return false;
        }
        return CONTEXT_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    private boolean isFileUploadParameter(TypeSymbol typeSymbol) {
        if (typeSymbol.getName().isEmpty()) {
            return false;
        }
        if (isNonGraphqlPackageSymbol(typeSymbol)) {
            return false;
        }
        return FILE_UPLOAD_IDENTIFIER.equals(typeSymbol.getName().get());
    }

    private boolean isNonGraphqlPackageSymbol(TypeSymbol typeSymbol) {
        if (typeSymbol.getModule().isEmpty()) {
            return true;
        }
        ModuleSymbol moduleSymbol = typeSymbol.getModule().get();
        return !PACKAGE_PREFIX.equals(moduleSymbol.id().moduleName()) ||
                !PACKAGE_ORG.equals(moduleSymbol.id().orgName());
    }
}
