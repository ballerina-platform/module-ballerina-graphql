# Change Log
This file contains all the notable changes done to the Ballerina GraphQL package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- [[#1447] Fix Returning Empty Values when Fragments Inside Fragments Querying Service Object](https://github.com/ballerina-platform/ballerina-standard-library/issues/1447)
- [[#1429] Fix Compiler Plugin Crashes when a Service has a Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/1429)
- [[#1277] Fix Fields Missing when a Query Having Duplicate Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/1277)

## [0.2.0-beta.1] - 2021-06-02

### Added
- [[#1307] Returning Union of Service Types from a Resource](https://github.com/ballerina-platform/ballerina-standard-library/issues/1307)
- [[#1244] Add Inline Fragment Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1244)
- [[#1336] Implement declarative auth design for GraphQL module](https://github.com/ballerina-platform/ballerina-standard-library/issues/1336)
- [[#1265] Support Optional Type Input Arguments](https://github.com/ballerina-platform/ballerina-standard-library/issues/1265)
- [[#1270] Add Compile Time Validation for Resource Function Names](https://github.com/ballerina-platform/ballerina-standard-library/issues/1270)

### Changed
- [[#1329] Improve Introspection Validation and Execution](https://github.com/ballerina-platform/ballerina-standard-library/issues/1329)
- [[#1330] Added Missing Fields of GraphQL Schema-Related Record Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1330)
- [[#1339] Improve Input Parameter Validation Logic in Compiler Plugin](https://github.com/ballerina-platform/ballerina-standard-library/issues/1339)
- [[#1344] Improve Return Type Validation Logic in Compiler Plugin](https://github.com/ballerina-platform/ballerina-standard-library/issues/1344)
- [[#1348] Add Validation to Return Type Service Class Definitions in Compiler Plugin](https://github.com/ballerina-platform/ballerina-standard-library/issues/1348)
- [[#998] Use Included Record Parameters for Listener Config](https://github.com/ballerina-platform/ballerina-standard-library/issues/998)
- [[#1350] Allow Optional Enums to be Resource Function Input Parameters](https://github.com/ballerina-platform/ballerina-standard-library/issues/1350)
- [[#1382] Decouple the Engine and the Listener](https://github.com/ballerina-platform/ballerina-standard-library/issues/1382)
- [[#1386] Make HttpService an Isolated Object](https://github.com/ballerina-platform/ballerina-standard-library/issues/1386)
- [[#1398] Rename the ServiceConfiguration Record to ServiceConfig](https://github.com/ballerina-platform/ballerina-standard-library/issues/1398)

### Fixed
- [[#1305] Allow Enum as an Input Parameter](https://github.com/ballerina-platform/ballerina-standard-library/issues/1305)
- [[#1250] Fix Hanging the Service when Returning Array](https://github.com/ballerina-platform/ballerina-standard-library/issues/1250)
- [[#1274] Fix Recursive Type Reference Causing Stack Overflow](https://github.com/ballerina-platform/ballerina-standard-library/issues/1274)
- [[#1252] Fix Incorrect Behaviour in Validation EnumValues Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/1251)
- [[#1269] Fix Validating Incorrect Arguments as Valid](https://github.com/ballerina-platform/ballerina-standard-library/issues/1269)
- [[#1268] Fix Incorrect Validation for Fields in Service Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1268)
- [[#1266] Fix Incorrect Validation for Input Parameters with Default Value](https://github.com/ballerina-platform/ballerina-standard-library/issues/1266)
- [[#1321] Fix Invalid Wrapping of List Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1321)
- [[#1332] Add Missing Arguments for Introspection Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/1332)
- [[#1331] Fix Showing Incorrect Location in Fragment Error Response](https://github.com/ballerina-platform/ballerina-standard-library/issues/1331)
- [[#1347] Fix Incorrect Behavior when Input Value is an Enum](https://github.com/ballerina-platform/ballerina-standard-library/issues/1347)
- [[#1312] Fix Query Depth Ignoring the Depth of Fragments in GraphQL Documents](https://github.com/ballerina-platform/ballerina-standard-library/issues/1312)
- [[#1368] Fix Crashing the Schema Generation when a Union Type not Having a Name](https://github.com/ballerina-platform/ballerina-standard-library/issues/1368)
- [[#1370] Fix Service Hanging When Returning an Enum Array](https://github.com/ballerina-platform/ballerina-standard-library/issues/1370)
- [[#1391] Fix Union of Service Types Returning all the Members](https://github.com/ballerina-platform/ballerina-standard-library/issues/1391)
- [[#1378] Fix Hierarchical Paths With Same Leaf Fields Returning Incorrect Values](https://github.com/ballerina-platform/ballerina-standard-library/issues/1378)
- [[#1407] Fix Returning Incorrect Type Names for Intersection Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1407)
- [[#1410] Fix Inline Fragments Returning Non-requested Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/1410)
- [[#1413] Fix Incorrectly validating Duplicate Operations](https://github.com/ballerina-platform/ballerina-standard-library/issues/1413)

## [0.2.0-alpha8] - 2021-04-23

### Added
- [[#1224] Fragment Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1224)
- [[#1000] Enum Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1000)
- [[#999] Map Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/999)
- [[#1091] Compiler plugin validations for GraphQL services](https://github.com/ballerina-platform/ballerina-standard-library/issues/1091)
- [[#1001] Support Union Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1001)

## [0.2.0-alpha7] - 2021-04-06

## [0.2.0-alpha6] - 2021-04-02

### Added
- [[#1191] Support Ballerina Decimal Type](https://github.com/ballerina-platform/ballerina-standard-library/issues/1191)

### Fixed
- [[#1190] Make GraphQL Resource Execution Non-Blocking](https://github.com/ballerina-platform/ballerina-standard-library/issues/1190)

## [0.2.0-alpha5] - 2021-03-19

### Added
- [[#779] Hierarchical Resource Path Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/779)

### Changed
- [[#990] Revisit the Error Types in GraphQL Module](https://github.com/ballerina-platform/ballerina-standard-library/issues/990)

### Fixed
- [[#912] Support Optional Types in Resource Functions](https://github.com/ballerina-platform/ballerina-standard-library/issues/912)
- [[#743] Improve Type Name Display in Error Messages](https://github.com/ballerina-platform/ballerina-standard-library/issues/743)


## [0.2.0-alpha4] - 2021-02-20

### Added
- [[#934] Configure Listener using HTTP Listener Configurations](https://github.com/ballerina-platform/ballerina-standard-library/issues/934)
- [[#938] Add MaxQueryDepth Configuration to the GraphQL Service](https://github.com/ballerina-platform/ballerina-standard-library/issues/938)

### Changed
- [[#763] Update the Functionality of Resource Functions Returning Service Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/763)
