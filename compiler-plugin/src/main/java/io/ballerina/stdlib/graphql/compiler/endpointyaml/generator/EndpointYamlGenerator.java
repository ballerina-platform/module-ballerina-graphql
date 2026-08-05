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

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator;
import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeParser;
import io.ballerina.compiler.syntax.tree.ParenthesizedArgList;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.io.IOException;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Optional;


public class EndpointYamlGenerator {
    private final ServiceDeclarationNode node;
    private final SyntaxNodeAnalysisContext context;
    private final String schemaFileName;

    private int port;
    final PackageMemberVisitor packageMemberVisitor;

    private static final String ARTIFACT_DIR = "artifact";
    private static final String GRAPHQL = "GraphQL";
    private static final String ENDPOINTS_FILE_NAME = "endpoints.yaml";
    private static final String LISTEN_TO = "listenTo";
    private static final String EMPTY_STR = "";
    private static final int PORT_PARAMETER_INDEX = 0;

    private record ListenerInfo(ParenthesizedArgList argList) {
    }

    private record ListenerResolution(ParenthesizedArgList argList) {
    }

    public EndpointYamlGenerator(ServiceDeclarationNode node, SyntaxNodeAnalysisContext context) {
        this(node, context, new FileNameGeneratorUtil(context).getFileName(), new PackageMemberVisitor());
    }

    private EndpointYamlGenerator(ServiceDeclarationNode node, SyntaxNodeAnalysisContext context,
                                  String schemaFileName, PackageMemberVisitor packageMemberVisitor) {
        this.node = node;
        this.context = context;
        this.schemaFileName = schemaFileName;
        this.packageMemberVisitor = packageMemberVisitor;
    }

    public Optional<Endpoint> getEndpoint() {
        String moduleName = context.moduleId().moduleName();
        ensureModuleVisited(moduleName);

        Optional<ListenerInfo> listenerInfoOpt = resolveListenerInfo(moduleName);
        if (listenerInfoOpt.isEmpty()) {
            reportListenerNotResolvedDiagnostic(context);
            return Optional.empty();
        }
        ListenerInfo listenerInfo = listenerInfoOpt.get();
        port = resolvePort(listenerInfo.argList());
        String basePath = buildBasePath();

        return Optional.of(new Endpoint(basePath, port, basePath, GRAPHQL, this.schemaFileName));
    }

    private void ensureModuleVisited(String moduleName) {
        Map<String, ModuleMemberVisitor> moduleVisitors = packageMemberVisitor
                .createModuleVisitor(moduleName, context.semanticModel());
        ModuleMemberVisitor moduleMemberVisitor = moduleVisitors.get(moduleName);
        packageMemberVisitor.setModuleVisitors(moduleVisitors);

        context.currentPackage()
                .module(context.moduleId())
                .documentIds()
                .forEach(docId -> {
                    SyntaxTree tree = context.currentPackage()
                            .module(context.moduleId())
                            .document(docId)
                            .syntaxTree();
                    tree.rootNode().accept(moduleMemberVisitor);
                });

    }

    private Optional<ListenerInfo> resolveListenerInfo(String moduleName) {
        Optional<ParenthesizedArgList> argList = Optional.empty();
        SemanticModel semanticModel = context.semanticModel();

        for (ExpressionNode raw : this.node.expressions()) {
            ExpressionNode expr = unwrapCheckExpression(raw);

            if (expr instanceof ExplicitNewExpressionNode explicit) {
                argList = Optional.ofNullable(explicit.parenthesizedArgList());
            } else if (expr instanceof ImplicitNewExpressionNode implicit) {
                argList = implicit.parenthesizedArgList();
            } else if (isNameReference(expr)) {
                Optional<ListenerResolution> resolution = resolveNamedListener(expr, moduleName, semanticModel);
                if (resolution.isPresent()) {
                    argList = Optional.ofNullable(resolution.get().argList());
                }
            }
        }
        return argList.map(ListenerInfo::new);

    }

    private ExpressionNode unwrapCheckExpression(ExpressionNode expr) {
        if (expr instanceof CheckExpressionNode checkedExpr) {
            return checkedExpr.expression();
        }
        return expr;
    }

    private boolean isNameReference(ExpressionNode expr) {
        return expr.kind().equals(SyntaxKind.SIMPLE_NAME_REFERENCE) ||
                expr.kind().equals(SyntaxKind.QUALIFIED_NAME_REFERENCE);
    }

