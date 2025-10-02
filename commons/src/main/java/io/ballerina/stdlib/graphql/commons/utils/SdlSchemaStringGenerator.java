/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.graphql.commons.utils;

import io.ballerina.stdlib.graphql.commons.types.DefaultDirective;
import io.ballerina.stdlib.graphql.commons.types.Directive;
import io.ballerina.stdlib.graphql.commons.types.DirectiveLocation;
import io.ballerina.stdlib.graphql.commons.types.EnumValue;
import io.ballerina.stdlib.graphql.commons.types.FederatedDirective;
import io.ballerina.stdlib.graphql.commons.types.FederatedEnumValue;
import io.ballerina.stdlib.graphql.commons.types.Field;
import io.ballerina.stdlib.graphql.commons.types.InputValue;
import io.ballerina.stdlib.graphql.commons.types.IntrospectionType;
import io.ballerina.stdlib.graphql.commons.types.ScalarType;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.Type;
import io.ballerina.stdlib.graphql.commons.types.TypeKind;
import io.ballerina.stdlib.graphql.commons.types.TypeName;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.graphql.commons.types.FederatedDirective.canImportInLinkDirective;
import static io.ballerina.stdlib.graphql.commons.types.FederatedDirective.values;

/**
 * Generate the SDL schema for a given Ballerina GraphQL Service.
 */
public class SdlSchemaStringGenerator {

    //String formats for SDL schema
    private static final String SCHEMA_FORMAT = "%s%s%s%s";
    private static final String FEDERATION2_SCHEMA_EXTENSION = "extend schema %s %s";
    private static final String DIRECTIVE_TYPE_FORMAT = "%sdirective @%s%s%s on %s";
    private static final String INTERFACE_TYPE_FORMAT = "%sinterface %s%s %s";
    private static final String UNION_TYPE_FORMAT = "%sunion %s%s";
    private static final String SCALAR_TYPE_FORMAT = "%sscalar %s%s";
    private static final String OBJECT_TYPE_FORMAT = "%stype %s%s %s";
    private static final String ENTITY_TYPE_FORMAT = "%stype %s%s%s %s";
    private static final String ENTITY_KEY_DIRECTIVE = " @key(fields: \"%s\"%s)";
    private static final String RESOLVABLE_ARGUMENT = ", resolvable: %s";
    private static final String LINK_DIRECTIVE = "@link(url: \"%s\", import: [%s])";
    private static final String ENUM_TYPE_FORMAT = "%senum %s %s";
    private static final String INPUT_TYPE_FORMAT = "%sinput %s %s";
    private static final String FIELD_FORMAT = "%s  %s%s: %s%s";
    private static final String FIELD_BLOCK_FORMAT = "{%n%s%n}";
    private static final String ARGS_FORMAT = "(%s%s%s%s)";
    private static final String DESC_FORMAT = "%s%n";
    private static final String DEPRECATE_FORMAT = "%s(reason: \"%s\")";
    private static final String DOCUMENT_FORMAT = "%s\"%s\"";
    private static final String BLOCK_STRING_FORMAT = "%s\"\"\"%n%s%s%n%s\"\"\"";
    private static final String IMPLEMENT_FORMAT = " implements %s";
    private static final String POSSIBLE_TYPE_FORMAT = " = %s";
    private static final String INPUT_FIELD_FORMAT = "%s  %s: %s";
    private static final String ARGS_TYPE_FORMAT = "%s = %s";
    private static final String ARGS_VALUE_FORMAT = "%s%s%s: %s";
    private static final String ENUM_VALUE_FORMAT = "%s  %s%s";
    private static final String NON_NULL_FORMAT = "%s!";
    private static final String LIST_FORMAT = "[%s]";
    private static final String DEPRECATE = " @deprecated";
    private static final String REPEATABLE = " repeatable";
    private static final String FEDERATION_SPEC_LINK = "https://specs.apollo.dev/federation/v2.0";

