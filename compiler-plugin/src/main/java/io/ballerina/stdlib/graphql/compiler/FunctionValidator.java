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

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.graphql.compiler.Utils.CompilationError;
import static io.ballerina.stdlib.graphql.compiler.Utils.RESOURCE_FUNCTION_GET;
import static io.ballerina.stdlib.graphql.compiler.Utils.getLocation;
import static io.ballerina.stdlib.graphql.compiler.Utils.getMethodSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.updateContext;

/**
 * Validate functions in Ballerina GraphQL services.
 */
public class FunctionValidator {
    private final Set<ClassSymbol> visitedClassSymbols = new HashSet<>();
    private final Map<String, Set<String>> classesAndResourceFunctions = new HashMap<>();
    private final Map<String, Set<ClassSymbol>> typeInclusions = new HashMap<>();
    private final Set<String> eligibleInterfaces = new HashSet<>();

    public void validate(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        NodeList<Node> memberNodes = serviceDeclarationNode.members();
        populatePossibleInterfaces(context.semanticModel().moduleSymbols());
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
        if (!resourceFunctionFound) {
            updateContext(context, CompilationError.MISSING_RESOURCE_FUNCTIONS, serviceDeclarationNode.location());
        }
    }

    private void populatePossibleInterfaces(List<Symbol> moduleSymbols) {
        for (Symbol symbol : moduleSymbols) {
            if (symbol.kind() == SymbolKind.CLASS) {
                ClassSymbol classSymbol = (ClassSymbol) symbol;

                // for each ClassSymbol, keep track of all type inclusions(implemented interfaces)
                List<TypeSymbol> inclusions = classSymbol.typeInclusions();
                for (TypeSymbol typeInclusion : inclusions) {
                    if (typeInclusion.typeKind() == TypeDescKind.TYPE_REFERENCE) {
                        String typeName = typeInclusion.getName().isPresent() ? typeInclusion.getName().get() : "";
                        if (typeInclusions.containsKey(typeName)) {
                            typeInclusions.get(typeName).add(classSymbol);
                        } else {
                            Set<ClassSymbol> childClasses = new HashSet<>();
                            childClasses.add(classSymbol);
                            typeInclusions.put(typeName, childClasses);
                        }
                    }
                }
                // for each ClassSymbol, track all resource functions
                if (classSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                    String className = classSymbol.getName().isPresent() ?
                            classSymbol.getName().get() : "";
                    if (!classesAndResourceFunctions.containsKey(className)) {
                        Collection<MethodSymbol> methods = classSymbol.methods().values();
                        Set<String> resourceMethods = new HashSet<>();
                         for (MethodSymbol method: methods) {
                            if (method.qualifiers().contains(Qualifier.RESOURCE)) {
                                resourceMethods.add(method.getName().get() + " "
                                        + ((ResourceMethodSymbol) method).resourcePath().signature());
                            }
                        }
                        classesAndResourceFunctions.put(className, resourceMethods);
                    }
                    // for each ClassSymbol, add to eligibleInterfaces if it is a distinct service
                    if (classSymbol.qualifiers().contains(Qualifier.DISTINCT)) {
                        eligibleInterfaces.add(className);
                    }
                }
            }
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
        if (returnTypeDesc.typeKind() == TypeDescKind.ANY || returnTypeDesc.typeKind() == TypeDescKind.ANYDATA) {
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
                String className = classSymbol.getName().isPresent() ? classSymbol.getName().get() : "";
                // if this service is an interface
                if (typeInclusions.containsKey(className)) {
                    validateImplementedClasses(classSymbol, context);
                }
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
                        Location inputLocation = getLocation(param, location);
                        updateContext(context, CompilationError.INVALID_RESOURCE_INPUT_PARAM, inputLocation);
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
            }
        }
        return !hasPrimitiveType(inputTypeSymbol);
    }

