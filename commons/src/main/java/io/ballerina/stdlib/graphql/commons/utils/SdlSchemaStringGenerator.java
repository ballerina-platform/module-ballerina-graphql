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
import io.ballerina.stdlib.graphql.commons.types.Field;
import io.ballerina.stdlib.graphql.commons.types.InputValue;
import io.ballerina.stdlib.graphql.commons.types.IntrospectionType;
import io.ballerina.stdlib.graphql.commons.types.ScalarType;
import io.ballerina.stdlib.graphql.commons.types.Schema;
import io.ballerina.stdlib.graphql.commons.types.Type;
import io.ballerina.stdlib.graphql.commons.types.TypeKind;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Generate the SDL schema for a given Ballerina GraphQL Service.
 */
public class SdlSchemaStringGenerator {

    //String formats for SDL schema
    private static final String SCHEMA_FORMAT = "%s%s%s";
    private static final String DIRECTIVE_TYPE_FORMAT = "%sdirective @%s%s%s on %s";
    private static final String INTERFACE_TYPE_FORMAT = "%sinterface %s%s %s";
    private static final String UNION_TYPE_FORMAT = "%sunion %s%s";
    private static final String SCALAR_TYPE_FORMAT = "%sscalar %s%s";
    private static final String OBJECT_TYPE_FORMAT = "%stype %s%s %s";
    private static final String ENUM_TYPE_FORMAT = "%senum %s %s";
    private static final String INPUT_TYPE_FORMAT = "input %s %s";
    private static final String FIELD_FORMAT = "%s  %s%s: %s%s";
    private static final String FIELD_BLOCK_FORMAT = "{%n%s%n}";
    private static final String ARGS_FORMAT = "(%s)";
    private static final String DESC_FORMAT = "%s%n";
    private static final String DEPRECATE_FORMAT = "%s(reason: \"%s\")";
    private static final String DOCUMENT_FORMAT = "%s\"%s\"";
    private static final String BLOCK_STRING_FORMAT = "%s\"\"\"%n%s%s%n%s\"\"\"";
    private static final String IMPLEMENT_FORMAT = " implements %s";
    private static final String POSSIBLE_TYPE_FORMAT = " = %s";
    private static final String INPUT_FIELD_FORMAT = "  %s: %s";
    private static final String ARGS_TYPE_FORMAT = "%s = %s";
    private static final String ARGS_VALUE_FORMAT = "%s: %s";
    private static final String ENUM_VALUE_FORMAT = "%s  %s%s";
    private static final String NON_NULL_FORMAT = "%s!";
    private static final String LIST_FORMAT = "[%s]";
    private static final String DEPRECATE = " @deprecated";

    //Schema delimiters
    private static final String LINE_SEPARATOR = System.getProperty("line.separator");
    private static final String INDENTATION = "  ";
    private static final String EMPTY_STRING = "";
    private static final String COMMA_SIGN = ", ";
    private static final String AND_SIGN = " & ";
    private static final String PIPE_SIGN = "|";
    private static final String SPACE = " ";

    public static String generate(Schema schema) {
        String sdlSchemaString = getSDLSchemaString(schema);
        return sdlSchemaString;
    }

    private static String getSDLSchemaString(Schema schema) {
        String directives = getDirectives(schema);
        String types = getTypes(schema);
        return getFormattedString(SCHEMA_FORMAT, createDescription(schema.getDescription()), directives, types);
    }

    private static String getDirectives(Schema schema) {
        List<String> directives = new ArrayList<>();
        for (Directive directive : schema.getDirectives()) {
            if (!isDefaultDirective(directive)) {
                directives.add(createDirective(directive));
            }
        }
        String formattedDirectives = String.join(LINE_SEPARATOR + LINE_SEPARATOR, directives);
        if (directives.isEmpty()) {
            return formattedDirectives;
        }
        return formattedDirectives + LINE_SEPARATOR + LINE_SEPARATOR;
    }