    //Schema delimiters
    private static final String LINE_SEPARATOR = System.getProperty("line.separator");
    private static final String LINE_SEPARATOR_REGEX = "\\r\\n?|\\n";
    private static final String INDENTATION = "  ";
    private static final String DOUBLE_INDENTATION = INDENTATION + INDENTATION;
    private static final String EMPTY_STRING = "";
    private static final String COMMA_SIGN = ",";
    private static final String AMPERSAND_SIGN = "&";
    private static final String PIPE_SIGN = "|";
    private static final String SPACE = " ";
    private static final String AT_SYMBOL = "@";
    private static final String DOUBLE_QUOTE = "\"";
    private static final String[] SUBGRAPH_QUERY_FIELDS = {"_entities", "_service"};
    private static boolean isSubgraphSdlIntrospection;

    private final boolean isSubgraph;
    private final Map<String, KeyDirectivesArgumentHolder> entityKeyDirectiveArgumentHolders;
    private final Schema schema;

    public static String generate(Schema schema) {
        return generate(schema, false);
    }

    public static String generate(Schema schema, boolean isSubgraphSdlIntrospection) {
        SdlSchemaStringGenerator.isSubgraphSdlIntrospection = isSubgraphSdlIntrospection;
        schema.addSubgraphSchemaAdditions();
        SdlSchemaStringGenerator sdlGenerator = new SdlSchemaStringGenerator(schema);
        return sdlGenerator.getSDLSchemaString();
    }

    private SdlSchemaStringGenerator(Schema schema) {
        this.schema = schema;
        this.isSubgraph = schema.isSubgraph();
        this.entityKeyDirectiveArgumentHolders = schema.getEntityKeyDirectiveArgumentHolders();
    }


    private String getSDLSchemaString() {
        String directives = getDirectives();
        String types = getTypes();
        String schemaExtension = getFederationSchemaExtensionLink();
        return getFormattedString(SCHEMA_FORMAT, schemaExtension, createTypeDescription(this.schema.getDescription()),
                                  directives, types);
    }

    private String getFederationSchemaExtensionLink() {
        if (!this.isSubgraph) {
            return EMPTY_STRING;
        }
        String linkDirective = getLinkDirective();
        return getFormattedString(FEDERATION2_SCHEMA_EXTENSION, linkDirective, LINE_SEPARATOR + LINE_SEPARATOR);
    }

    private String getLinkDirective() {
        String imports = getImportsArgumentValueOfLinkDirective();
        return getFormattedString(LINK_DIRECTIVE, FEDERATION_SPEC_LINK, imports);
    }

    private String getImportsArgumentValueOfLinkDirective() {
        List<String> imports = Arrays.stream(FederatedDirective.values())
                .filter(directive -> !canImportInLinkDirective(directive.getName()))
                .map(directive -> DOUBLE_QUOTE + AT_SYMBOL + directive.getName() + DOUBLE_QUOTE)
                .collect(Collectors.toList());
        if (isSubgraphSdlIntrospection) {
            imports.add(DOUBLE_QUOTE + TypeName.FIELD_SET.getName() + DOUBLE_QUOTE);
        }
        return String.join(SPACE + COMMA_SIGN, imports);
    }

    private String getDirectives() {
        List<String> directives = new ArrayList<>();
        for (Directive directive : this.schema.getDirectives()) {
            if (!isDefaultDirective(directive)) {
                if (!isSubgraphSdlIntrospection && isFederatedDirective(directive)) {
                    continue;
                }
                directives.add(createDirective(directive));
            }
        }
        String formattedDirectives = String.join(LINE_SEPARATOR + LINE_SEPARATOR, directives);
        if (directives.isEmpty()) {
            return formattedDirectives;
        }
        return formattedDirectives + LINE_SEPARATOR + LINE_SEPARATOR;
    }

