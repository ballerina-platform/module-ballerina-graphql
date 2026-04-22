/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

public class FileNameGeneratorUtil {

    private static final String SLASH = "/";
    private static final String UNDERSCORE = "_";
    private static final String HYPHEN = "-";
    private final Map<Integer, String> services = new HashMap<>();

    private SyntaxNodeAnalysisContext context = null;
    private static final String SCHEMA_EXTENSION = ".graphql";

    public FileNameGeneratorUtil(SyntaxNodeAnalysisContext context) {
        this.context = context;
    }

    public String getFileName() {
        SyntaxTree syntaxTree = context.syntaxTree();
        SemanticModel semanticModel = context.semanticModel();
        extractServiceNodes(syntaxTree.rootNode(), semanticModel);

        String balFileName = syntaxTree.filePath().replaceAll(SLASH, UNDERSCORE).split("\\.")[0];
        if (!(context.node() instanceof ServiceDeclarationNode node)) {
            return balFileName + SCHEMA_EXTENSION;
        }

        Optional<Symbol> serviceSymbol = semanticModel.symbol(node);
        if (serviceSymbol.isEmpty()) {
            String basePathName = getServiceBasePath(node);
            if (!basePathName.isBlank()) {
                return balFileName + UNDERSCORE + getNormalizedFileName(basePathName) + SCHEMA_EXTENSION;
            }
            return balFileName + SCHEMA_EXTENSION;
        }

        return constructFileName(syntaxTree, services, serviceSymbol.get());
    }

    private void extractServiceNodes(ModulePartNode modulePartNode,
                                     SemanticModel semanticModel) {
        List<String> allServices = new ArrayList<>();
        for (Node node : modulePartNode.members()) {
            if (!SyntaxKind.SERVICE_DECLARATION.equals(node.kind())) {
                continue;
            }
            ServiceDeclarationNode serviceNode = (ServiceDeclarationNode) node;
            Optional<Symbol> serviceSymbol = semanticModel.symbol(serviceNode);
            if (semanticModel.symbol(serviceNode).isEmpty() ||
                    !(semanticModel.symbol(serviceNode).get() instanceof ServiceDeclarationSymbol)) {
                continue;
            }
            StringBuilder basePath = new StringBuilder();
            NodeList<Node> resourcePathNode = ((ServiceDeclarationNode) node).absoluteResourcePath();

            for (Node identifierNode : resourcePathNode) {
                basePath.append(identifierNode.toString().trim());
            }

            String serviceBasePath = basePath.toString();
            if (allServices.contains(serviceBasePath)) {
                serviceBasePath = serviceBasePath + HYPHEN + serviceSymbol.get().hashCode();
            } else {
                allServices.add(serviceBasePath);
            }
            services.put(serviceSymbol.get().hashCode(), serviceBasePath);
        }
    }

    private String constructFileName(SyntaxTree syntaxTree, Map<Integer, String> services,
                                     Symbol serviceSymbol) {
        String serviceName = services.get(serviceSymbol.hashCode());
        String fileName = serviceName == null ? "" : getNormalizedFileName(serviceName);
        String[] fileNames = syntaxTree.filePath().replaceAll(SLASH, UNDERSCORE).split("\\.");

        if (fileNames.length == 0) {
            return "";
        }
        String balFileName = fileNames[0];
        if (fileName.equals(SLASH)) {
            return balFileName + SCHEMA_EXTENSION;
        }
        if (fileName.contains(HYPHEN) && fileName.split(HYPHEN)[0].equals(SLASH) || fileName.isBlank()) {
            return balFileName + UNDERSCORE + serviceSymbol.hashCode() + SCHEMA_EXTENSION;
        }
        return balFileName + UNDERSCORE + fileName + SCHEMA_EXTENSION;
    }

    private String getServiceBasePath(ServiceDeclarationNode serviceNode) {
        StringBuilder basePath = new StringBuilder();
        NodeList<Node> pathSegments = serviceNode.absoluteResourcePath();
        for (Node identifierNode : pathSegments) {
            basePath.append(identifierNode.toString().trim());
        }
        return basePath.toString();
    }

    public static String getNormalizedFileName(String fileName) {
        String[] splitNames = fileName.split("[^a-zA-Z0-9]");
        if (splitNames.length > 0) {
            return Arrays.stream(splitNames)
                    .filter(namePart -> !namePart.isBlank())
                    .collect(Collectors.joining(UNDERSCORE));
        }
        return fileName;
    }

    public static String resolveContractFileName(Path outPath, String fileName, SyntaxNodeAnalysisContext context) {
        if (outPath != null && Files.exists(outPath)) {
            final File[] listFiles = new File(String.valueOf(outPath)).listFiles();
            if (listFiles != null) {
                fileName = checkAvailabilityOfGivenName(fileName, listFiles, context);
            }
        }
        return fileName;
    }

    private static String checkAvailabilityOfGivenName(String fileName, File[] listFiles,
                                                       SyntaxNodeAnalysisContext context) {
        for (File file : listFiles) {
            if (!isSameFileName(file.getName(), fileName)) {
                continue;
            }
            if (System.console() != null) {
                String userInput = System.console().readLine("There is already a file named '" + file.getName() +
                        "' in the target location. Do you want to overwrite the file? [y/N] ");
                if (!Objects.equals(userInput.toLowerCase(Locale.ENGLISH), "y")) {
                    fileName = setGeneratedFileName(listFiles, fileName);
                }
            } else {
                DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                        "FILE_BEING_OVERWRITTEN",
                        "There is already a file named '" + file.getName() +
                                "' in the target location. File will be overwritten.",
                        DiagnosticSeverity.WARNING
                );
                context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
            }
        }
        return fileName;
    }

    private static boolean isSameFileName(String file1, String file2) {
        String fileName1 = getFileNameWithoutExtension(file1);
        String fileName2 = getFileNameWithoutExtension(file2);
        return fileName1.equals(fileName2);
    }

    private static String getFileNameWithoutExtension(String fileName) {
        int i = fileName.lastIndexOf('.');
        return i == -1 ? fileName : fileName.substring(0, i);
    }

    private static String setGeneratedFileName(File[] filesList, String fileName) {
        int duplicateCount = 0;
        for (File file : filesList) {
            String fName = file.getName();
            if (isSameFileName(fName, fileName)) {
                duplicateCount++;
            }
        }
        return fileName.split("\\.")[0] + "." + duplicateCount;
    }
}
