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

import io.ballerina.compiler.api.symbols.Documentable;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.Project;
import io.ballerina.projects.ResolvedPackageDependency;
import io.ballerina.stdlib.graphql.commons.types.LinePosition;
import io.ballerina.stdlib.graphql.commons.types.Position;
import io.ballerina.stdlib.graphql.commons.types.ScalarType;
import io.ballerina.stdlib.graphql.commons.types.Type;
import io.ballerina.stdlib.graphql.commons.types.TypeKind;
import io.ballerina.tools.diagnostics.Location;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * Utility methods for Ballerina GraphQL schema generator.
 */
public class GeneratorUtils {
    private GeneratorUtils() {
    }

    public static final String UNION_TYPE_NAME_DELIMITER = "_";

    public static final String MAP_KEY_ARGUMENT_NAME = "key";
    public static final String MAP_KEY_ARGUMENT_DESCRIPTION =
            "[auto-generated]: The key of the value required from a map";
    public static final String SCHEMA_STRING_FIELD = "schemaString";

    public static String getTypeName(TypeSymbol typeSymbol) {
        switch (typeSymbol.typeKind()) {
            case STRING:
            case STRING_CHAR:
                return ScalarType.STRING.getName();
            case INT:
                return ScalarType.INT.getName();
            case FLOAT:
                return ScalarType.FLOAT.getName();
            case BOOLEAN:
                return ScalarType.BOOLEAN.getName();
            case DECIMAL:
                return ScalarType.DECIMAL.getName();
            default:
                if (typeSymbol.getName().isEmpty()) {
                    return null;
                }
                return typeSymbol.getName().get();
        }
    }

    public static String getTypeName(List<TypeSymbol> memberTypes) {
        List<String> typeNames = new ArrayList<>();
        for (TypeSymbol typeSymbol : memberTypes) {
            if (typeSymbol.getName().isEmpty()) {
                continue;
            }
            typeNames.add(typeSymbol.getName().get());
        }
        return String.join(UNION_TYPE_NAME_DELIMITER, typeNames);
    }

    public static String getDescription(Documentable documentable) {
        if (documentable.documentation().isEmpty()) {
            return null;
        }
        if (documentable.documentation().get().description().isEmpty()) {
            return null;
        }
        return documentable.documentation().get().description().get();
    }

    public static String getDeprecationReason(Documentable documentable) {
        if (documentable.documentation().isEmpty()) {
            return null;
        }
        if (documentable.documentation().get().deprecatedDescription().isEmpty()) {
            return null;
        }
        return documentable.documentation().get().deprecatedDescription().get();
    }

    public static Type getWrapperType(Type type, TypeKind typeKind) {
        return new Type(typeKind, type);
    }

    public static Position getTypePosition(Optional<Location> location, Symbol symbol, Project project) {
        if (location.isEmpty()) {
            return null;
        }
        Optional<Path> completePath = getFilePathForSymbol(symbol, project);
        String filePath = completePath.isPresent() ? completePath.get().toAbsolutePath().toString() :
                location.get().lineRange().filePath();
        return new Position(
                filePath,
                new LinePosition(location.get().lineRange().startLine().line(),
                        location.get().lineRange().startLine().offset()),
                new LinePosition(location.get().lineRange().endLine().line(),
                        location.get().lineRange().endLine().offset())
        );
    }

    public static Optional<Path> getFilePathForSymbol(Symbol symbol, Project project) {
        if (symbol.getLocation().isEmpty() || symbol.getModule().isEmpty()) {
            return Optional.empty();
        }
        String orgName = symbol.getModule().get().id().orgName();
        String moduleName = symbol.getModule().get().id().moduleName();
        if (isLangLib(orgName, moduleName)) {
            return Optional.empty();
        }

        // We search for the symbol in project's dependencies
        Collection<ResolvedPackageDependency> dependencies =
                project.currentPackage().getResolution().dependencyGraph().getNodes();
        // Symbol location has only the name of the file
        String sourceFile = symbol.getLocation().get().lineRange().filePath();
        for (ResolvedPackageDependency depNode : dependencies) {
            // Check for matching dependency
            Package depPackage = depNode.packageInstance();
            if (!depPackage.packageOrg().value().equals(orgName)) {
                continue;
            }
            for (ModuleId moduleId : depPackage.moduleIds()) {
                if (depPackage.module(moduleId).moduleName().toString().equals(moduleName)) {
                    Module module = depPackage.module(moduleId);
                    // Find in source files
                    for (DocumentId docId : module.documentIds()) {
                        if (module.document(docId).name().equals(sourceFile)) {
                            return module.project().documentPath(docId);
                        }
                    }
                    // Find in test sources
                    for (DocumentId docId : module.testDocumentIds()) {
                        if (module.document(docId).name().equals(sourceFile)) {
                            return module.project().documentPath(docId);
                        }
                    }
                }
            }
        }
        return Optional.empty();
    }

    private static boolean isLangLib(String orgName, String moduleName) {
        return orgName.equals("ballerina") && moduleName.startsWith("lang.");
    }

}
