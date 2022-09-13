/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.schema.generator;

import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.ConstantSymbol;
import io.ballerina.compiler.api.symbols.EnumSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterKind;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.StreamTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.SymbolKind;
import io.ballerina.compiler.api.symbols.TableTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.util.PathSegment;
import io.ballerina.stdlib.graphql.compiler.schema.types.DefaultDirective;
import io.ballerina.stdlib.graphql.compiler.schema.types.Description;
import io.ballerina.stdlib.graphql.compiler.schema.types.Directive;
import io.ballerina.stdlib.graphql.compiler.schema.types.EnumValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.Field;
import io.ballerina.stdlib.graphql.compiler.schema.types.InputValue;
import io.ballerina.stdlib.graphql.compiler.schema.types.ScalarType;
import io.ballerina.stdlib.graphql.compiler.schema.types.Schema;
import io.ballerina.stdlib.graphql.compiler.schema.types.Type;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeKind;
import io.ballerina.stdlib.graphql.compiler.schema.types.TypeName;
import io.ballerina.stdlib.graphql.compiler.service.InterfaceFinder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.getAccessor;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveType;
import static io.ballerina.stdlib.graphql.compiler.Utils.getEffectiveTypes;
import static io.ballerina.stdlib.graphql.compiler.Utils.isContextParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isFileUploadParameter;
import static io.ballerina.stdlib.graphql.compiler.Utils.isRemoteMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.MAP_KEY_ARGUMENT_DESCRIPTION;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.MAP_KEY_ARGUMENT_NAME;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDeprecationReason;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getDescription;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getTypeName;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.getWrapperType;
import static io.ballerina.stdlib.graphql.compiler.schema.generator.GeneratorUtils.removeEscapeCharacter;
import static io.ballerina.stdlib.graphql.compiler.service.validator.ValidatorUtils.RESOURCE_FUNCTION_GET;

/**
 * Generates the GraphQL schema from a given, valid, Ballerina service.
 */
public class SchemaGenerator {

    private static final String IF_ARG_NAME = "if";
    private static final String REASON_ARG_NAME = "reason";

    private final ServiceDeclarationSymbol serviceDeclarationSymbol;
    private final InterfaceFinder interfaceFinder;
    private final Schema schema;

    public SchemaGenerator(ServiceDeclarationSymbol serviceDeclarationSymbol, InterfaceFinder interfaceFinder) {
        this.serviceDeclarationSymbol = serviceDeclarationSymbol;
        this.interfaceFinder = interfaceFinder;
        this.schema = new Schema(getDescription(serviceDeclarationSymbol));
    }

