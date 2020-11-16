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
    *AbstractNode;
    *ParentType;

    public string name;
    public Location location;
    private ArgumentNode[] arguments;
    private FieldNode[] selections;

    public isolated function init(string name, Location location) {
        self.name = name;
        self.location = location;
        self.selections = [];
        self.arguments = [];
    }

    public isolated function accept(Visitor v) {
        var result = v.visitField(self);
    }

    public isolated function addArgument(ArgumentNode argument) {
        self.arguments.push(argument);
    }

    public isolated function addSelection(FieldNode selection) {
        self.selections.push(selection);
    }

    public isolated function getArguments() returns ArgumentNode[] {
        return self.arguments;
    }

    public isolated function getSelections() returns FieldNode[] {
        return self.selections;
    }
}
