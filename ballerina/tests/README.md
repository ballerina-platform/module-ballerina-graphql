## Writing Tests

All the listeners are defined in the `test_listeners.bal` file.
All the services are defined in the `test_services.bal` file.
When the GraphQL document is too long, it is saved as a separate file inside the `tests/resources/documents` directory ad a `txt` file. 
All the text files can be read using the `getGraphQLDocumentFromFile()` utility function. We have to pass the file name to that function.

Similarly, when the expected JSON file is too long, they are stored as separate JSON files under the `tests/resources/expected_results.json` directory.
Those files can be read using the `getJsonContentFromFile` utility function by passing the name of the JSON file.

The JSON files and document files are named as same as the test functions, inside which those files used.
For example, the document used in the `testSampleFunctionality` test is saved as `sample_functionality.txt` file, and the expected result is saved as `sample_functionality.json`.
