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

import io.ballerina.projects.BalCommand;
import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.projects.plugins.CompilerLifecycleEventContext;
import io.ballerina.stdlib.graphql.compiler.Utils;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Stream;

public class EndpointsYamlWriterTaskTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();

    @Test
    public void testPerformReportsDiagnosticWhenWriteFails() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("endpoint_details_extraction_tests")
                .resolve("01_hardcoded_port");
        System.setProperty("ballerina.home", DISTRIBUTION_PATH.toString());
        BuildOptions buildOptions = BuildOptions.builder().build();
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath, buildOptions);
        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();
        Path targetDir = project.targetDir();

        try {
            // Pre-create "artifact" as a plain file so EndpointYamlGenerator's
            // Files.createDirectories(outPath.resolve("artifact")) fails with an IOException.
            deleteDirectories(targetDir);
            Files.createDirectories(targetDir);
            Files.createFile(targetDir.resolve("artifact"));

            Map<String, Object> ctxData = new HashMap<>();
            ctxData.put(Utils.GRAPHQL_EXPORTED_ENDPOINTS,
                    List.of(new Endpoint("/graphql", 9090, "/graphql", "GraphQL", "service_graphql.graphql")));

            List<Diagnostic> reportedDiagnostics = new ArrayList<>();
            CompilerLifecycleEventContext context = new CompilerLifecycleEventContext() {
                @Override
                public Package currentPackage() {
                    return currentPackage;
                }

                @Override
                public PackageCompilation compilation() {
                    return compilation;
                }

                @Override
                public void reportDiagnostic(Diagnostic diagnostic) {
                    reportedDiagnostics.add(diagnostic);
                }

                @Override
                public Optional<Path> getGeneratedArtifactPath() {
                    return Optional.empty();
                }

                @Override
                public BalCommand balCommand() {
                    return BalCommand.BUILD;
                }
            };

            new EndpointsYamlWriterTask(ctxData).perform(context);

            Assert.assertEquals(reportedDiagnostics.size(), 1,
                    "Expected one diagnostic reporting the endpoints.yaml write failure");
            Assert.assertEquals(reportedDiagnostics.get(0).diagnosticInfo().severity(), DiagnosticSeverity.ERROR);
            Assert.assertTrue(reportedDiagnostics.get(0).message().contains("artifact"),
                    "Expected diagnostic to describe the write failure: " + reportedDiagnostics.get(0).message());
        } finally {
            deleteDirectories(targetDir);
        }
    }

    private static void deleteDirectories(Path targetDir) throws Exception {
        if (Files.exists(targetDir)) {
            try (Stream<Path> paths = Files.walk(targetDir)) {
                paths.sorted(Comparator.reverseOrder()).forEach(p -> {
                    try {
                        Files.delete(p);
                    } catch (Exception e) {
                        // best-effort cleanup
                    }
                });
            }
        }
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }
}
