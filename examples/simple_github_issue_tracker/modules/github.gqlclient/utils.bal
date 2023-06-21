import ballerina/graphql;

type OperationResponse record {| anydata...; |}|record {| anydata...; |}[]|boolean|string|int|float|();

type DataResponse record {|
   map<json?> __extensions?;
   OperationResponse ...;
|};

isolated function performDataBinding(json graphqlResponse, typedesc<DataResponse> targetType)
                                    returns DataResponse|graphql:RequestError {
    do {
        map<json> responseMap = <map<json>>graphqlResponse;
        json responseData = responseMap.get("data");
        if (responseMap.hasKey("extensions")) {
            responseData = check responseData.mergeJson({"__extensions": responseMap.get("extensions")});
        }
        DataResponse response = check responseData.cloneWithType(targetType);
        return response;
    } on fail var e {
        return error graphql:RequestError("GraphQL Client Error", e);
    }
}
