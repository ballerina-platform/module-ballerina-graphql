# Proposal: GraphQL File Upload

_Owners_: @ThisaruGuruge @DimuthuMadushan     
_Reviewers_: @shafreenAnfar @ThisaruGuruge       
_Created_: 2021/12/17   
_Updated_: 2021/12/17     
_Issue_: [#1882](https://github.com/ballerina-platform/ballerina-standard-library/issues/1882)

## Summary
Implement the file upload for the Ballerina GraphQL package. The GraphQL file upload can be used to upload the files via GraphQL endpoints.

## Goals
* Provide a way to upload files via GraphQL endpoints.

## Motivation
Although the GraphQL specification doesn’t specify the file uploading, this might be an essential feature for some of the GraphQL use cases. Most of the prominent GraphQL implementations have introduced the file uploading feature and there are several specifications for that as well. This proposal is also referring such a [specification](https://github.com/jaydenseric/graphql-multipart-request-spec) to structure the Multipart Request. With this feature, the GraphQL endpoints are able to accept the Multipart Request coming from the client. GraphQL User will be able to access all the details of the file receiving via Multipart Request.

## Description
As mentioned in the `Goals` section, the purpose of this proposal is to provide a way to upload files to a GraphQL endpoint using the Ballerina GraphQL package. In order to fulfill the requirement, GraphQL mutation query can be used with `HTTP` multipart request. GraphQL endpoints can accept the multipart request which includes file information. This multipart request should be in the form described in the `Multipart Request` section. With this request format, the user will be able to send files into the GraphQL endpoint.

GraphQL module provides `graphql:Upload` type described in `graphql:Upload` section, to represent the file information within the resolvers. Graphql library is able to process the Multipart request receiving to the GraphQL endpoint and extract a `graphql:Upload` type value from the request. The GraphQL multipart request handler resolves the request and populates the value of type `graphql:Upload`. If an error occurred while processing the request, it’ll be returned without further processing. The values populated without any error, pass along with the GraphQL document to continue the execution. The developer will be able to use these `graphql:Upload` type values within the resolvers to extract the file information. Extracted file information can be used to store the file using custom logic.

The high-level architecture of the proposed design is as follows:
![](../../../../../Downloads/Untitled Diagram(7).jpg)

### The `graphql:Upload` Type
The `graphql:Upload` will be defined as a record type in the Ballerina GraphQL module. Following are the fields of the `graphql:Upload` type.

```ballerina
type Upload record {
    string fileName;
    string mimeType;
    string encoding;
    stream<byte[], io:Error?> byteStream;
}
```
| Field    | 	Type                     |	Description|
|----------|---------------------------|-------------|
| fileName | 	string                   |Name of the file|
| mimeType | 	string                   |File Mime type according to the file content|
| encoding | 	string 	                 |File stream encoding|
| byteStream | stream<byte[], io:Error?>  |File content as a stream of byte[]|

### Multipart Request
HTTP Multipart Request for GraphQL file upload consists of the following fields.

* `Operations` - The field includes `JSON-encoded` body of standard GraphQL POST requests where all the variable values related to file upload are `null`.
```curl
“Operations“: { "query": "mutation($file: Upload!) { fileUpload(files: $file) { link }", "variables": {"file": null} }
```

* `Map` - `JSON-encoded` map of paths of the file that occurred in the operation. Map `key` is the `name` of the file in multipart request and the `value` is an array of paths.
```curl
“Map”: { “0”: ["file"] },
```

* `File` - The field includes the file with a unique name.

Sample `curl` request for single file upload:
```curl
curl localhost:9090/graphql \
  -F operations='{ "query": "mutation($file: Upload!) { fileUpload(file: $file) { link } }", "variables": { "file": null } }' \
  -F map='{ "0": ["file"] }' \
  -F 0=@file1.png
```

Sample `curl` request for multiple file upload:
```curl
curl localhost:9090/graphql \
  -F operations='{ "query": "mutation($file: [Upload!]) { filesUpload(file: $file) { link } }", "variables": { "file": [null, null] } }' \
  -F map='{ "0": ["file.0"], "1": ["file.1"]}' \
  -F 0=@file1.png
  -F 1=@file2.png
```

### Using the `graphql:Upload` type in the Resolvers
The `graphql:Upload` can be used as the parameter type of resolver function to handle the file uploading process. Following is an example:

>Note: To implement the logic of the file uploading process, the developer may have to import the Ballerina `io` library into the service.

Single file upload:
```ballerina
remote function fileUpload(graphql:Upload file) returns string|error {
    string fileName fileName = file.fileName;
    stream<byte[], Error?> byteStream = file.byteStream;
    string path = string`./files/${fileName}`;
    check io:fileWriteBlocksFromStream(path, byteStream);
    return "Successfully Uploaded"
}
```
Multiple file upload:
```ballerina
remote function multipleFileUpload(graphql:Upload[] files) returns string[]|error {
    string[] fileInfo = [];
    foreach int i in 0..< files.length() {
        Upload file = files[i];
        stream<byte[], Error?> byteStream = file.byteStream;
        string path = string`./files/${fileName}`;
        check io:fileWriteBlocksFromStream(path, byteStream);
        fileInfo.push(file.fileName);
    }
    return fileInfo;
}
```
