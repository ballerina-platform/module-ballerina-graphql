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

import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.JBallerinaBackend;
import io.ballerina.projects.JvmTarget;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.stream.Stream;

public class EndpointDetailsExtractorTest {
    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final String ENDPOINT_DETAILS_EXTRACTION_TESTS = "endpoint_details_extraction_tests";
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();
    private static final String GENERATOR_TESTS_DIR = "generator_tests";

    private static final String TARGET_DIR = "target";
    private static final String ARTIFACT_DIR = "artifact";
    private static final String ENDPOINTS_FILE_NAME = "endpoints.yaml";

    @Test
    public void testConfigurablePortWithDefaultValue() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("02_configurable_port_default");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve(ENDPOINTS_FILE_NAME);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointPort(endpointYaml, 9091);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testConfigurablePortWithRequiredValue() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("03_configurable_port_required");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertNotEquals(diagnosticResult.errorCount(), 0);
            boolean hasListenerError = hasDiagnosticCodeOrMessage(projectDirPath,
                    "PORT_CONFIGURATION_BEING_NULL", null);
            Assert.assertTrue(hasListenerError, "Expected PORT_CONFIGURATION_BEING_NULL diagnostic");

        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testEndpointDetailsForSingleService() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("01_hardcoded_port");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve(ENDPOINTS_FILE_NAME);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointPort(endpointYaml, 9090);
            assertEndpointBasePath(endpointYaml, "/graphql");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testBasePathForMultipleServices() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(GENERATOR_TESTS_DIR)
                .resolve("22_graphql_service_with_http_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            Path endpointsYaml = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve(ENDPOINTS_FILE_NAME);
            String content = Files.readString(endpointsYaml);
            Assert.assertTrue(content.contains("basePath: \"/\""), "Expected basePath \"/\" for the first service");
            Assert.assertTrue(content.contains("basePath: \"/too\""),
                    "Expected basePath \"/too\" for the second service");
            Assert.assertTrue(content.contains("port: 9091"), "Expected port 9091 for the first service");
            Assert.assertTrue(content.contains("port: 9093"), "Expected port 9093 for the second service");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testListenerNotResolved() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("05_listener_not_resolved");
        try {
            boolean hasListenerError = hasDiagnosticCodeOrMessage(projectDirPath,
                    "LISTENER_NOT_RESOLVED", "undefined symbol");
            Assert.assertTrue(hasListenerError, "Expected LISTENER_NOT_RESOLVED diagnostic");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testNamedListenerReference() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("06_named_listener_reference");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no errors for named listener reference");
            Path endpointYaml = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve(ENDPOINTS_FILE_NAME);
            Assert.assertTrue(Files.exists(endpointYaml), "Endpoint YAML should be generated");
            assertEndpointPort(endpointYaml, 9090);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testImplicitNewExpressionListener() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("07_implicit_new_listener");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no errors for implicit new listener");
            Path endpointYaml = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve(ENDPOINTS_FILE_NAME);
            Assert.assertTrue(Files.exists(endpointYaml), "Endpoint YAML should be generated");
            assertEndpointPort(endpointYaml, 9090);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testExplicitNewExpressionListener() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("08_explicit_new_listener");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no errors for explicit new listener");
            Path endpointYaml = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve(ENDPOINTS_FILE_NAME);
            Assert.assertTrue(Files.exists(endpointYaml), "Endpoint YAML should be generated");
            assertEndpointPort(endpointYaml, 9090);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testCheckExpressionUnwrapping() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("09_check_expression_listener");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no errors when listener is wrapped in check");
            Path endpointYaml = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve(ENDPOINTS_FILE_NAME);
            Assert.assertTrue(Files.exists(endpointYaml), "Endpoint YAML should be generated");
            assertEndpointPort(endpointYaml, 9090);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testNamedArgumentPortExtraction() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("10_named_arg_port");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    "Expected no errors for named argument port");
            Path endpointYaml = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve(ENDPOINTS_FILE_NAME);
            Assert.assertTrue(Files.exists(endpointYaml), "Endpoint YAML should be generated");
            assertEndpointPort(endpointYaml, 9090);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testNonNumericPortReportsDiagnostic() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("11_non_numeric_port");
        try {
            boolean hasPortError = hasDiagnosticCodeOrMessage(projectDirPath,
                    "PORT_BEING_NON_NUMERIC", "incompatible types");
            Assert.assertTrue(hasPortError, "Expected PORT_BEING_NON_NUMERIC diagnostic");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testRequiredConfigurablePortReportsDiagnostic() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("03_configurable_port_required");
        try {
            boolean hasMissingPortError = hasDiagnosticCodeOrMessage(projectDirPath,
                    "PORT_CONFIGURATION_BEING_NULL", null);
            Assert.assertTrue(hasMissingPortError, "Expected PORT_CONFIGURATION_BEING_NULL diagnostic code");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    private static DiagnosticResult getDiagnosticResults(Path projectDirPath) throws IOException {
        System.setProperty("ballerina.home", DISTRIBUTION_PATH.toString());
        BuildOptions buildOptions = BuildOptions.builder().setExportEndpoints(true).build();
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath, buildOptions);
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

    private static boolean hasDiagnosticCodeOrMessage(Path projectDirPath, String diagnosticCode,
                                                      String messageSegment) {
        BuildOptions buildOptions = BuildOptions.builder().setExportEndpoints(true).build();
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath, buildOptions);

        DiagnosticResult compilationDiagnostics = project.currentPackage().getCompilation().diagnosticResult();
        DiagnosticResult pluginDiagnostics = project.currentPackage().runCodeGenAndModifyPlugins();
        return Stream.concat(compilationDiagnostics.diagnostics().stream(), pluginDiagnostics.diagnostics().stream())
                .anyMatch(diagnostic -> {
                    String code = diagnostic.diagnosticInfo().code();
                    if (diagnosticCode.equals(code)) {
                        return true;
                    }
                    String message = diagnostic.message();
                    if (messageSegment != null && !messageSegment.isEmpty()) {
                        return message.contains(messageSegment);
                    }
                    return false;
                });
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private static void assertEndpointPort(Path endpointYaml, int expectedPort) throws IOException {
        try (Stream<String> lines = Files.lines(endpointYaml)) {
            String portLine = lines.map(String::trim)
                    .filter(line -> line.startsWith("port:"))
                    .findFirst()
                    .orElseThrow(() -> new AssertionError("No port field found in: " + endpointYaml));
            int actualPort = Integer.parseInt(portLine.substring("port:".length()).trim());
            Assert.assertEquals(actualPort, expectedPort, "Unexpected endpoint port in " + endpointYaml);
        }
    }

    private static void assertEndpointBasePath(Path endpointYaml, String expectedBasePath) throws IOException {
        try (Stream<String> lines = Files.lines(endpointYaml)) {
            String portLine = lines.map(String::trim)
                    .filter(line -> line.startsWith("basePath:"))
                    .findFirst()
                    .orElseThrow(() -> new AssertionError("No basepath field found in: " + endpointYaml));
            String actualBasePath = portLine.substring("basePath:".length()).trim().replace("\"", "");
            Assert.assertEquals(actualBasePath, expectedBasePath, "Unexpected endpoint basepath in " + endpointYaml);
        }
    }

    private void deleteDirectories(Path projectDirPath) throws IOException {
        Path targetDir = projectDirPath.resolve(TARGET_DIR);
        if (Files.exists(targetDir)) {
            try (Stream<Path> paths = Files.walk(targetDir)) {
                paths.sorted(Comparator.reverseOrder()).forEach(path -> {
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
}
