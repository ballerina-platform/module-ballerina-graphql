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

    private static final String ENDPOINT_SUFFIX = "_endpoint.yaml";
    private static final String GQL_SUFFIX = ".graphql";

    private static final String ENDPOINT_YAML_GEN_ERROR_MSG = "Endpoint YAML file should be generated";
    private static final String ARTIFACT_DIR_EXIST_MSG = "Artifact directory should exist";
    private static final String NO_ERRORS_EXPECTED_MSG = "Expected no compilation/plugin errors";
    private static final String SCHEMA_ARTIFACTS_FOR_MULTIPLE_SERVICES_MSG = "Expected schema artifacts for " +
            "multiple services";
    private static final String SCHEMA_GEN_ERROR_FOR_INVALID_SCHEMA = "Artifacts should not be generated " +
            "for invalid schema";

    @Test
    public void testServiceArtifactsGenerationForSingleService() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve(SCHEMA_VALIDATOR_DIR)
                .resolve("01_graphql_service");
        try {
            DiagnosticResult diagnosticResult = getDiagnosticResults(projectDirPath, true);
            Assert.assertEquals(diagnosticResult.errorCount(), 0,
                    NO_ERRORS_EXPECTED_MSG);

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_graphql2_endpoint.yaml");
            Path expectedEndpointYaml = YAML_FILES_DIRECTORY.resolve("service_graphql2_endpoint.yaml");

            Assert.assertTrue(Files.exists(artifactDir), ARTIFACT_DIR_EXIST_MSG);
            Assert.assertTrue(Files.exists(endpointYaml), ENDPOINT_YAML_GEN_ERROR_MSG);
            verifyYamlContent(endpointYaml, expectedEndpointYaml);

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
                    NO_ERRORS_EXPECTED_MSG);

            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), ARTIFACT_DIR_EXIST_MSG);

            Path endpointYaml1 = artifactDir.resolve("service_endpoint.yaml");
            Path endpointYaml2 = artifactDir.resolve("service_too_endpoint.yaml");
            Path expectedDir = YAML_FILES_DIRECTORY;

            Assert.assertTrue(Files.exists(endpointYaml1), ENDPOINT_YAML_GEN_ERROR_MSG);
            Assert.assertTrue(Files.exists(endpointYaml2), ENDPOINT_YAML_GEN_ERROR_MSG);

            verifyYamlContent(endpointYaml1, expectedDir.resolve("service_endpoint.yaml"));
            verifyYamlContent(endpointYaml2, expectedDir.resolve("service_too_endpoint.yaml"));

            long schemaCount = countFilesWithSuffix(artifactDir, GQL_SUFFIX);
            Assert.assertTrue(schemaCount > 1, SCHEMA_ARTIFACTS_FOR_MULTIPLE_SERVICES_MSG);
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
                    NO_ERRORS_EXPECTED_MSG);
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
                    NO_ERRORS_EXPECTED_MSG);
            Path artifactDir = projectDirPath.resolve(TARGET_DIR).resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), ARTIFACT_DIR_EXIST_MSG);
            long endpointYamlCount = countFilesWithSuffix(artifactDir, ENDPOINT_SUFFIX);
            long schemaCount = countFilesWithSuffix(artifactDir, GQL_SUFFIX);
            Assert.assertTrue(endpointYamlCount >= 2);
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
            Assert.assertFalse(Files.exists(artifactDir), SCHEMA_GEN_ERROR_FOR_INVALID_SCHEMA);
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
            Assert.assertTrue(Files.exists(artifactDir), ARTIFACT_DIR_EXIST_MSG);
            Assert.assertTrue(countFilesWithSuffix(artifactDir, ENDPOINT_SUFFIX) >= 2);
            Assert.assertTrue(countFilesWithSuffix(artifactDir, GQL_SUFFIX) >= 2);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    private static void verifyYamlContent(Path actualYaml, Path expectedYaml) throws IOException {
        String endpointContent = Files.readString(actualYaml);
        String expectedEndpointContent = Files.readString(expectedYaml);
        Assert.assertEquals(endpointContent.replaceAll("\\s+", ""),
                expectedEndpointContent.replaceAll("\\s+", ""));
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
}
