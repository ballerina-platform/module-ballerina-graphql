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

    @Test
    public void testHardcodedPortExtraction() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("01_hardcoded_port");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_graphql_endpoint.yaml");
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointPort(endpointYaml, 9090);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testConfigurablePortWithDefaultValue() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("02_configurable_port_default");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_graphql_endpoint.yaml");
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointPort(endpointYaml, 9091);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testConfigurablePortWithRequiredValue()  throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("03_configurable_port_required");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_graphql_endpoint.yaml");
            Assert.assertNotEquals(diagnosticResult.errorCount(), 0);
            assertEndpointPort(endpointYaml, 0);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testEndpointYamlContainsExpectedPortForMultipleServices() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(GENERATOR_TESTS_DIR)
                .resolve("22_graphql_service_with_http_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointPort(projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                            .resolve("service_endpoint.yaml"),
                    9091);
            assertEndpointPort(projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve("service_too_endpoint.yaml"), 9093);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testBasePathForSingleService() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(ENDPOINT_DETAILS_EXTRACTION_TESTS)
                .resolve("01_hardcoded_port");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_graphql_endpoint.yaml");
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointBasePath(endpointYaml, "\"/graphql\"");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testBasePathForMultipleServices() throws IOException {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(GENERATOR_TESTS_DIR)
                .resolve("22_graphql_service_with_http_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0);
            assertEndpointBasePath(projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                            .resolve("service_endpoint.yaml"),
                    "\"/\"");
            assertEndpointBasePath(projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR)
                    .resolve("service_too_endpoint.yaml"), "\"/too\"");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    private static DiagnosticResult getDiagnosticResults(Path projectDirPath, boolean isExportEndpoints) {
        BuildOptions buildOptions = BuildOptions.builder().setExportEndpoints(isExportEndpoints).build();
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath, buildOptions);
        return project.currentPackage().runCodeGenAndModifyPlugins();
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
                    .orElseThrow(() -> new AssertionError("No port field found in: " + endpointYaml));
            String actualBasePath = portLine.substring("basePath:".length()).trim();
            Assert.assertEquals(actualBasePath, expectedBasePath, "Unexpected endpoint port in " + endpointYaml);
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