    private Optional<ListenerResolution> resolveNamedListener(ExpressionNode expr, String moduleName,
                                                    SemanticModel semanticModel) {
        String listenerModuleName = getModuleName(semanticModel, expr);
        if (listenerModuleName.isEmpty()) {
            listenerModuleName = moduleName;
        }

        String listenerName;

        if (expr instanceof QualifiedNameReferenceNode refNode) {
            listenerName = unescapeIdentifier(refNode.identifier().text().trim());
        } else {
            listenerName = unescapeIdentifier(expr.toString().trim());
        }

        Optional<ListenerDeclarationNode> declOpt =
                packageMemberVisitor.getListenerDeclaration(listenerModuleName, listenerName);

        if (declOpt.isEmpty()) {
            return Optional.empty();
        }

        ListenerDeclarationNode decl = declOpt.get();
        Optional<ParenthesizedArgList> argList = extractArgListFromListenerDecl(decl);
        return argList.map(ListenerResolution::new);
    }

    private Optional<ParenthesizedArgList> extractArgListFromListenerDecl(ListenerDeclarationNode decl) {
        Node initNode = decl.initializer();
        if (initNode == null) {
            return Optional.empty();
        }
        ExpressionNode initializer = (ExpressionNode) initNode;
        initializer = unwrapCheckExpression(initializer);

        return switch (initializer.kind()) {
            case EXPLICIT_NEW_EXPRESSION ->
                    Optional.ofNullable(((ExplicitNewExpressionNode) initializer).parenthesizedArgList());
            case IMPLICIT_NEW_EXPRESSION -> ((ImplicitNewExpressionNode) initializer).parenthesizedArgList();
            default -> Optional.empty();
        };
    }

    private int resolvePort(ParenthesizedArgList argListOpt) {
        SeparatedNodeList<FunctionArgumentNode> arguments = argListOpt.arguments();
        resolvePortFromArgs(arguments);
        return port;
    }

    private void resolvePortFromArgs(SeparatedNodeList<FunctionArgumentNode> arguments) {
        for (int index = 0; index < arguments.size(); index++) {
            FunctionArgumentNode arg = arguments.get(index);
            if (arg instanceof NamedArgumentNode) {
                resolvePortFromNamedArgs(arguments, index);
                return;
            }
            if (index == PORT_PARAMETER_INDEX) {
                PositionalArgumentNode portArg = (PositionalArgumentNode) arg;
                String portVal = getPortValue(portArg.expression(), context.semanticModel(), context).orElse(null);
                if (portVal != null) {
                    try {
                        port = Integer.parseInt(portVal);
                    } catch (NumberFormatException e) {
                        reportNonNumericPort(context);
                    }
                }
            }
        }
    }

    private void resolvePortFromNamedArgs(SeparatedNodeList<FunctionArgumentNode> arguments, int startIndex) {
        for (int i = startIndex; i < arguments.size(); i++) {
            FunctionArgumentNode arg = arguments.get(i);
            if (arg instanceof NamedArgumentNode namedArg &&
                    namedArg.argumentName().toString().trim().equals(LISTEN_TO)) {
                String portValue = getPortValue(namedArg.expression(), context.semanticModel(), context)
                        .orElse(null);
                if (portValue != null) {
                    port = Integer.parseInt(portValue);
                }
            }
        }
    }

    private String buildBasePath() {
        StringBuilder basePath = new StringBuilder();
        for (Node identifierNode : this.node.absoluteResourcePath()) {
            basePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        String serviceBasePath = basePath.toString();
        if (EMPTY_STR.contentEquals(basePath)) {
            serviceBasePath = "/";
        }
        return serviceBasePath;
    }

    public static void writeEndpointsYaml(Path outPath, List<Endpoint> endpoints) throws IOException {
        Files.createDirectories(outPath.resolve(ARTIFACT_DIR));
        Path path = outPath.resolve(ARTIFACT_DIR).resolve(ENDPOINTS_FILE_NAME).toAbsolutePath();
        writeYaml(path, new EndpointsWrapper(endpoints));
    }

    private static void writeYaml(Path path, EndpointsWrapper wrapper) throws IOException {
        YAMLFactory yamlFactory = YAMLFactory.builder()
                .disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER)
                .build();
        ObjectMapper mapper = new ObjectMapper(yamlFactory);
        mapper.findAndRegisterModules();

        try (Writer writer = Files.newBufferedWriter(path)) {
            mapper.writeValue(writer, wrapper);
        } catch (IOException e) {
            throw new IOException("Failed to write to: " + path, e);
        }
    }

    private Optional<String> getPortValue(ExpressionNode expression, SemanticModel semanticModel,
                                          SyntaxNodeAnalysisContext context) {
        return getPortValue(expression, false, semanticModel, context);
    }