    private static boolean isNilable(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() != TypeDescKind.UNION) {
            return false;
        }
        UnionTypeSymbol unionTypeSymbol = (UnionTypeSymbol) typeSymbol;
        for (TypeSymbol memberType : unionTypeSymbol.memberTypeDescriptors()) {
            if (memberType.typeKind() == TypeDescKind.NIL) {
                return true;
            }
        }
        return false;
    }

    private static String getParameterDescription(String parameterName, MethodSymbol methodSymbol) {
        if (methodSymbol.documentation().isEmpty()) {
            return null;
        }
        return methodSymbol.documentation().get().parameterMap().get(parameterName);
    }

    public Schema generate() {
        findRootTypes(this.serviceDeclarationSymbol);
        findIntrospectionTypes();
        return this.schema;
    }

    private void findIntrospectionTypes() {
        IntrospectionTypeCreator introspectionTypeCreator = new IntrospectionTypeCreator(this.schema);
        introspectionTypeCreator.addIntrospectionTypes();
        addDefaultDirectives();
    }

    private void findRootTypes(ServiceDeclarationSymbol serviceDeclarationSymbol) {
        Type queryType = addType(TypeName.QUERY);
        for (MethodSymbol methodSymbol : serviceDeclarationSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) methodSymbol;
                String accessor = getAccessor(resourceMethodSymbol);
                if (RESOURCE_FUNCTION_GET.equals(accessor)) {
                    queryType.addField(getField((resourceMethodSymbol)));
                } else {
                    Type subscriptionType = addType(TypeName.SUBSCRIPTION);
                    subscriptionType.addField(getField(resourceMethodSymbol));
                }
            } else if (isRemoteMethod(methodSymbol)) {
                Type mutationType = addType(TypeName.MUTATION);
                mutationType.addField(getField(methodSymbol));
            }
        }
        this.schema.setQueryType(queryType);
        if (this.schema.containsType(TypeName.MUTATION.getName())) {
            this.schema.setMutationType(this.schema.getType(TypeName.MUTATION.getName()));
        }
        if (this.schema.containsType(TypeName.SUBSCRIPTION.getName())) {
            this.schema.setSubscriptionType(this.schema.getType(TypeName.SUBSCRIPTION.getName()));
        }
    }

    private Field getField(ResourceMethodSymbol methodSymbol) {
        return getField(methodSymbol, ((PathSegmentList) methodSymbol.resourcePath()).list());
    }

    private Field getField(ResourceMethodSymbol methodSymbol, List<PathSegment> list) {
        if (list.size() == 1) {
            boolean isDeprecated = methodSymbol.deprecated();
            String deprecationReason = getDeprecationReason(methodSymbol);
            Type fieldType = getType(methodSymbol);
            Field field = new Field(list.get(0).signature(), getDescription(methodSymbol), fieldType, isDeprecated,
                                    deprecationReason);
            addArgs(field, methodSymbol);
            return field;
        } else {
            PathSegment pathSegment = list.get(0);
            Type type = getType(methodSymbol, pathSegment, list);
            return new Field(pathSegment.signature(), getWrapperType(type, TypeKind.NON_NULL));
        }
    }

    private Type getType(ResourceMethodSymbol methodSymbol, PathSegment pathSegment, List<PathSegment> list) {
        Type type = addType(pathSegment.signature(), TypeKind.OBJECT, Description.GENERATED_TYPE.getDescription());
        List<PathSegment> remainingPathList = list.subList(1, list.size());
        type.addField(getField(methodSymbol, remainingPathList));
        return type;
    }

    private Field getField(MethodSymbol methodSymbol) {
        boolean isDeprecated = methodSymbol.deprecated();
        String deprecationReason = getDeprecationReason(methodSymbol);
        if (methodSymbol.getName().isEmpty()) {
            return null;
        }
        Type fieldType = getType(methodSymbol);
        Field field = new Field(methodSymbol.getName().get(), getDescription(methodSymbol), fieldType, isDeprecated,
                                deprecationReason);
        addArgs(field, methodSymbol);
        return field;
    }

    private void addArgs(Field field, MethodSymbol methodSymbol) {
        if (methodSymbol.typeDescriptor().params().isEmpty()) {
            return;
        }
        for (ParameterSymbol parameterSymbol : methodSymbol.typeDescriptor().params().get()) {
            if (isContextParameter(parameterSymbol.typeDescriptor()) || parameterSymbol.getName().isEmpty()) {
                continue;
            }
            String parameterName = parameterSymbol.getName().get();
            String description = getParameterDescription(parameterName, methodSymbol);
            field.addArg(getArg(parameterName, description, parameterSymbol));
        }
    }

    private InputValue getArg(String parameterName, String description, ParameterSymbol parameterSymbol) {
        Type type = getInputFieldType(parameterSymbol.typeDescriptor());
        String defaultValue = getDefaultValue(parameterSymbol);
        return new InputValue(parameterName, type, description, defaultValue);
    }

    private Type getType(MethodSymbol methodSymbol) {
        if (methodSymbol.typeDescriptor().returnTypeDescriptor().isEmpty()) {
            return null;
        }
        TypeSymbol typeSymbol = methodSymbol.typeDescriptor().returnTypeDescriptor().get();
        return getFieldType(typeSymbol);
    }

    private Type getType(TypeSymbol typeSymbol) {
        String typeName = getTypeName(typeSymbol);
        if (this.schema.containsType(typeName)) {
            return this.schema.getType(typeName);
        }
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                return addType(ScalarType.STRING);
            case INT:
                return addType(ScalarType.INT);
            case FLOAT:
                return addType(ScalarType.FLOAT);
            case BOOLEAN:
                return addType(ScalarType.BOOLEAN);
            case DECIMAL:
                return addType(ScalarType.DECIMAL);
            case TYPE_REFERENCE:
                return getType((TypeReferenceTypeSymbol) typeSymbol, typeName);
            case ARRAY:
                return getType((ArrayTypeSymbol) typeSymbol);
            case UNION:
                return getType(typeName, null, (UnionTypeSymbol) typeSymbol);
            case INTERSECTION:
                return getType(null, null, null, (IntersectionTypeSymbol) typeSymbol);
            case STREAM:
                return getType(((StreamTypeSymbol) typeSymbol).typeParameter());
        }
        return null;
    }

    private Type addType(ScalarType scalarType) {
        return this.schema.addType(scalarType);
    }

    private Type addType(TypeName typeName) {
        return addType(typeName.getName(), TypeKind.OBJECT, null);
    }

    private Type addType(String name, TypeKind kind, String description) {
        return this.schema.addType(name, kind, description);
    }

    private Type getType(TypeReferenceTypeSymbol typeSymbol, String name) {
        if (typeSymbol.getName().isEmpty()) {
            return null;
        }
        Symbol definitionSymbol = typeSymbol.definition();
        if (definitionSymbol.kind() == SymbolKind.TYPE_DEFINITION) {
            return getType(name, (TypeDefinitionSymbol) definitionSymbol);
        } else if (definitionSymbol.kind() == SymbolKind.CLASS) {
            return getType(name, (ClassSymbol) definitionSymbol);
        } else if (definitionSymbol.kind() == SymbolKind.ENUM) {
            return getType(name, (EnumSymbol) definitionSymbol);
        }
        return null;
    }

    private Type getType(ArrayTypeSymbol arrayTypeSymbol) {
        TypeSymbol memberTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
        return getWrapperType(getFieldType(memberTypeSymbol), TypeKind.LIST);
    }

    private Type getType(String name, TypeDefinitionSymbol typeDefinitionSymbol) {
        String description = getDescription(typeDefinitionSymbol);
        Map<String, String> parameterMap;
        if (typeDefinitionSymbol.documentation().isEmpty()) {
            parameterMap = new HashMap<>();
        } else {
            parameterMap = typeDefinitionSymbol.documentation().get().parameterMap();
        }
        if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.RECORD) {
            RecordTypeSymbol recordType = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
            return getType(name, description, parameterMap, recordType);
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.UNION) {
            return getType(name, description, (UnionTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.INTERSECTION) {
            IntersectionTypeSymbol intersectionType = (IntersectionTypeSymbol) typeDefinitionSymbol.typeDescriptor();
            return getType(name, description, parameterMap, intersectionType);
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.TABLE) {
            return getType((TableTypeSymbol) typeDefinitionSymbol.typeDescriptor());
        } else if (typeDefinitionSymbol.typeDescriptor().typeKind() == TypeDescKind.OBJECT) {
            return getTypeFromObjectDefinition(name, typeDefinitionSymbol);
        }
        return null;
    }

    private Type getTypeFromObjectDefinition(String name, TypeDefinitionSymbol typeDefinitionSymbol) {
        String description = getDescription(typeDefinitionSymbol);
        Type objectType = addType(name, TypeKind.INTERFACE, description);
        getTypesFromInterface(name, objectType);

        ObjectTypeSymbol objectTypeSymbol = (ObjectTypeSymbol) typeDefinitionSymbol.typeDescriptor();
        for (MethodSymbol methodSymbol : objectTypeSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                objectType.addField(getField((ResourceMethodSymbol) methodSymbol));
            }
        }
        return objectType;
    }

    private Type getType(String name, ClassSymbol classSymbol) {
        String description = getDescription(classSymbol);
        Type objectType = addType(name, TypeKind.OBJECT, description);

        for (MethodSymbol methodSymbol : classSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                objectType.addField(getField((ResourceMethodSymbol) methodSymbol));
            }
        }
        return objectType;
    }

    private void getTypesFromInterface(String typeName, Type interfaceType) {
        // Implementations can only contain class symbols or object type definitions
        List<Symbol> implementations = this.interfaceFinder.getImplementations(typeName);
        for (Symbol implementation : implementations) {
            Type implementedType;
            // When adding an implementation, the name is already checked. Therefore, no need to check isEmpty().
            // noinspection OptionalGetWithoutIsPresent
            String implementationName = implementation.getName().get();
            if (implementation.kind() == SymbolKind.CLASS) {
                implementedType = getType(implementationName, (ClassSymbol) implementation);
            } else {
                implementedType = getTypeFromObjectDefinition(implementationName,
                                                              (TypeDefinitionSymbol) implementation);
            }

            interfaceType.addPossibleType(implementedType);
            implementedType.addInterface(interfaceType);
        }
    }

    private Type getType(String name, EnumSymbol enumSymbol) {
        String description = getDescription(enumSymbol);
        Type enumType = addType(name, TypeKind.ENUM, description);
        for (ConstantSymbol enumMember : enumSymbol.members()) {
            addEnumValueToType(enumType, enumMember);
        }
        return enumType;
    }

    private Type getType(String name, String description, Map<String, String> fieldMap,
                         RecordTypeSymbol recordTypeSymbol) {
        Type objectType = addType(name, TypeKind.OBJECT, description);
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            if (recordFieldSymbol.getName().isEmpty()) {
                continue;
            }
            String fieldDescription = fieldMap.get(removeEscapeCharacter(recordFieldSymbol.getName().get()));
            objectType.addField(getField(recordFieldSymbol, fieldDescription));
        }
        return objectType;
    }

    private Field getField(RecordFieldSymbol recordFieldSymbol, String description) {
        if (recordFieldSymbol.getName().isEmpty()) {
            return null;
        }
        String name = recordFieldSymbol.getName().get();
        Field field = new Field(name, description);
        TypeSymbol typeSymbol = recordFieldSymbol.typeDescriptor();
        Type type;
        if (typeSymbol.typeKind() == TypeDescKind.MAP) {
            type = getType(((MapTypeSymbol) typeSymbol).typeParam());
            Type argType = getWrapperType(addType(ScalarType.STRING), TypeKind.NON_NULL);
            field.addArg(new InputValue(MAP_KEY_ARGUMENT_NAME, argType, MAP_KEY_ARGUMENT_DESCRIPTION, null));
        } else {
            type = getType(typeSymbol);
        }
        if (!isNilable(typeSymbol) && !recordFieldSymbol.isOptional()) {
            type = getWrapperType(type, TypeKind.NON_NULL);
        }
        field.setType(type);
        return field;
    }

    private Type getType(String name, String description, UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        if (effectiveTypes.size() == 1) {
            return getType(effectiveTypes.get(0));
        }

        String typeName = name == null ? getTypeName(effectiveTypes) : name;
        String typeDescription = description == null ? Description.GENERATED_UNION_TYPE.getDescription() : description;
        Type unionType = addType(typeName, TypeKind.UNION, typeDescription);

        for (TypeSymbol typeSymbol : effectiveTypes) {
            Type possibleType = getType(typeSymbol);
            String memberTypeName = getTypeName(typeSymbol);
            if (memberTypeName == null) {
                continue;
            }
            unionType.addPossibleType(possibleType);
        }
        return unionType;
    }

    private Type getType(String name, String description, Map<String, String> parameterMap,
                         IntersectionTypeSymbol intersectionTypeSymbol) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (name == null) {
            return getType(effectiveType);
        } else {
            if (parameterMap == null) {
                parameterMap = new HashMap<>();
            }
            return getType(name, description, parameterMap, (RecordTypeSymbol) effectiveType);
        }
    }

    private Type getType(TableTypeSymbol tableTypeSymbol) {
        TypeSymbol typeSymbol = tableTypeSymbol.rowTypeParameter();
        Type type = getType(typeSymbol);
        return getWrapperType(getWrapperType(type, TypeKind.NON_NULL), TypeKind.LIST);
    }

    private Type getInputType(TypeSymbol typeSymbol) {
        String typeName = getTypeName(typeSymbol);
        if (this.schema.containsType(typeName)) {
            return this.schema.getType(typeName);
        }
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                return addType(ScalarType.STRING);
            case INT:
                return addType(ScalarType.INT);
            case FLOAT:
                return addType(ScalarType.FLOAT);
            case BOOLEAN:
                return addType(ScalarType.BOOLEAN);
            case DECIMAL:
                return addType(ScalarType.DECIMAL);
            case TYPE_REFERENCE:
                return getInputType((TypeReferenceTypeSymbol) typeSymbol, typeName);
            case ARRAY:
                return getInputType((ArrayTypeSymbol) typeSymbol);
            case UNION:
                return getInputType((UnionTypeSymbol) typeSymbol);
            case INTERSECTION:
                return getInputType(null, null, (IntersectionTypeSymbol) typeSymbol);
        }
        return null;
    }

    private Type getInputType(TypeReferenceTypeSymbol typeReferenceTypeSymbol, String typeName) {
        if (isFileUploadParameter(typeReferenceTypeSymbol)) {
            return addType(ScalarType.UPLOAD);
        }
        if (typeReferenceTypeSymbol.getName().isEmpty()) {
            return null;
        }
        Symbol definitionSymbol = typeReferenceTypeSymbol.definition();
        if (definitionSymbol.kind() == SymbolKind.TYPE_DEFINITION) {
            return getInputType(typeName, (TypeDefinitionSymbol) definitionSymbol);
        } else if (definitionSymbol.kind() == SymbolKind.ENUM) {
            return getType(typeName, (EnumSymbol) definitionSymbol);
        }
        return null;
    }

    private Type getInputType(ArrayTypeSymbol arrayTypeSymbol) {
        TypeSymbol memberTypeSymbol = arrayTypeSymbol.memberTypeDescriptor();
        return getWrapperType(getInputFieldType(memberTypeSymbol), TypeKind.LIST);
    }

    private Type getInputType(String typeName, TypeDefinitionSymbol typeDefinitionSymbol) {
        TypeSymbol typeDescriptor = typeDefinitionSymbol.typeDescriptor();
        String description = getDescription(typeDefinitionSymbol);
        switch (typeDescriptor.typeKind()) {
            case RECORD:
                return getInputType(typeName, description, (RecordTypeSymbol) typeDescriptor);
            case UNION:
                return getInputType((UnionTypeSymbol) typeDescriptor);
            case INTERSECTION:
                return getInputType(typeName, description, (IntersectionTypeSymbol) typeDescriptor);
            default:
                return null;
        }
    }

    private Type getInputType(String name, String description, RecordTypeSymbol recordTypeSymbol) {
        Type objectType = addType(name, TypeKind.INPUT_OBJECT, description);
        for (RecordFieldSymbol recordFieldSymbol : recordTypeSymbol.fieldDescriptors().values()) {
            objectType.addInputField(getInputField(recordFieldSymbol));
        }
        return objectType;
    }

    private Type getInputType(UnionTypeSymbol unionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = getEffectiveTypes(unionTypeSymbol);
        for (TypeSymbol typeSymbol : effectiveTypes) {
            return getInputType(typeSymbol);
        }
        return null;
    }

    private Type getInputType(String typeName, String description, IntersectionTypeSymbol intersectionTypeSymbol) {
        TypeSymbol effectiveType = getEffectiveType(intersectionTypeSymbol);
        if (typeName == null) {
            return getInputType(effectiveType);
        } else {
            return getInputType(typeName, description, (RecordTypeSymbol) effectiveType);
        }
    }

    private InputValue getInputField(RecordFieldSymbol recordFieldSymbol) {
        if (recordFieldSymbol.getName().isEmpty()) {
            return null;
        }
        String name = recordFieldSymbol.getName().get();
        String description = getDescription(recordFieldSymbol);
        Type type = getInputType(recordFieldSymbol.typeDescriptor());
        if (!isNilable(recordFieldSymbol.typeDescriptor()) && !recordFieldSymbol.isOptional()) {
            type = getWrapperType(type, TypeKind.NON_NULL);
        }
        String defaultValue = getDefaultValue(recordFieldSymbol);
        return new InputValue(name, type, description, defaultValue);
    }

    private void addEnumValueToType(Type type, ConstantSymbol enumMember) {
        if (enumMember.getName().isEmpty()) {
            return;
        }
        String memberDescription = getDescription(enumMember);
        String name = enumMember.getName().get();
        boolean isDeprecated = enumMember.deprecated();
        String deprecationReason = getDeprecationReason(enumMember);
        EnumValue enumValue = new EnumValue(name, memberDescription, isDeprecated, deprecationReason);
        type.addEnumValue(enumValue);
    }

    private Type getFieldType(TypeSymbol typeSymbol) {
        Type type = getType(typeSymbol);
        if (isNilable(typeSymbol)) {
            return type;
        }
        return getWrapperType(type, TypeKind.NON_NULL);
    }

    private Type getInputFieldType(TypeSymbol typeSymbol) {
        Type type = getInputType(typeSymbol);
        if (isNilable(typeSymbol)) {
            return type;
        }
        return getWrapperType(type, TypeKind.NON_NULL);
    }

    private void addDefaultDirectives() {
        Directive include = new Directive(DefaultDirective.INCLUDE);
        include.addArg(getIfInputValue(Description.INCLUDE_IF));
        this.schema.addDirective(include);

        Directive skip = new Directive(DefaultDirective.SKIP);
        skip.addArg(getIfInputValue(Description.SKIP_IF));
        this.schema.addDirective(skip);

        Directive deprecated = new Directive(DefaultDirective.DEPRECATED);
        InputValue reason = new InputValue(REASON_ARG_NAME, addType(ScalarType.STRING),
                                           Description.DEPRECATED_REASON.getDescription(), null);
        deprecated.addArg(reason);
        this.schema.addDirective(deprecated);
    }

    private InputValue getIfInputValue(Description description) {
        Type type = getWrapperType(addType(ScalarType.BOOLEAN), TypeKind.NON_NULL);
        return new InputValue(IF_ARG_NAME, type, description.getDescription(), null);
    }

    private String getDefaultValue(RecordFieldSymbol recordFieldSymbol) {
        if (recordFieldSymbol.hasDefaultValue()) {
            return "";
        }
        return null;
    }

    private String getDefaultValue(ParameterSymbol parameterSymbol) {
        if (parameterSymbol.paramKind() == ParameterKind.DEFAULTABLE) {
            return "\"\"";
        }
        return null;
    }
}
