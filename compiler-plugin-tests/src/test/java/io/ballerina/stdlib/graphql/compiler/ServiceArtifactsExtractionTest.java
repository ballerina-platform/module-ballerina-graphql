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

package io.ballerina.stdlib.graphql.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.JBallerinaBackend;
import io.ballerina.projects.JvmTarget;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.graphql.compiler.endpointyaml.generator.FileNameGeneratorUtil;
import io.ballerina.stdlib.graphql.compiler.endpointyaml.generator.ModuleMemberVisitor;
import io.ballerina.stdlib.graphql.compiler.endpointyaml.generator.Utils;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.lang.reflect.Proxy;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Stream;

import static io.ballerina.projects.directory.BuildProject.load;

public class ServiceArtifactsExtractionTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final String GENERATOR_TESTS_DIR = "generator_tests";
    private static final String SCHEMA_VALIDATOR_DIR = "schema_validator_tests";
    private static final String ENDPOINT_DETAILS_TESTS_DIR = "endpoint_details_extraction_tests";
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();
    private static final Path YAML_FILES_DIRECTORY = Paths.get("src", "test", "resources", "yaml_files")
            .toAbsolutePath();

    private static final String VALIDATOR_TESTS_DIR = "validator_tests";
    private static final String ARTIFACT_DIR = "artifact";
    private static final String TARGET_DIR = "target";

    private static final String ENDPOINTS_FILE_NAME = "endpoints.yaml";
    private static final String GQL_SUFFIX = ".graphql";

    @Test
    public void testServiceArtifactsGenerationForSingleService() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(SCHEMA_VALIDATOR_DIR)
                .resolve("01_graphql_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no compilation/plugin errors");

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointsYaml = artifactDir.resolve(ENDPOINTS_FILE_NAME);
            Path expectedEndpointsYaml = YAML_FILES_DIRECTORY.resolve("endpoints_single_service.yaml");

            Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");
            Assert.assertTrue(Files.exists(endpointsYaml), "Consolidated endpoints YAML should be generated");
            verifyYamlContent(endpointsYaml, expectedEndpointsYaml);

        } finally {
            deleteDirectories(projectDirPath);
        }
    }


    @Test
    public void testServiceArtifactsGenerationForMultipleServices() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(GENERATOR_TESTS_DIR)
                .resolve("22_graphql_service_with_http_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no compilation/plugin errors");

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");

            Path endpointsYaml = artifactDir.resolve(ENDPOINTS_FILE_NAME);
            Assert.assertTrue(Files.exists(endpointsYaml), "Consolidated endpoints YAML should be generated");

            String content = Files.readString(endpointsYaml);
            Assert.assertTrue(content.contains("port: 9091"), "Expected port 9091 for the first service");
            Assert.assertTrue(content.contains("port: 9093"), "Expected port 9093 for the second service");

            long schemaCount = countFilesWithSuffix(artifactDir, GQL_SUFFIX);
            Assert.assertTrue(schemaCount > 1, "Expected schema artifacts for " +
                    "multiple services");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testServiceArtifactGenerationWithoutFlag() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(GENERATOR_TESTS_DIR)
                .resolve("01_scalar_types");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, false);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no compilation/plugin errors");
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertFalse(Files.exists(artifactDir));
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testServiceArtifactsGenerationForGqlWithHttp() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(GENERATOR_TESTS_DIR)
                .resolve("22_graphql_service_with_http_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no compilation/plugin errors");
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");
            long endpointCount = countEndpointEntries(artifactDir.resolve(ENDPOINTS_FILE_NAME));
            long schemaCount = countFilesWithSuffix(artifactDir, GQL_SUFFIX);
            Assert.assertTrue(endpointCount >= 2);
            Assert.assertEquals(schemaCount, 2);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testServiceArtifactsGenerationWithInvalidSchema() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(VALIDATOR_TESTS_DIR)
                .resolve("60_invalid_use_of_reserved_federation_type_names");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertTrue(diagnosticResult.errorCount() > 0);

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertFalse(Files.exists(artifactDir), "Artifacts should not be generated " +
                    "for invalid schema");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testServiceArtifactsGenerationWithDynamicallyAttachedListeners() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(VALIDATOR_TESTS_DIR)
                .resolve("23_dynamically_attaching_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertFalse(Files.exists(artifactDir));
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testServiceArtifactsWithDuplicateServicePaths() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("04_service_with_duplicate_paths");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");
            Assert.assertTrue(countEndpointEntries(artifactDir.resolve(ENDPOINTS_FILE_NAME)) >= 2);
            Assert.assertTrue(countFilesWithSuffix(artifactDir, GQL_SUFFIX) >= 2);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }


    @Test
    public void testResolveContractFileNameWithNonExistentOutPath() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("01_hardcoded_port");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        TestContextData data = getTestContextData(project);
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(data, diagnostics);

        Path nonExistentDir = Paths.get("/tmp/does_not_exist_" + System.currentTimeMillis());
        String result = FileNameGeneratorUtil.resolveContractFileName(
                nonExistentDir, "service_graphql.graphql", context);
        Assert.assertEquals(result, "service_graphql.graphql",
                "File name should be returned unchanged when outPath does not exist");
        Assert.assertTrue(diagnostics.isEmpty(), "Expected no diagnostics for non-existent outPath");
    }

    @Test
    public void testResolveContractFileNameWithNullOutPath() {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("01_hardcoded_port");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        TestContextData data = getTestContextData(project);
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(data, diagnostics);

        String result = FileNameGeneratorUtil.resolveContractFileName(
                null, "service_graphql.graphql", context);
        Assert.assertEquals(result, "service_graphql.graphql",
                "File name should be returned unchanged when outPath is null");
        Assert.assertTrue(diagnostics.isEmpty(), "Expected no diagnostics when outPath is null");
    }

    @Test
    public void testResolveContractFileNameReportsOverwriteWarning() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("01_hardcoded_port");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        TestContextData data = getTestContextData(project);
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(data, diagnostics);

        Path tempDir = Files.createTempDirectory("overwrite_test");
        try {
            // pre-create a conflicting file
            Files.createFile(tempDir.resolve("service_graphql.graphql"));

            FileNameGeneratorUtil.resolveContractFileName(
                    tempDir, "service_graphql.graphql", context);

            Assert.assertFalse(diagnostics.isEmpty(),
                    "Expected FILE_BEING_OVERWRITTEN diagnostic to be reported");
            boolean hasOverwriteWarning = diagnostics.stream()
                    .anyMatch(d -> d.diagnosticInfo().code().equals("FILE_BEING_OVERWRITTEN")
                            && d.diagnosticInfo().severity() == DiagnosticSeverity.WARNING);
            Assert.assertTrue(hasOverwriteWarning,
                    "Expected FILE_BEING_OVERWRITTEN warning diagnostic");
        } finally {
            deleteDirectories(tempDir);
        }
    }

    @Test
    public void testResolveContractFileNameNoConflict() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("01_hardcoded_port");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        TestContextData data = getTestContextData(project);
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(data, diagnostics);

        Path tempDir = Files.createTempDirectory("no_conflict_test");
        try {
            String result = FileNameGeneratorUtil.resolveContractFileName(
                    tempDir, "service_graphql.graphql", context);
            Assert.assertEquals(result, "service_graphql.graphql",
                    "File name should be unchanged when no conflict exists");
            Assert.assertTrue(diagnostics.isEmpty(), "Expected no diagnostics when no conflict");
        } finally {
            deleteDirectories(tempDir);
        }
    }

    @Test
    public void testUnescapeUnicodeCodepointsBasicCharacter() {
        Assert.assertEquals(Utils.unescapeUnicodeCodepoints("\\u{0041}"), "A");
    }

    @Test
    public void testUnescapeUnicodeCodepointsLowercaseHex() {
        Assert.assertEquals(Utils.unescapeUnicodeCodepoints("\\u{0061}"), "a");
    }

    @Test
    public void testUnescapeUnicodeCodepointsBackslashCharacter() {
        String result = Utils.unescapeUnicodeCodepoints("\\u{005C}");
        Assert.assertTrue(result.contains("\\"),
                "Backslash codepoint should produce a backslash in output");
    }

    @Test
    public void testGetNormalizedFileNameWithSlashes() {
        Assert.assertEquals(FileNameGeneratorUtil.getNormalizedFileName("/graphql/api"), "graphql_api");
    }

    @Test
    public void testGetNormalizedFileNameWithHyphens() {
        Assert.assertEquals(FileNameGeneratorUtil.getNormalizedFileName("my-service"), "my_service");
    }

    @Test
    public void testGetNormalizedFileNameWithMixedSeparators() {
        Assert.assertEquals(FileNameGeneratorUtil.getNormalizedFileName("/my-graphql/api_v2"), "my_graphql_api_v2");
    }

    @Test
    public void testGetNormalizedFileNameWithConsecutiveSeparators() {
        // blank segments filtered out
        Assert.assertEquals(FileNameGeneratorUtil.getNormalizedFileName("//graphql"), "graphql");
    }

    @Test
    public void testResolveContractFileNameDifferentExtensionSameStem() throws IOException {
        // existing file has a different extension but same stem → still a conflict
        // isSameFileName strips extension before comparing
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("01_hardcoded_port");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(getTestContextData(project), diagnostics);

        Path tempDir = Files.createTempDirectory("same_stem_test");
        try {
            // existing file has .yaml extension, new file has .graphql — same stem
            Files.createFile(tempDir.resolve("service_graphql.yaml"));

            FileNameGeneratorUtil.resolveContractFileName(
                    tempDir, "service_graphql.graphql", context);

            boolean hasWarning = diagnostics.stream()
                    .anyMatch(d -> d.diagnosticInfo().code().equals("FILE_BEING_OVERWRITTEN"));
            Assert.assertTrue(hasWarning,
                    "Same stem with different extension should still trigger overwrite warning");
        } finally {
            deleteDirectories(tempDir);
        }
    }

    @Test
    public void testGetFileNameForRootPathService() {
        // service / on new graphql:Listener(9090)
        // fileName.equals(SLASH) → <balFileName>.graphql
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("13_service_with_root_path");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(getTestContextData(project), diagnostics);

        FileNameGeneratorUtil util = new FileNameGeneratorUtil(context);
        String fileName = util.getFileName();

        Assert.assertEquals(fileName, "service.graphql",
                "Root path service should produce <balFileName>.graphql");
        Assert.assertTrue(diagnostics.isEmpty(), "Expected no diagnostics");
    }

    @Test
    public void testGetFileNameWhenServiceSymbolEmptyWithBasePath() {
        // serviceSymbol.isEmpty() and base path is non-blank
        // expected: service_graphql.graphql
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("14_service_symbol_empty_with_basepath");
        BuildProject project = loadProject(projectDirPath);
        List<Diagnostic> diagnostics = new ArrayList<>();
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(getTestContextData(project), diagnostics);

        FileNameGeneratorUtil util = new FileNameGeneratorUtil(context);
        String fileName = util.getFileName();

        Assert.assertTrue(fileName.contains("graphql") && fileName.endsWith(".graphql"),
                "File name should include base path segment when symbol is unresolved: " + fileName);
    }

    @Test
    public void testVisitConstantDeclarationRegistersVariable() {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_TESTS_DIR)
                .resolve("15_constant_port");
        BuildProject project = loadProject(projectDirPath);
        TestContextData data = getTestContextData(project);

        ModuleMemberVisitor visitor = new ModuleMemberVisitor(data.semanticModel);
        data.syntaxTree.rootNode().accept(visitor);

        Optional<ModuleMemberVisitor.VariableDeclaredValue> portOpt =
                visitor.getVariableDeclaredValue("PORT");
        Assert.assertTrue(portOpt.isPresent(), "Constant PORT should be registered");
        Assert.assertFalse(portOpt.get().isConfigurable(),
                "Constant declarations are always non-configurable");
        Assert.assertEquals(portOpt.get().value().toString().trim(), "9090",
                "Constant value should be 9090");
    }

    private BuildProject loadProject(Path projectDirPath) {
        BuildOptions buildOptions = BuildOptions.builder().setExportEndpoints(true).build();
        return BuildProject.load(getEnvironmentBuilder(), projectDirPath, buildOptions);
    }

    private TestContextData getTestContextData(BuildProject project) {
        io.ballerina.projects.Package currentPackage = project.currentPackage();
        io.ballerina.projects.Module module = currentPackage.getDefaultModule();
        DocumentId documentId = module.documentIds().iterator().next();
        Document document = module.document(documentId);
        SyntaxTree syntaxTree = document.syntaxTree();
        SemanticModel semanticModel = currentPackage.getCompilation().getSemanticModel(documentId.moduleId());
        ModulePartNode modulePartNode = syntaxTree.rootNode();
        ServiceDeclarationNode serviceNode = null;

        for (Node member : modulePartNode.members()) {
            if (member.kind() == SyntaxKind.SERVICE_DECLARATION) {
                serviceNode = (io.ballerina.compiler.syntax.tree.ServiceDeclarationNode) member;
                break;
            }
        }

        if (serviceNode == null) {
            throw new IllegalStateException("No service declaration node found in source file");
        }

        return new TestContextData(currentPackage, syntaxTree, semanticModel, serviceNode,
                documentId, currentPackage.getCompilation());
    }

    private SyntaxNodeAnalysisContext createSyntaxNodeAnalysisContext(TestContextData data,
                                                                      List<Diagnostic> reportedDiagnostics) {
        return (SyntaxNodeAnalysisContext) Proxy.newProxyInstance(
                SyntaxNodeAnalysisContext.class.getClassLoader(),
                new Class[]{SyntaxNodeAnalysisContext.class},
                (proxy, method, args) -> switch (method.getName()) {
                    case "node" -> data.serviceNode;
                    case "syntaxTree" -> data.syntaxTree;
                    case "semanticModel" -> data.semanticModel;
                    case "currentPackage" -> data.currentPackage;
                    case "documentId" -> data.documentId;
                    case "moduleId" -> data.documentId.moduleId();
                    case "compilation" -> data.compilation;
                    case "reportDiagnostic" -> {
                        if (args != null && args.length == 1 && args[0] instanceof Diagnostic) {
                            reportedDiagnostics.add((Diagnostic) args[0]);
                        }
                        yield null;
                    }
                    default -> throw new UnsupportedOperationException("Unsupported context method: " +
                            method.getName());
                });
    }

    private static void verifyYamlContent(Path actualYaml, Path expectedYaml) throws IOException {
        String endpointContent = Files.readString(actualYaml);
        String expectedEndpointContent = Files.readString(expectedYaml);
        Assert.assertEquals(endpointContent.replaceAll("\\s+", ""),
                expectedEndpointContent.replaceAll("\\s+", ""));
    }

    private static DiagnosticResult getDiagnosticResults(Path projectDirPath, boolean isExportEndpoints)
            throws IOException {
        System.setProperty("ballerina.home", DISTRIBUTION_PATH.toString());
        BuildOptions buildOptions = BuildOptions.builder().setExportEndpoints(isExportEndpoints).build();
        BuildProject project = load(getEnvironmentBuilder(), projectDirPath, buildOptions);
        DiagnosticResult diagnosticResult = project.currentPackage().runCodeGenAndModifyPlugins();
        if (diagnosticResult.errorCount() == 0) {
            PackageCompilation compilation = project.currentPackage().getCompilation();
            JBallerinaBackend jBallerinaBackend = JBallerinaBackend.from(compilation, JvmTarget.JAVA_21);
            Path executablePath = project.targetDir().resolve("bin").resolve("output.jar");
            Files.createDirectories(executablePath.getParent());
            jBallerinaBackend.emit(JBallerinaBackend.OutputType.EXEC, executablePath);
        }
        return diagnosticResult;
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private static long countEndpointEntries(Path endpointsYaml) throws IOException {
        try (Stream<String> lines = Files.lines(endpointsYaml)) {
            return lines.filter(line -> line.trim().startsWith("- name:")).count();
        }
    }

    private static long countFilesWithSuffix(Path directory, String suffix) throws IOException {
        try (Stream<Path> paths = Files.walk(directory)) {
            return paths.filter(Files::isRegularFile)
                    .filter(path -> {
                        Path fileName = path.getFileName();
                        return fileName != null && fileName.toString().endsWith(suffix);
                    })
                    .count();
        }
    }

    private void deleteDirectories(Path projectDirPath) throws IOException {
        Path targetDir = projectDirPath.resolve(TARGET_DIR);
        if (Files.exists(targetDir)) {
            try (Stream<Path> paths = Files.walk(targetDir)) {
                paths.sorted(Comparator.reverseOrder())
                        .forEach(path -> {
                            try {
                                Files.delete(path);
                            } catch (IOException e) {
                                Assert.fail("Failed to delete file: " + path, e);
                            }
                        });
            }
        }

        Path dependenciesFile = projectDirPath.resolve("Dependencies.toml");
        if (Files.exists(dependenciesFile)) {
            Files.delete(dependenciesFile);
        }
    }

    private static class TestContextData {
        private final io.ballerina.projects.Package currentPackage;
        private final SyntaxTree syntaxTree;
        private final SemanticModel semanticModel;
        private final io.ballerina.compiler.syntax.tree.ServiceDeclarationNode serviceNode;
        private final DocumentId documentId;
        private final PackageCompilation compilation;

        private TestContextData(Package currentPackage, SyntaxTree syntaxTree, SemanticModel semanticModel,
                                io.ballerina.compiler.syntax.tree.ServiceDeclarationNode serviceNode,
                                DocumentId documentId, PackageCompilation compilation) {
            this.currentPackage = currentPackage;
            this.syntaxTree = syntaxTree;
            this.semanticModel = semanticModel;
            this.serviceNode = serviceNode;
            this.documentId = documentId;
            this.compilation = compilation;
        }
    }

}