    private boolean isFederatedDirective(Directive directive) {
        return isSubgraph && Arrays.stream(values())
                .anyMatch(federatedDirective -> Objects.equals(directive.getName(), federatedDirective.getName()));
    }

    private String getTypes() {
        List<Type> typeList = new ArrayList<>();
        for (Map.Entry<String, Type> entry : this.schema.getTypes().entrySet()) {
            if (!isIntrospectionType(entry.getValue()) && !isBuiltInScalarType(entry.getValue())) {
                if (!isSubgraphSdlIntrospection && isDefaultFederatedType(entry.getValue())) {
                    continue;
                }
                typeList.add(entry.getValue());
            }
        }
        
        typeList.sort((t1, t2) -> {
            int priority1 = getTypeSortPriority(t1);
            int priority2 = getTypeSortPriority(t2);
            if (priority1 != priority2) {
                return Integer.compare(priority1, priority2);
            }
            return t1.getName().compareTo(t2.getName());
        });
        
        List<String> types = new ArrayList<>();
        for (Type type : typeList) {
            types.add(createType(type));
        }
        return String.join(LINE_SEPARATOR + LINE_SEPARATOR, types);
    }
    
    private int getTypeSortPriority(Type type) {
        if (this.schema.getQueryType() != null && type.getName().equals(this.schema.getQueryType().getName())) {
            return 0;
        }
        if (this.schema.getMutationType() != null && type.getName().equals(this.schema.getMutationType().getName())) {
            return 1;
        }
        if (this.schema.getSubscriptionType() != null && 
                type.getName().equals(this.schema.getSubscriptionType().getName())) {
            return 2;
        }
        
        switch (type.getKind()) {
            case INTERFACE:
                return 3;
            case OBJECT:
                return 4;
            case INPUT_OBJECT:
                return 5;
            case ENUM:
                return 6;
            case UNION:
                return 7;
            case SCALAR:
                return 8;
            default:
                return 9;
        }
    }

    private boolean isDefaultFederatedType(Type type) {
        if (!isSubgraph) {
            return false;
        }
        if (type.getKind() == TypeKind.SCALAR) {
            return isDefaultFederatedScalarType(type);
        }
        if (type.getKind() == TypeKind.ENUM) {
            return isDefaultFederatedEnumType(type);
        }
        if (type.getKind() == TypeKind.OBJECT) {
            return isDefaultFederatedObjectType(type);
        }
        if (type.getKind() == TypeKind.UNION) {
            return isFederatedEntityUnionType(type);
        }
        return false;
    }

    private boolean isDefaultFederatedScalarType(Type type) {
        return Objects.equals(type.getName(), TypeName.ANY.getName())
                || Objects.equals(type.getName(), TypeName.FIELD_SET.getName())
                || type.getName().equals(TypeName.LINK_IMPORT.getName());
    }

    private boolean isDefaultFederatedEnumType(Type type) {
        return Arrays.stream(FederatedEnumValue.values())
                .anyMatch(federatedEnum -> type.getName().equals(federatedEnum.getName()));
    }

    private boolean isDefaultFederatedObjectType(Type type) {
        return type.getName().equals(TypeName.SERVICE.getName());
    }

    private boolean isFederatedEntityUnionType(Type type) {
        return type.getName().equals(TypeName.ENTITY.getName());
    }

    private String createDirective(Directive directive) {
        return getFormattedString(DIRECTIVE_TYPE_FORMAT, createTypeDescription(directive.getDescription()),
                directive.getName(), createArgs(directive.getArgs()), createIsRepeatable(directive),
                createDirectiveLocation(directive.getLocations()));
    }

