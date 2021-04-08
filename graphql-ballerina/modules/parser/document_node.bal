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

public class DocumentNode {
    // TODO: Make this a map
    private OperationNode[] operations;
    private map<FragmentNode> fragments;
    private ErrorDetail[] errors;

    public isolated function init() {
        self.operations = [];
        self.fragments = {};
        self.errors = [];
    }

    public isolated function addOperation(OperationNode operation) {
        // TODO: Validate operation name for duplicates
        self.operations.push(operation);
    }

    public isolated function addFragment(FragmentNode fragment) returns SyntaxError? {
        if (self.fragments.hasKey(fragment.getName())) {
            FragmentNode originalFragment = <FragmentNode>self.fragments[fragment.getName()];
            string message = string`There can be only one fragment named "${fragment.getName()}".`;
            Location l1 = originalFragment.getLocation();
            Location l2 = fragment.getLocation();
            self.errors.push({message: message, locations: [l1, l2]});
        }
        self.fragments[fragment.getName()] = fragment;
    }

    public isolated function accept(Visitor v) {
        var result = v.visitDocument(self);
    }

    public isolated function getOperations() returns OperationNode[] {
        return self.operations;
    }

    public isolated function getErrors() returns ErrorDetail[] {
        return self.errors;
    }

    public isolated function getFragments() returns map<FragmentNode> {
        return self.fragments;
    }

    public isolated function getFragment(string name) returns FragmentNode? {
        return self.fragments[name];
    }
}