    private boolean hasInvalidReturnType(TypeSymbol returnTypeSymbol) {
        return returnTypeSymbol.typeKind() == TypeDescKind.MAP || returnTypeSymbol.typeKind() == TypeDescKind.JSON ||
                returnTypeSymbol.typeKind() == TypeDescKind.BYTE || returnTypeSymbol.typeKind() == TypeDescKind.OBJECT;
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
            if (!classSymbol.typeInclusions().isEmpty()) {
                implementedValidInterface(classSymbol, context);
            }
            if (!resourceMethodFound) {
                updateContext(context, CompilationError.MISSING_RESOURCE_FUNCTIONS,
                        classSymbol.getLocation().get());
            }
        }
    }

    // checks if the returning type is an interface and if so, if the classes implementing this
    // interface has all the resource functions
    private void validateImplementedClasses(ClassSymbol classSymbol, SyntaxNodeAnalysisContext context) {
        if (!classSymbol.qualifiers().contains(Qualifier.DISTINCT)) {
            updateContext(context, CompilationError.INVALID_INTERFACE,
                    classSymbol.getLocation().get());
        }
        Set<ClassSymbol> childClasses = typeInclusions.get(classSymbol.getName().get());
        Set<String> resourceFunctionsInInterface = classesAndResourceFunctions.get(classSymbol.getName().get());
        for (ClassSymbol childClass : childClasses) {
            if (!childClass.methods().keySet().containsAll(resourceFunctionsInInterface)) {
                updateContext(context, CompilationError.INVALID_INTERFACE_IMPLEMENTATION,
                        childClass.getLocation().get());
            }
        }
    }

    // if the returning service has no resource function, this checks for implemented interfaces with resource functions
    private void implementedValidInterface(ClassSymbol classSymbol,
                                           SyntaxNodeAnalysisContext context) {
        List<TypeSymbol> typeInclusions = classSymbol.typeInclusions();
        for (TypeSymbol typeInclusion : typeInclusions) {
            if (typeInclusion.typeKind() == TypeDescKind.TYPE_REFERENCE) {
                TypeReferenceTypeSymbol inclusionSymbol = (TypeReferenceTypeSymbol) typeInclusion;
                if (inclusionSymbol.definition().kind() == SymbolKind.CLASS) {
                    ClassSymbol inclusionClassSymbol = (ClassSymbol) inclusionSymbol.definition();
                    if (inclusionClassSymbol.qualifiers().contains(Qualifier.SERVICE)) {
                        String className = inclusionClassSymbol.getName().isPresent() ?
                                inclusionClassSymbol.getName().get() : "";
                        // checks if the type inclusion if a valid service
                        validateServiceClassDefinition(inclusionClassSymbol, inclusionSymbol.getLocation().get(),
                                context);
                        // checks if the type inclusion is a valid interface
                        if (eligibleInterfaces.contains(className) &&
                                classesAndResourceFunctions.containsKey(className)) {
                            Set<String> methods = classesAndResourceFunctions.get(className);
                            if (!implementedAllResourceFunctions(methods, classSymbol.methods().keySet())) {
                                updateContext(context, CompilationError.INVALID_INTERFACE_IMPLEMENTATION,
                                        inclusionClassSymbol.getLocation().get());
                            }
                            // checks interfaces implemented by the interface
                            if (!inclusionClassSymbol.typeInclusions().isEmpty()) {
                                implementedValidInterface(inclusionClassSymbol, context);
                            }
                        } else {
                            updateContext(context, CompilationError.INVALID_INTERFACE,
                                    inclusionClassSymbol.getLocation().get());
                        }
                    } else {
                        updateContext(context, CompilationError.INVALID_INTERFACE,
                                inclusionClassSymbol.getLocation().get());
                    }
                }
            }
        }
    }

    private boolean implementedAllResourceFunctions(Set<String> interfaceMethods, Set<String> classMethods) {
        return classMethods.containsAll(interfaceMethods);
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
            if (recordField.typeDescriptor().typeKind() == TypeDescKind.TYPE_REFERENCE) {
                validateReturnType(recordField.typeDescriptor(), location, context);
            } else {
                if (Utils.isInvalidFieldName(recordField.getName().orElse(""))) {
                    Location fieldLocation = getLocation(recordField, location);
                    updateContext(context, CompilationError.INVALID_FIELD_NAME, fieldLocation);
                }
            }
        }
    }
}
