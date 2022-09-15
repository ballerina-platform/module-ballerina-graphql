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

import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.graphql.compiler.Utils.getObjectTypeSymbol;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceClass;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceObjectDefinition;
import static io.ballerina.stdlib.graphql.compiler.Utils.isServiceObjectReference;

/**
 * Finds and validates possible GraphQL interfaces in a Ballerina service.
 */
public class InterfaceFinder {
    private final Map<String, List<Symbol>> interfaceImplementations;
    private final Map<String, TypeReferenceTypeSymbol> possibleInterfaces;

    public InterfaceFinder() {
        this.interfaceImplementations = new HashMap<>();
        this.possibleInterfaces = new HashMap<>();
    }

    public void populateInterfaces(SyntaxNodeAnalysisContext context) {
        for (Symbol symbol : context.semanticModel().moduleSymbols()) {
            if (!isServiceClass(symbol) && !isServiceObjectDefinition(symbol)) {
                continue;
            }
            if (symbol.getName().isEmpty()) {
                continue;
            }
            findPossibleInterfaces(symbol);
        }
    }

    private void findPossibleInterfaces(Symbol serviceObjectTypeDefinitionOrServiceClass) {
        ObjectTypeSymbol objectTypeSymbol = getObjectTypeSymbol(serviceObjectTypeDefinitionOrServiceClass);
        for (TypeSymbol typeSymbol : objectTypeSymbol.typeInclusions()) {
            if (!isServiceObjectReference(typeSymbol)) {
                continue;
            }
            if (typeSymbol.getName().isEmpty()) {
                continue;
            }
            String interfaceName = typeSymbol.getName().get();
            addPossibleInterface(interfaceName, (TypeReferenceTypeSymbol) typeSymbol);
            addInterfaceImplementation(interfaceName, serviceObjectTypeDefinitionOrServiceClass);
        }
    }

    public boolean isPossibleInterface(String name) {
        return this.possibleInterfaces.containsKey(name);
    }

    public List<Symbol> getImplementations(String interfaceName) {
        return this.interfaceImplementations.get(interfaceName);
    }

    private void addInterfaceImplementation(String interfaceName, Symbol implementation) {
        if (this.interfaceImplementations.containsKey(interfaceName)) {
            List<Symbol> interfaces = this.interfaceImplementations.get(interfaceName);
            if (!interfaces.contains(implementation)) {
                this.interfaceImplementations.get(interfaceName).add(implementation);
            }
        } else {
            List<Symbol> interfaceClasses = new ArrayList<>();
            interfaceClasses.add(implementation);
            this.interfaceImplementations.put(interfaceName, interfaceClasses);
        }
    }

    private void addPossibleInterface(String interfaceName, TypeReferenceTypeSymbol objectTypeReference) {
        if (this.possibleInterfaces.containsKey(interfaceName)) {
            return;
        }
        this.possibleInterfaces.put(interfaceName, objectTypeReference);
    }
}