    private String createType(Type type) {
        if (type.getKind().equals(TypeKind.SCALAR)) {
            return createScalarType(type);
        }
        if (type.getKind().equals(TypeKind.OBJECT)) {
            return createObjectType(type);
        }
        if (type.getKind().equals(TypeKind.INTERFACE)) {
            return createInterfaceType(type);
        }
        if (type.getKind().equals(TypeKind.UNION)) {
            return createUnionType(type);
        }
        if (type.getKind().equals(TypeKind.ENUM)) {
            return createEnumType(type);
        }
        if (type.getKind().equals(TypeKind.INPUT_OBJECT)) {
            return createInputObjectType(type);
        }
        return EMPTY_STRING;
    }

    private String createScalarType(Type type) {
        return getFormattedString(SCALAR_TYPE_FORMAT, createTypeDescription(type.getDescription()), type.getName(),
                createSpecifiedByUrl(type));
    }

    private String createObjectType(Type type) {
        String typeName = type.getName();
        if (this.isSubgraph && this.entityKeyDirectiveArgumentHolders.containsKey(typeName)) {
            return getFormattedString(ENTITY_TYPE_FORMAT, createTypeDescription(type.getDescription()), typeName,
                                      createInterfaceImplements(type), createEntityKeyDirectives(typeName),
                                      createFields(type));
        }
        return getFormattedString(OBJECT_TYPE_FORMAT, createTypeDescription(type.getDescription()), typeName,
                                  createInterfaceImplements(type), createFields(type));
    }

    private String createEntityKeyDirectives(String entityName) {
        KeyDirectivesArgumentHolder arguments = this.entityKeyDirectiveArgumentHolders.get(entityName);
        // If there are more than one field name in the list, then key directive is repeated for each fieldName
        List<String> keyDirectiveFields = arguments.getFieldNames();
        List<String> keyDirectives = keyDirectiveFields.stream()
                .map(fields -> createEntityKeyDirective(fields, arguments.isResolvable())).collect(Collectors.toList());
        return String.join(EMPTY_STRING, keyDirectives);
    }

    private String createEntityKeyDirective(String fieldArgument, Boolean resolvable) {
        String resolvableArgument = resolvable ? EMPTY_STRING :
                getFormattedString(RESOLVABLE_ARGUMENT, resolvable.toString());
        return getFormattedString(ENTITY_KEY_DIRECTIVE, fieldArgument, resolvableArgument);
    }

    private String createInterfaceType(Type type) {
        return getFormattedString(INTERFACE_TYPE_FORMAT, createTypeDescription(type.getDescription()), type.getName(),
                                  createInterfaceImplements(type), createFields(type));
    }

    private String createUnionType(Type type) {
        return getFormattedString(UNION_TYPE_FORMAT, createTypeDescription(type.getDescription()), type.getName(),
                                  createPossibleTypes(type));
    }

    private String createInputObjectType(Type type) {
        return getFormattedString(INPUT_TYPE_FORMAT, createTypeDescription(type.getDescription()), type.getName(),
                createInputValues(type));
    }

    private String createEnumType(Type type) {
        return getFormattedString(ENUM_TYPE_FORMAT, createTypeDescription(type.getDescription()), type.getName(),
                createEnumValues(type));
    }

    private String createTypeDescription(String description) {
        if (description == null) {
            return EMPTY_STRING;
        } else {
            String[] lines = description.trim().split(LINE_SEPARATOR_REGEX);
            if (lines.length == 1) {
                return getFormattedString(DESC_FORMAT, getFormattedString(DOCUMENT_FORMAT, EMPTY_STRING, lines[0]));
            } else {
                String formattedDesc = getFormattedString(BLOCK_STRING_FORMAT, EMPTY_STRING, EMPTY_STRING,
                        String.join(LINE_SEPARATOR, lines), EMPTY_STRING);
                return getFormattedString(DESC_FORMAT, formattedDesc);
            }
        }
    }

