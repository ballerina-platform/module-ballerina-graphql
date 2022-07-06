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

package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.Objects;

import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.ARGUMENTS_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.FILE_INFO_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_DEFINITION;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_NAME_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.VARIABLE_VALUE_FIELD;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isEnum;
import static io.ballerina.stdlib.graphql.runtime.engine.EngineUtils.isIgnoreType;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isContext;
import static io.ballerina.stdlib.graphql.runtime.utils.Utils.isFileUpload;

/**
 * This class processes the arguments passed to a GraphQL document to pass into Ballerina functions.
 */
public class ArgumentHandler {
    private final BMap<BString, Object> argumentsMap;
    private final MethodType method;

    private final BMap<BString, Object> fileInfo;
    private final BObject context;

    public ArgumentHandler(MethodType method, BObject context) {
        this.method = method;
        this.fileInfo = (BMap<BString, Object>) context.getNativeData(FILE_INFO_FIELD);
        this.context = context;
        this.argumentsMap = ValueCreator.createMapValue();
    }

    public Object[] getArguments(BObject fieldNode) {
        this.populateArgumentsMap(fieldNode);
        return this.getArgumentsForMethod();
    }

    private void populateArgumentsMap(BObject fieldNode) {
        BArray argumentArray = fieldNode.getArrayValue(ARGUMENTS_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentNode = (BObject) argumentArray.get(i);
            BString argumentName = argumentNode.getStringValue(NAME_FIELD);
            Parameter parameter = Objects.requireNonNull(getParameterForArgumentNode(argumentName));
            Object argumentValue = this.getArgumentValue(argumentNode, parameter.type);
            this.argumentsMap.put(argumentName, argumentValue);
        }
    }

    private Object getArgumentValue(BObject argumentNode, Type parameterType) {
        if (isFileUpload(parameterType)) {
            return getFileUploadParameter(argumentNode, parameterType);
        } else if (parameterType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            return this.getInputObjectArgument(argumentNode, (RecordType) parameterType);
        } else if (parameterType.getTag() == TypeTags.INTERSECTION_TAG) {
            return this.getIntersectionTypeArgument(argumentNode, (IntersectionType) parameterType);
        } else if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
            return this.getArrayTypeArgument(argumentNode, (ArrayType) parameterType);
        } else if (parameterType.getTag() == TypeTags.UNION_TAG) {
            return this.getUnionTypeArgument(argumentNode, (UnionType) parameterType);
        } else {
            return this.getScalarArgumentValue(argumentNode);
        }
    }

    private Object getFileUploadParameter(BObject argumentNode, Type parameterType) {
        if (parameterType.getTag() == TypeTags.ARRAY_TAG) {
            return this.fileInfo.getArrayValue(argumentNode.getStringValue(VARIABLE_NAME_FIELD));
        } else {
            return this.fileInfo.getMapValue(argumentNode.getStringValue(VARIABLE_NAME_FIELD));
        }
    }

    private BMap<BString, Object> getInputObjectArgument(BObject argumentNode, RecordType recordType) {
        BMap<BString, Object> recordValue = ValueCreator.createRecordValue(recordType);
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            BMap<BString, Object> variablesMap = argumentNode.getMapValue(VARIABLE_VALUE_FIELD);
            return JsonUtils.convertJSONToRecord(variablesMap, recordType);
        }
        BArray inputObjectFields = argumentNode.getArrayValue(VALUE_FIELD);
        for (int i = 0; i < inputObjectFields.size(); i++) {
            BObject inputObjectField = (BObject) inputObjectFields.get(i);
            BString inputObjectFieldName = inputObjectField.getStringValue(NAME_FIELD);
            Field field = recordType.getFields().get(inputObjectFieldName.getValue());
            Object fieldValue = getArgumentValue(inputObjectField, field.getFieldType());
            recordValue.put(inputObjectFieldName, fieldValue);
        }
        return recordValue;
    }

    private Object getIntersectionTypeArgument(BObject argumentNode, IntersectionType intersectionType) {
        Type effectiveType = getEffectiveType(intersectionType);
        if (effectiveType.getTag() == TypeTags.ARRAY_TAG) {
            BArray valueArray = getArrayTypeArgument(argumentNode, (ArrayType) effectiveType);
            valueArray.freezeDirect();
            return valueArray;
        }
        BMap<BString, Object> argumentValue = getInputObjectArgument(argumentNode, (RecordType) effectiveType);
        argumentValue.freezeDirect();
        return argumentValue;
    }

    private BArray getArrayTypeArgument(BObject argumentNode, ArrayType arrayType) {
        BArray valueArray = ValueCreator.createArrayValue(arrayType);
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            BArray argumentsArray = argumentNode.getArrayValue(VARIABLE_VALUE_FIELD);
            return (BArray) JsonUtils.convertJSON(argumentsArray, arrayType);
        }
        BArray argumentArray = argumentNode.getArrayValue(VALUE_FIELD);
        for (int i = 0; i < argumentArray.size(); i++) {
            BObject argumentElementNode = (BObject) argumentArray.get(i);
            Object elementValue = getArgumentValue(argumentElementNode, arrayType.getElementType());
            valueArray.append(elementValue);
        }
        return valueArray;
    }

    private Object getUnionTypeArgument(BObject argumentNode, UnionType unionType) {
        if (isEnum(unionType)) {
            return getScalarArgumentValue(argumentNode);
        } else if (unionType.isNilable()) {
            if (argumentNode.getBooleanValue(VARIABLE_DEFINITION) && argumentNode.get(VARIABLE_VALUE_FIELD) == null) {
                return null;
            } else if (!argumentNode.getBooleanValue(VARIABLE_DEFINITION) && argumentNode.get(VALUE_FIELD) == null) {
                return null;
            }
        }
        Type effectiveType = getEffectiveType(unionType);
        return getArgumentValue(argumentNode, effectiveType);
    }

    private Object getScalarArgumentValue(BObject argumentNode) {
        if (argumentNode.getBooleanValue(VARIABLE_DEFINITION)) {
            return argumentNode.get(VARIABLE_VALUE_FIELD);
        }
        return argumentNode.get(VALUE_FIELD);
    }

    private Parameter getParameterForArgumentNode(BString paramName) {
        for (Parameter parameter : this.method.getParameters()) {
            if (parameter.name.equals(paramName.getValue())) {
                return parameter;
            }
        }
        return null;
    }

    private Object[] getArgumentsForMethod() {
        Parameter[] parameters = this.method.getParameters();
        Object[] result = new Object[parameters.length * 2];
        for (int i = 0, j = 0; i < parameters.length; i += 1, j += 2) {
            if (i == 0 && isContext(parameters[i].type)) {
                result[i] = this.context;
                result[j + 1] = true;
                continue;
            }
            if (this.argumentsMap.get(StringUtils.fromString(parameters[i].name)) == null) {
                result[j] = parameters[i].type.getZeroValue();
                result[j + 1] = false;
            } else {
                result[j] = this.argumentsMap.get(StringUtils.fromString(parameters[i].name));
                result[j + 1] = true;
            }
        }
        return result;
    }

    private static Type getEffectiveType(IntersectionType intersectionType) {
        for (Type constituentType : intersectionType.getConstituentTypes()) {
            if (constituentType.getTag() != TypeTags.READONLY_TAG) {
                return constituentType;
            }
        }
        return intersectionType;
    }

    private static Type getEffectiveType(UnionType unionType) {
        for (Type memberType : unionType.getOriginalMemberTypes()) {
            if (!isIgnoreType(memberType)) {
                return memberType;
            }
        }
        return unionType;
    }
}
