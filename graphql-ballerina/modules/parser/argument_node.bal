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

public class ArgumentNode {
    *Node;

    private ArgumentName name;
    private ArgumentValue value;
    private ArgumentType kind;

    public isolated function init(ArgumentName name, ArgumentValue value, ArgumentType kind) {
        self.name = name;
        self.value = value;
        self.kind = kind;
    }

    public isolated function getName() returns ArgumentName {
        return self.name;
    }

    public isolated function getValue() returns ArgumentValue {
        return self.value;
    }

    public isolated function getKind() returns ArgumentType {
        return self.kind;
    }

    public isolated function accept(Visitor v) {
        var result = v.visitArgument(self);
    }
}