    private String createFields(Type type) {
        List<String> fields = new ArrayList<>();
        for (Field field : type.getFields()) {
            if (isSubgraph && !isSubgraphSdlIntrospection && Arrays.asList(SUBGRAPH_QUERY_FIELDS)
                    .contains(field.getName())) {
                continue;
            }
            fields.add(getFormattedString(FIELD_FORMAT, createFieldDescription(field.getDescription()), field.getName(),
                                          createArgs(field.getArgs()), createFieldType(field.getType()),
                                          createDeprecate(field)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, fields));
    }

    private String createEnumValues(Type type) {
        List<String> enumValues = new ArrayList<>();
        for (EnumValue enumValue : type.getEnumValues()) {
            enumValues.add(getFormattedString(ENUM_VALUE_FORMAT, createFieldDescription(enumValue.getDescription()),
                    enumValue.getName(), createDeprecate(enumValue)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, enumValues));
    }

    private String createInputValues(Type type) {
        List<String> inputFields = new ArrayList<>();
        for (InputValue inputField : type.getInputFields()) {
            inputFields.add(getFormattedString(INPUT_FIELD_FORMAT, createFieldDescription(inputField.getDescription()),
                    inputField.getName(), createArgType(inputField)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, inputFields));
    }

    private String createPossibleTypes(Type type) {
        List<String> possibleTypes = new ArrayList<>();
        for (Type possibleType : type.getPossibleTypes()) {
            possibleTypes.add(possibleType.getName());
        }
        return getFormattedString(POSSIBLE_TYPE_FORMAT, String.join(PIPE_SIGN, possibleTypes));
    }

    private String createArgs(List<InputValue> inputValues) {
        List<String> args = new ArrayList<>();
        if (inputValues.isEmpty()) {
            return EMPTY_STRING;
        }
        boolean hasDescription = inputValues.stream()
                .anyMatch(input -> input.getDescription() != null && !input.getDescription().isEmpty());
        if (hasDescription) {
            for (InputValue arg : inputValues) {
                args.add(getFormattedString(ARGS_VALUE_FORMAT, createArgDescription(arg.getDescription()),
                        DOUBLE_INDENTATION, arg.getName(), createArgType(arg)));
            }
            return getFormattedString(ARGS_FORMAT, LINE_SEPARATOR, String.join(LINE_SEPARATOR, args),
                    LINE_SEPARATOR, INDENTATION);
        } else {
            for (InputValue arg : inputValues) {
                args.add(getFormattedString(ARGS_VALUE_FORMAT, EMPTY_STRING, EMPTY_STRING, arg.getName(),
                        createArgType(arg)));
            }
            return getFormattedString(ARGS_FORMAT, EMPTY_STRING, String.join(COMMA_SIGN + SPACE, args), EMPTY_STRING,
                    EMPTY_STRING);
        }
    }

    private String createFieldType(Type type) {
        if (type.getKind().equals(TypeKind.NON_NULL)) {
            return getFormattedString(NON_NULL_FORMAT, createFieldType(type.getOfType()));
        } else if (type.getKind().equals(TypeKind.LIST)) {
            return getFormattedString(LIST_FORMAT, createFieldType(type.getOfType()));
        } else {
            return type.getName();
        }
    }

    private String createArgType(InputValue arg) {
        if (arg.getDefaultValue() == null) {
            return createFieldType(arg.getType());
        } else {
            return getFormattedString(ARGS_TYPE_FORMAT, createFieldType(arg.getType()), arg.getDefaultValue());
        }
    }

    private String createInterfaceImplements(Type type) {
        List<String> interfaces = new ArrayList<>();
        if (type.getInterfaces().isEmpty()) {
            return EMPTY_STRING;
        }
        for (Type interfaceType : type.getInterfaces()) {
            interfaces.add(interfaceType.getName());
        }
        return getFormattedString(IMPLEMENT_FORMAT, String.join(SPACE + AMPERSAND_SIGN + SPACE, interfaces));
    }

    private String createFieldDescription(String description) {
        if (description == null) {
            return EMPTY_STRING;
        } else {
            String[] lines = description.trim().split(LINE_SEPARATOR_REGEX);
            if (lines.length == 1) {
                return getFormattedString(DESC_FORMAT, getFormattedString(DOCUMENT_FORMAT, INDENTATION, lines[0]));
            } else {
                String formattedDesc = getFormattedString(BLOCK_STRING_FORMAT, INDENTATION, INDENTATION,
                        String.join(LINE_SEPARATOR + INDENTATION, lines), INDENTATION);
                return getFormattedString(DESC_FORMAT, formattedDesc);
            }
        }
    }

    private String createArgDescription(String description) {
        if (description == null) {
            return EMPTY_STRING;
        } else {
            String[] lines = description.trim().split(LINE_SEPARATOR_REGEX);
            if (lines.length == 1) {
                return getFormattedString(DESC_FORMAT,
                        getFormattedString(DOCUMENT_FORMAT, DOUBLE_INDENTATION, lines[0]));
            } else {
                String formattedDesc = getFormattedString(BLOCK_STRING_FORMAT, DOUBLE_INDENTATION, DOUBLE_INDENTATION,
                        String.join(LINE_SEPARATOR + DOUBLE_INDENTATION, lines), DOUBLE_INDENTATION);
                return getFormattedString(DESC_FORMAT, formattedDesc);
            }
        }
    }

    private String createDirectiveLocation(List<DirectiveLocation> location) {
        List<String> locations = new ArrayList<>();
        for (DirectiveLocation directiveLocation : location) {
            locations.add(directiveLocation.name());
        }
        return String.join(PIPE_SIGN, locations);
    }

    private String createDeprecate(EnumValue enumValue) {
        if (enumValue.isDeprecated()) {
            if (enumValue.getDeprecationReason() != null) {
                return getFormattedString(DEPRECATE_FORMAT, DEPRECATE,
                        createDeprecateReason(enumValue.getDeprecationReason()));
            }
            return DEPRECATE;
        }
        return EMPTY_STRING;
    }

    private String createDeprecate(Field field) {
        if (field.isDeprecated()) {
            if (field.getDeprecationReason() != null) {
                return getFormattedString(DEPRECATE_FORMAT, DEPRECATE,
                        createDeprecateReason(field.getDeprecationReason()));
            }
            return DEPRECATE;
        }
        return EMPTY_STRING;
    }

    private String createDeprecateReason(String reason) {
        return reason.replaceAll(LINE_SEPARATOR_REGEX, SPACE);
    }

    private String createSpecifiedByUrl(Type type) {
        // Return an empty string since this is not supported yet
        return EMPTY_STRING;
    }

    private String createIsRepeatable(Directive directive) {
        // Only add repeatable keyword to federated directives
        if (isRepeatableFederatedDirective(directive)) {
            return REPEATABLE;
        }
        // Return an empty string since this is not supported yet
        return EMPTY_STRING;
    }

    private boolean isRepeatableFederatedDirective(Directive directive) {
        Optional<FederatedDirective> filteredDirective = Arrays.stream(values())
                .filter(federatedDirective -> directive.getName().equals(federatedDirective.getName())).findFirst();
        if (filteredDirective.isEmpty()) {
            return false;
        }
        return filteredDirective.get().isRepeatable();
    }

    private Boolean isIntrospectionType(Type type) {
        for (IntrospectionType value : IntrospectionType.values()) {
            if (value.getName().equals(type.getName())) {
                return true;
            }
        }
        return false;
    }

    private Boolean isBuiltInScalarType(Type type) {
        for (ScalarType value : ScalarType.values()) {
            if (value.getName().equals(type.getName()) && value.isInbuiltType()) {
                return true;
            }
        }
        return false;
    }

    private Boolean isDefaultDirective(Directive directive) {
        for (DefaultDirective value : DefaultDirective.values()) {
            if (value.getName().equals(directive.getName())) {
                return true;
            }
        }
        return false;
    }

    private String getFormattedString(String format, String... args) {
        return String.format(format, (Object[]) args);
    }
}
