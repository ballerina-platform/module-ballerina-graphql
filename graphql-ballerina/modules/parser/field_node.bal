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

public class FieldNode {
    *Node;
    *ParentNode;

    private string name;
    private Location location;
    private ArgumentNode[] arguments;
    private FieldNode[] fields;
    private string[] fragments;
    private Selection[] selections;

    public isolated function init(string name, Location location) {
        self.name = name;
        self.location = location;
        self.fields = [];
        self.arguments = [];
        self.fragments = [];
        self.selections = [];
    }

    public isolated function getName() returns string {
        return self.name;
    }

    public isolated function getLocation() returns Location {
        return self.location;
    }

    public isolated function accept(Visitor v) {
        anydata|error result = v.visitField(self);
    }

    public isolated function addArgument(ArgumentNode argument) {
        self.arguments.push(argument);
    }

    public isolated function addField(FieldNode fieldNode) {
        self.fields.push(fieldNode);
    }

    public isolated function getArguments() returns ArgumentNode[] {
        return self.arguments;
    }

    public isolated function getFields() returns FieldNode[] {
        return self.fields;
    }

    public isolated function addFragment(string name) {
        self.fragments.push(name);
    }

    public isolated function getFragments() returns string[] {
        return self.fragments;
    }

    public isolated function addSelection(Selection selection) {
        self.selections.push(selection);
    }

    public isolated function getSelections() returns Selection[] {
        return self.selections;
    }
}
