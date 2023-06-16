# Proposal: GraphQL ID scalar type

_Owners_: @ThisaruGuruge @aashikam     
_Reviewers_: @shafreenAnfar @ThisaruGuruge       
_Created_: 2023/03/14    
_Updated_: 2021/06/16     
_Issue_: [#4202](https://github.com/ballerina-platform/ballerina-standard-library/issues/4202)

## Summary

The ID scalar type in GraphQL is often numeric, it should always serialize as a String. This proposal intends to introduce the annotation `@graphql:ID` in order to differentiate the scalar type ID.

## Motivation

The ID scalar type is a unique identifier, often used to re-fetch an object or as the key for a cache. It is important to know for sure that it's a unique identifier which will be useful when you paginate records, modify cache etc. So in practice, it has a very practical implication, it conveys a significant meaning for the programmer that the field is unique for the type.

## Description

The annotation `@graphql:ID` will be introduced to GraphQL package which then can be used to define the scalar type `ID` in GraphQL objects in Ballerina as given below.

### Definition of the annotation 

```ballerina
# Represents the annotation of the ID type.
public annotation ID on record field, parameter, return;
```
The annotation `@graphql:ID` is only allowed for the following ballerina types.
- For the types `int`, `string`, `float`, `decimal`, `uuid:Uuid` (represented as `ID!` in GraphQL schema)
- For the array types `int[]`, `string[]`, `float[]`, `decimal[]`, `uuid:Uuid[]` (represented as `[ID!]!` in GraphQL schema)
- For the nilable types `int?`, `string?`, `float?`, `decimal?`, `uuid:Uuid?` (represented as `ID` in GraphQL schema)
- For the nilable array types `int[]?`, `string[]?`, `float[]?`, `decimal[]?`, `uuid:Uuid[]?` (represented as `[ID!]` in GraphQL schema)
- For the nilable type array types `int?[]`, `string?[]`, `float?[]`, `decimal?[]`, `uuid:Uuid?[]` (represented as `[ID]!` in GraphQL schema)


### Usage of the annotation

```ballerina
listener graphql:Listener basicListener = new (9091); 

service /id_annotations on basicListener  {

    resource function get floatId(@graphql:ID float? floatId) returns string {
        return "Hello, World";
    }

    resource function get decimalId(@graphql:ID decimal? decimalId) returns string {
        return "Hello, World";
    }

    resource function get intIdReturnRecord(@graphql:ID int intId) returns Student {
        return new Student(2, "Jennifer Flackett");
    }

    resource function get uuidArrayReturnRecord(@graphql:ID uuid:Uuid[] uuidId) returns Student {
        return new Student5(563, "Aretha Franklin");
    }

    resource function get stringIdReturnRecord(@graphql:ID string stringId) returns Person {
        return {id: 543, name: "Marmee March", age: 12};
    }

    resource function get stringArrayReturnRecordArray(@graphql:ID string[] stringIds) returns Person[] {
        return [
            {id: 789, name: "Beth Match", age: 15},
            {id: 678, name: "Jo March", age: 16},
            {id: 543, name: "Amy March", age: 12}
        ];
    }

    resource function get floatArrayReturnRecordArray(@graphql:ID float[] floatIds) returns Person[] {
        return [
            {id: 789, name: "Beth Match", age: 15},
            {id: 678, name: "Jo March", age: 16},
            {id: 543, name: "Amy March", age: 12}
        ];
    }
}

public type Person record {|
    @graphql:ID
    int id;
    string name;
    int age;
|};


public distinct service class Student {
    final int id;
    final string name;

    function init(int id, string name) {
        self.id = id;
        self.name = name;
    }

    resource function get id() returns @graphql:ID int {
        return self.id;
    }

    resource function get name() returns string {
        return self.name;
    }
}
```