    private Optional<String> getPortValue(ExpressionNode expression, boolean isConfigurablePort,
                                          SemanticModel semanticModel, SyntaxNodeAnalysisContext context) {

        if (expression.kind().equals(SyntaxKind.NUMERIC_LITERAL)) {
            return resolveNumericLiteral(expression);
        }
        if (!isNameReference(expression)) {
            return Optional.empty();
        }
        return resolvePortFromVariable(expression, semanticModel, context, isConfigurablePort);
    }

    private Optional<String> resolveNumericLiteral(ExpressionNode expression) {
        BasicLiteralNode literal = (BasicLiteralNode) expression;
        return Optional.of(literal.literalToken().text());
    }

    private Optional<String> resolvePortFromVariable(ExpressionNode expression,
                                                     SemanticModel semanticModel,
                                                     SyntaxNodeAnalysisContext context, boolean isConfigurablePort) {
        String moduleName = getModuleName(semanticModel, expression);
        String portVariableName = extractVariableName(expression);

        Optional<ModuleMemberVisitor.VariableDeclaredValue> varOpt =
                packageMemberVisitor.getVariableDeclaredValue(moduleName, portVariableName);

        if (varOpt.isEmpty()) {
            return Optional.empty();
        }

        ModuleMemberVisitor.VariableDeclaredValue varVal = varOpt.get();
        String portValueSource = String.valueOf(varVal.value());
        ExpressionNode portExpr = portValueSource.isEmpty() ? null : NodeParser.parseExpression(portValueSource);

        if (portExpr == null || portExpr.isMissing()) {
            return Optional.empty();
        }

        return resolvePortExpression(portExpr, varVal.isConfigurable(), isConfigurablePort, semanticModel, context);
    }

    private String extractVariableName(ExpressionNode expression) {
        if (expression instanceof QualifiedNameReferenceNode refNode) {
            return unescapeIdentifier(refNode.identifier().text().trim());
        }
        return unescapeIdentifier(expression.toString().trim());
    }

    private Optional<String> resolvePortExpression(ExpressionNode portExpr, boolean isConfigurable,
                                                   boolean isConfigurablePort,
                                                   SemanticModel semanticModel,
                                                   SyntaxNodeAnalysisContext context) {
        if (portExpr.kind().equals(SyntaxKind.REQUIRED_EXPRESSION)) {
            reportMissingPortConfigDiagnostic(context);
            return Optional.empty();
        }
        if ((isConfigurable || isConfigurablePort) && portExpr.kind().equals(SyntaxKind.CONDITIONAL_EXPRESSION)) {
            reportMissingPortConfigDiagnostic(context);
        } else if (isConfigurable || isConfigurablePort) {
            reportDefaultPortConfigDiagnostic(context);
        }

        if (portExpr.kind().equals(SyntaxKind.NUMERIC_LITERAL)) {
            return resolveNumericLiteral(portExpr);
        }
        return getPortValue(portExpr, isConfigurable, semanticModel, context);
    }

    private void reportMissingPortConfigDiagnostic(SyntaxNodeAnalysisContext context) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "PORT_CONFIGURATION_BEING_NULL",
                "The configurable value provided for the port should have a " +
                        "default value to generate the server details " +
                "when --export-endpoints flag is present.",
                DiagnosticSeverity.ERROR
        );
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
    }

    private void reportDefaultPortConfigDiagnostic(SyntaxNodeAnalysisContext context) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "PORT_USING_CONFIGURABLE_DEFAULT",
                "The server port is defined as a configurable. Hence, " +
                        "using the default value to generate the server information " +
                "when --export-endpoints flag is present",
                DiagnosticSeverity.WARNING
        );
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
    }

    private void reportNonNumericPort(SyntaxNodeAnalysisContext context) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "PORT_BEING_NON_NUMERIC",
                "The server port should contain a numeric value.",
                DiagnosticSeverity.ERROR
        );
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
    }

    public void reportListenerNotResolvedDiagnostic(SyntaxNodeAnalysisContext context) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "LISTENER_NOT_RESOLVED",
                "No listener information found for this module.",
                DiagnosticSeverity.ERROR
        );
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
    }

    public static String unescapeIdentifier(String parameterName) {
        String unescapedParamName = Utils.unescapeBallerina(parameterName);
        return unescapedParamName.replace("\\\\", "").replace("'", "");
    }

    public static String getModuleName(SemanticModel semanticModel, Node node) {
        Optional<Symbol> symbol = semanticModel.symbol(node);
        if (symbol.isEmpty()) {
            return "";
        }
        return getModuleName(symbol.get());
    }

    public static String getModuleName(Symbol symbol) {
        Optional<ModuleSymbol> module = symbol.getModule();
        if (module.isEmpty()) {
            return "";
        }
        return module.get().id().moduleName();
    }

}
