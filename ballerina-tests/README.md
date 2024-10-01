## Writing Tests

The tests for the Ballerina GraphQL module are organized into multiple test suites. When adding a new test, ensure that it is added to the appropriate test suite. Below are the current test suites:

- **graphql-advanced-test-suite**: Covers test cases for GraphQL context, caching, file uploads, and query complexity.
- **graphql-client-test-suite**: Covers test cases for the Ballerina GraphQL client.
- **graphql-dataloader-test-suite**: Covers test cases related to the DataLoader implementation.
- **graphql-interceptor-test-suite**: Covers test cases for interceptors.
- **graphql-security-test-suite**: Covers test cases for security.
- **graphql-subgraph-test-suite**: Covers federation and subgraph-related implementation.
- **graphql-subscription-test-suite**: Covers subscription-related functionality.
- **graphql-service-test-suite**: Covers the remaining overall GraphQL specification.

### Test Structure

### Test Structure

- **Listeners**: Test listeners are defined in the `<suite>/tests/listeners.bal` file.
- **Services**: Test services are defined in the `<suite>/tests/services.bal` file.
- **Records, Object Types, and Values**: Ballerina records, object types, and values are defined in the corresponding Ballerina files:
  - `<suite>/tests/records.bal`
  - `<suite>/tests/object_types.bal`
  - `<suite>/tests/values.bal`

### Handling Large Documents and JSON Files

For lengthy GraphQL documents, save them as separate `.txt` files in the `<suite>/tests/resources/documents` directory. Use the `common:getGraphqlDocumentFromFile()` utility function to read these files, passing the file name as an argument.

Similarly, when expected JSON results are too large, save them as separate `.json` files in the `<suite>/tests/resources/expected_results.json` directory. Use the `common:getJsonContentFromFile()` function to read these files, passing the appropriate file name.

### Naming Convention

Name the document and JSON files after the corresponding test functions. For example:

- A document used in the `testSampleFunctionality` test is saved as `sample_functionality.txt`.
- The expected result is saved as `sample_functionality.json`.

### graphql-test-common

The `graphql-test-common` module provides utility methods shared across all test suites. Most test suites include this module as a dependency from the local repository.
