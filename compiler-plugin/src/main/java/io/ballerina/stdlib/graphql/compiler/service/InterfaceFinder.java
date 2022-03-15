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

package io.ballerina.stdlib.graphql.compiler.service;

import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static io.ballerina.stdlib.graphql.compiler.Utils.isResourceMethod;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceReference;

/**
 * Finds and validates possible GraphQL interfaces in a Ballerina service.
 */
public class InterfaceFinder {
    private final Map<String, List<ClassSymbol>> interfaceImplementations;
    private final Map<String, ClassSymbol> possibleInterfaces;
    private final List<String> validInterfaces;

    public InterfaceFinder() {
        this.interfaceImplementations = new HashMap<>();
        this.possibleInterfaces = new HashMap<>();
        this.validInterfaces = new ArrayList<>();
    }

    public void populateInterfaces(SyntaxNodeAnalysisContext context) {
        for (Symbol symbol : context.semanticModel().moduleSymbols()) {
            if (!isServiceClass(symbol)) {
                continue;
            }
            ClassSymbol classSymbol = (ClassSymbol) symbol;
            if (classSymbol.getName().isEmpty()) {
                continue;
            }
            findPossibleInterfaces(classSymbol);
        }
    }

    private void findPossibleInterfaces(ClassSymbol classSymbol) {
        for (TypeSymbol typeSymbol : classSymbol.typeInclusions()) {
            if (!isServiceReference(typeSymbol)) {
                continue;
            }
            if (typeSymbol.getName().isEmpty()) {
                continue;
            }
            ClassSymbol interfaceClass = (ClassSymbol) ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
            String interfaceName = typeSymbol.getName().get();
            addPossibleInterface(interfaceName, interfaceClass);
            addInterfaceImplementation(interfaceName, classSymbol);
        }
    }

    public boolean isValidInterface(String name) {
        return this.validInterfaces.contains(name);
    }

    public boolean isPossibleInterface(String className) {
        return this.possibleInterfaces.containsKey(className);
    }

    public List<ClassSymbol> getImplementations(String className) {
        return this.interfaceImplementations.get(className);
    }

    private void addInterfaceImplementation(String interfaceName, ClassSymbol interfaceClass) {
        if (this.interfaceImplementations.containsKey(interfaceName)) {
            List<ClassSymbol> interfaces = this.interfaceImplementations.get(interfaceName);
            if (!interfaces.contains(interfaceClass)) {
                this.interfaceImplementations.get(interfaceName).add(interfaceClass);
            }
        } else {
            List<ClassSymbol> interfaceClasses = new ArrayList<>();
            interfaceClasses.add(interfaceClass);
            this.interfaceImplementations.put(interfaceName, interfaceClasses);
        }
    }

    private void addPossibleInterface(String interfaceName, ClassSymbol interfaceClass) {
        if (this.possibleInterfaces.containsKey(interfaceName)) {
            return;
        }
        this.possibleInterfaces.put(interfaceName, interfaceClass);
    }

    public boolean isValidInterfaceImplementation(ClassSymbol interfaceClass, ClassSymbol childClass) {
        Set<String> interfaceResourceMethods = getResourceMethods(interfaceClass);
        Set<String> childResourceMethods = getResourceMethods(childClass);
        return childResourceMethods.containsAll(interfaceResourceMethods);
    }

    private Set<String> getResourceMethods(ClassSymbol classSymbol) {
        Set<String> resourceMethods = new HashSet<>();
        for (MethodSymbol methodSymbol : classSymbol.methods().values()) {
            if (isResourceMethod(methodSymbol)) {
                resourceMethods.add(methodSymbol.signature());
            }
        }
        return resourceMethods;
    }

    public void addValidInterface(String className) {
        if (this.validInterfaces.contains(className)) {
            return;
        }
        this.validInterfaces.add(className);
    }
}
