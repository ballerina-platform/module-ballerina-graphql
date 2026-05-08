/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.graphql.compiler.endpointyaml.generator;


import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.NodeVisitor;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

public class PackageMemberVisitor extends NodeVisitor {

    private Map<String, ModuleMemberVisitor> moduleVisitors = new LinkedHashMap<>();

    public void setModuleVisitors(Map<String, ModuleMemberVisitor> moduleVisitors) {
        this.moduleVisitors = new LinkedHashMap<>(moduleVisitors);
    }

    public Map<String, ModuleMemberVisitor> createModuleVisitor(String moduleName, SemanticModel semanticModel) {
        ModuleMemberVisitor visitor = new ModuleMemberVisitor(semanticModel);
        this.moduleVisitors.put(moduleName, visitor);
        return this.moduleVisitors;
    }

    public Optional<ModuleMemberVisitor> getModuleVisitor(String moduleName) {
        if (moduleVisitors.containsKey(moduleName)) {
            return Optional.of(moduleVisitors.get(moduleName));
        }
        return Optional.empty();
    }

    public Optional<ListenerDeclarationNode> getListenerDeclaration(String moduleName, String listenerName) {
        return getModuleVisitor(moduleName)
                .flatMap(moduleVisitor -> moduleVisitor.getListenerDeclaration(listenerName));
    }

    public Optional<ModuleMemberVisitor.VariableDeclaredValue> getVariableDeclaredValue(String moduleName,
                                                                                        String variableName) {
        return getModuleVisitor(moduleName)
                .flatMap(moduleVisitor -> moduleVisitor.getVariableDeclaredValue(variableName));
    }
}