    private static String getTypes(Schema schema) {
        List<String> types = new ArrayList<>();
        for (Map.Entry<String, Type> entry : schema.getTypes().entrySet()) {
            if (!isIntrospectionType(entry.getValue()) && !isBuiltInScalarType(entry.getValue())) {
                types.add(createType(entry.getValue()));
            }
        }
        return String.join(LINE_SEPARATOR + LINE_SEPARATOR, types);
    }

    private static String createDirective(Directive directive) {
        return getFormattedString(DIRECTIVE_TYPE_FORMAT, createDescription(directive.getDescription()),
                directive.getName(), createArgs(directive.getArgs()), createIsRepeatable(directive),
                createDirectiveLocation(directive.getLocations()));
    }

    private static String createType(Type type) {
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

    private static String createScalarType(Type type) {
        return getFormattedString(SCALAR_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                createSpecifiedByUrl(type));
    }

    private static String createObjectType(Type type) {
        return getFormattedString(OBJECT_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                createInterfaceImplements(type), createFields(type));
    }

    private static String createInterfaceType(Type type) {
        return getFormattedString(INTERFACE_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                createInterfaceImplements(type), createFields(type));
    }

    private static String createUnionType(Type type) {
        return getFormattedString(UNION_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                createPossibleTypes(type));
    }

    private static String createInputObjectType(Type type) {
        return getFormattedString(INPUT_TYPE_FORMAT, type.getName(), createInputValues(type));
    }

    private static String createEnumType(Type type) {
        return getFormattedString(ENUM_TYPE_FORMAT, createDescription(type.getDescription()), type.getName(),
                createEnumValues(type));
    }

    private static String createDescription(String description) {
        if (description == null || description.isEmpty()) {
            return EMPTY_STRING;
        } else {
            String desc;
            if (description.split(LINE_SEPARATOR).length > 1) {
                desc = getFormattedString(BLOCK_STRING_FORMAT, EMPTY_STRING, EMPTY_STRING, description, EMPTY_STRING);
            } else {
                desc = getFormattedString(DOCUMENT_FORMAT, EMPTY_STRING, description);
            }
            return getFormattedString(DESC_FORMAT, desc);
        }
    }

    private static String createFields(Type type) {
        List<String> fields = new ArrayList<>();
        for (Field field : type.getFields()) {
            fields.add(getFormattedString(FIELD_FORMAT, createFieldDescription(field.getDescription()), field.getName(),
                    createArgs(field.getArgs()), createFieldType(field.getType()), createDeprecate(field)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, fields));
    }

    private static String createEnumValues(Type type) {
        List<String> enumValues = new ArrayList<>();
        for (EnumValue enumValue : type.getEnumValues()) {
            enumValues.add(getFormattedString(ENUM_VALUE_FORMAT, createFieldDescription(enumValue.getDescription()),
                    enumValue.getName(), createDeprecate(enumValue)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, enumValues));
    }

    private static String createInputValues(Type type) {
        List<String> inputFields = new ArrayList<>();
        for (InputValue inputField : type.getInputFields()) {
            inputFields.add(getFormattedString(INPUT_FIELD_FORMAT, inputField.getName(), createArgType(inputField)));
        }
        return getFormattedString(FIELD_BLOCK_FORMAT, String.join(LINE_SEPARATOR, inputFields));
    }

    private static String createPossibleTypes(Type type) {
        List<String> possibleTypes = new ArrayList<>();
        for (Type possibleType : type.getPossibleTypes()) {
            possibleTypes.add(possibleType.getName());
        }
        return getFormattedString(POSSIBLE_TYPE_FORMAT, String.join(PIPE_SIGN, possibleTypes));
    }

    private static String createArgs(List<InputValue> inputValues) {
        List<String> args = new ArrayList<>();
        if (inputValues.isEmpty()) {
            return EMPTY_STRING;
        }
        for (InputValue arg : inputValues) {
            args.add(getFormattedString(ARGS_VALUE_FORMAT, arg.getName(), createArgType(arg)));
        }
        return getFormattedString(ARGS_FORMAT, String.join(COMMA_SIGN, args));
    }

    private static String createFieldType(Type type) {
        if (type.getKind().equals(TypeKind.NON_NULL)) {
            return getFormattedString(NON_NULL_FORMAT, createFieldType(type.getOfType()));
        } else if (type.getKind().equals(TypeKind.LIST)) {
            return getFormattedString(LIST_FORMAT, createFieldType(type.getOfType()));
        } else {
            return type.getName();
        }
    }

    private static String createArgType(InputValue arg) {
        if (arg.getDefaultValue() == null) {
            return createFieldType(arg.getType());
        } else {
            return getFormattedString(ARGS_TYPE_FORMAT, createFieldType(arg.getType()), arg.getDefaultValue());
        }
    }

    private static String createInterfaceImplements(Type type) {
        List<String> interfaces = new ArrayList<>();
        if (type.getInterfaces().isEmpty()) {
            return EMPTY_STRING;
        }
        for (Type interfaceType : type.getInterfaces()) {
            interfaces.add(interfaceType.getName());
        }
        return getFormattedString(IMPLEMENT_FORMAT, String.join(AND_SIGN, interfaces));
    }

    private static String createFieldDescription(String description) {
        if (description == null || description.isEmpty()) {
            return EMPTY_STRING;
        } else {
            String desc;
            String[] lines = description.split(LINE_SEPARATOR);
            if (lines.length > 1) {
                desc = getFormattedString(BLOCK_STRING_FORMAT, INDENTATION, INDENTATION,
                        String.join(LINE_SEPARATOR + INDENTATION, lines), INDENTATION);
            } else {
                desc = getFormattedString(DOCUMENT_FORMAT, INDENTATION, description);
            }
            return getFormattedString(DESC_FORMAT, desc);
        }
    }

    private static String createDirectiveLocation(List<DirectiveLocation> location) {
        List<String> locations = new ArrayList<>();
        for (DirectiveLocation directiveLocation : location) {
            locations.add(directiveLocation.name());
        }
        return String.join(PIPE_SIGN, locations);
    }

    private static String createDeprecate(EnumValue enumValue) {
        if (enumValue.isDeprecated()) {
            if (enumValue.getDeprecationReason() != null) {
                return getFormattedString(DEPRECATE_FORMAT, DEPRECATE,
                        createDeprecateReason(enumValue.getDeprecationReason()));
            }
            return DEPRECATE;
        }
        return EMPTY_STRING;
    }
    private static String createDeprecate(Field field) {
        if (field.isDeprecated()) {
            if (field.getDeprecationReason() != null) {
                return getFormattedString(DEPRECATE_FORMAT, DEPRECATE,
                        createDeprecateReason(field.getDeprecationReason()));
            }
            return DEPRECATE;
        }
        return EMPTY_STRING;
    }

    private static String createDeprecateReason(String reason) {
        return reason.replace(LINE_SEPARATOR, SPACE);
    }

    private static String createSpecifiedByUrl(Type type) {
        // Return an empty string since this is not supported yet
        return EMPTY_STRING;
    }

    private static String createIsRepeatable(Directive directive) {
        // Return an empty string since this is not supported yet
        return EMPTY_STRING;
    }

    private static Boolean isIntrospectionType(Type type) {
        for (IntrospectionType value : IntrospectionType.values()) {
            if (value.getName().equals(type.getName())) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isBuiltInScalarType(Type type) {
        for (ScalarType value : ScalarType.values()) {
            if (value.getName().equals(type.getName()) && value.isInbuiltType()) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isDefaultDirective(Directive directive) {
        for (DefaultDirective value : DefaultDirective.values()) {
            if (value.getName().equals(directive.getName())) {
                return true;
            }
        }
        return false;
    }

    private static String getFormattedString(String format, String... args) {
        return String.format(format, (Object[]) args);
    }
}
