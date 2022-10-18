// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

public isolated class ArgumentNode {
    *NamedNode;

    private string name;
    private Location location;
    private ArgumentValue|ArgumentValue[] value;
    private Location valueLocation;
    private ArgumentType kind;
    private string? variableName;
    private anydata variableValue;
    private boolean variableDefinition;
    private boolean containsInvalidValue;

    public isolated function init(string name, Location location, ArgumentType kind, boolean isVarDef = false) {
        self.name = name;
        self.location = location.clone();
        self.value = ();
        self.valueLocation = location.clone();
        self.kind = kind;
        self.variableDefinition = isVarDef;
        self.variableName = ();
        self.variableValue = ();
        self.containsInvalidValue = false;
    }

    public isolated function accept(Visitor visitor, anydata data = ()) {
        visitor.visitArgument(self, data);
    }

    public isolated function getName() returns string {
        lock {
            return self.name;
        }
    }

    public isolated function getLocation() returns Location {
        lock {
            return self.location.cloneReadOnly();
        }
    }

    public isolated function getKind() returns ArgumentType {
        lock {
            return self.kind;
        }
    }

    public isolated function setKind(ArgumentType kind) {
        lock {
            self.kind = kind;
        }
    }

    public isolated function addVariableName(string name) {
        lock {
            self.variableName = name;
        }
    }

    public isolated function getVariableName() returns string? {
        lock {
            return self.variableName;
        }
    }

    public isolated function setValue(ArgumentValue|ArgumentValue[] value) {
        if value is ArgumentValue {
            lock {
                self.value = value;
            }
            return;
        }

        lock {
            ArgumentValue[] clone = [];
            foreach int i in 0 ..< value.length() {
                clone[i] = <ArgumentValue>value[i];
            }
            self.value = clone;
        }
    }

    public isolated function setValueLocation(Location location) {
        lock {
            self.valueLocation = location.clone();
        }
    }

    public isolated function getValue() returns ArgumentValue|ArgumentValue[] {
        lock {
            if self.value is ArgumentValue {
                return <ArgumentValue>self.value;
            }
        }

        ArgumentValue[] argumentValues = [];
        lock {
            ArgumentValue[] value = <ArgumentValue[]>self.value;
            foreach int i in 0 ..< value.length() {
                argumentValues[i] = <ArgumentValue>value[i];
            }
        }
        return argumentValues;
    }

    public isolated function getValueLocation() returns Location {
        lock {
            return self.valueLocation.cloneReadOnly();
        }
    }

    public isolated function setVariableDefinition(boolean value) {
        lock {
            self.variableDefinition = value;
        }
    }

    public isolated function isVariableDefinition() returns boolean {
        lock {
            return self.variableDefinition;
        }
    }

    public isolated function setVariableValue(anydata inputValue) {
        lock {
            self.variableValue = inputValue.clone();
        }
    }

    public isolated function getVariableValue() returns anydata {
        lock {
            return self.variableValue.clone();
        }
    }

    public isolated function setInvalidVariableValue() {
        lock {
            self.containsInvalidValue = true;
        }
    }

    public isolated function hasInvalidVariableValue() returns boolean {
        lock {
            return self.containsInvalidValue;
        }
    }
}
