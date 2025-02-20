# Change Log
This file contains all the notable changes done to the Ballerina GraphQL package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- [[#7555] Fix Compiler Crash when Listener Init Parameters are Passed as Named Parameters](https://github.com/ballerina-platform/ballerina-library/issues/7555)

## [1.15.0] - 2025-02-08

### Added
- [[#4122] Introduce Parallel Execution for GraphQL Resolvers](https://github.com/ballerina-platform/ballerina-library/issues/4122)

### Fixed
- [[#7317] Fix Service Crashing when Input Object Type Variable Value Includes an Additional Field](https://github.com/ballerina-platform/ballerina-library/issues/7317)
- [[#7502] Fix not Allowing to Pass `ListenerConfigurations` using Configurable Variables](https://github.com/ballerina-platform/ballerina-library/issues/7502)

## [1.14.0] - 2024-08-20

### Added

- [[#6722] Add Support for Query Complexity Analysis](https://github.com/ballerina-platform/ballerina-library/issues/6722)

## [1.13.1] - 2024-07-02

### Changed
- [[#6652] Cache Entire Record Having All Non-Optional Fields Instead of Caching Each Field Separately](https://github.com/ballerina-platform/ballerina-library/issues/6652)

## [1.13.0] - 2024-05-06

### Added
- [[#6461] Add Support for Publishing Observability Metrics for GraphQL Services](https://github.com/ballerina-platform/ballerina-library/issues/6461)

## [1.12.0] - 2024-05-03

### Fixed
- [[#4848] Fix Resolvers not Able to Return Error Reference Types](https://github.com/ballerina-platform/ballerina-library/issues/4848)
- [[#4859] Fix Service Crashing when Intersection Types are Used as Input Objects](https://github.com/ballerina-platform/ballerina-library/issues/4859)
- [[#6418] Fix Code Coverage Showing Invalid Entries with GraphQL](https://github.com/ballerina-platform/ballerina-library/issues/6418)
- [[#6310] Fix Incorrect Error Message in Compiler Plugin](https://github.com/ballerina-platform/ballerina-library/issues/6310)
- [[#6459] Fix Incorrect Compilation Error when Port is Passed via a Variable with SSL Settings](https://github.com/ballerina-platform/ballerina-library/issues/6459)

## [1.11.0] - 2024-02-21

### Added
- [[#1586] Add Compile Time Schema Generation for Default Parameters](https://github.com/ballerina-platform/module-ballerina-graphql/pull/1586)
- [[#3317] Add Support to Generate GraphQL Schema for Local Service Variable Declaration](https://github.com/ballerina-platform/ballerina-library/issues/3317)
- [[#3621] Add Support to GraphQL Server Side Caching](https://github.com/ballerina-platform/ballerina-library/issues/3621)

### Changed
- [[#4634] Use Aliases in GraphQL Error Path](https://github.com/ballerina-platform/ballerina-standard-library/issues/4634)
- [[#4911] Make some of the Java classes proper utility classes](https://github.com/ballerina-platform/ballerina-standard-library/issues/4911)

## [1.10.0] - 2023-09-18

### Added
- [[#2998] Add `@deprecated` Directive Support for Output Object Defined using Record Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/2998)
- [[#4586] Add Support for Printing GraphiQL Url to Stdout](https://github.com/ballerina-platform/ballerina-standard-library/issues/4586)
- [[#4569] Introduce DataLoader for Ballerina GraphQL](https://github.com/ballerina-platform/ballerina-standard-library/issues/4569)
- [[#4337] Add Support for Generating Subgraph SDL Schema at Compile Time](https://github.com/ballerina-platform/ballerina-standard-library/issues/4337)

### Fixed
- [[#4627] Fix Schema Generation Failure when Service has Type Alias](https://github.com/ballerina-platform/ballerina-standard-library/issues/4627)
- [[#4650] Fix Incorrect Schema Generation when an Annotation Present in a Record Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/4650)
- [[#4660] Fix GraphiQL Client Endpoint for Secured Listeners](https://github.com/ballerina-platform/ballerina-standard-library/issues/4660)
- [[#4681] Removed Adding All Possible Federated Directives to SDL String in GraphQL Subgraph](https://github.com/ballerina-platform/ballerina-standard-library/issues/4681)
- [[#4685] Fix `ID` Scalar Type Treated as a Non Built-in Type](https://github.com/ballerina-platform/ballerina-standard-library/issues/4685)
- [[#4724] Fix Allowing Empty Records as GraphQL Object Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/4724)
- [[#4799] Fix Not Allowing `map<any>` as Return Type in ReferenceResolver](https://github.com/ballerina-platform/ballerina-standard-library/issues/4799)

### Changed
- [[#4630] Deprecate executeWithType() method from graphql:Client](https://github.com/ballerina-platform/ballerina-standard-library/issues/4630)
- [[#4648] Removed Returning Deprecation Reasons for Non-Deprecated Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/4648)
- [[#4801] Make `_service` and `_entities` Resources Isolated](https://github.com/ballerina-platform/ballerina-standard-library/issues/4801)

## [1.9.0] - 2023-06-30

### Added
- [[#4176] Add Support for Input Constraint Validation](https://github.com/ballerina-platform/ballerina-standard-library/issues/4176)
- [[#4479] Introduce `graphql:__addError()` Function to Add an ErrorDetail into the `errors` Field of a GraphQL Response](https://github.com/ballerina-platform/ballerina-standard-library/issues/4479)
- [[#4202] Add Support for GraphQL Scalar Type ID](https://github.com/ballerina-platform/ballerina-standard-library/issues/4202)

### Fixed
- [[#4489] Fix Removing Duplicate Fields with Different Arguments without Returning an Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/4489)
- [[#4566] Fix Compiler Plugin Failure when Returning an Invalid Intersection Type](https://github.com/ballerina-platform/ballerina-standard-library/issues/4566)

## [1.8.0] - 2023-06-01

### Added
- [[#3234] Add Support for Field Interceptors](https://github.com/ballerina-platform/ballerina-standard-library/issues/3234)
- [[#4254] Introduce GraphQL Interceptor Configuration](https://github.com/ballerina-platform/ballerina-standard-library/issues/4254)
- [[#4376] Introduce an API to get Subfields of a `graphql:Field` Object](https://github.com/ballerina-platform/ballerina-standard-library/issues/4376)

### Fixed
- [[#4364] Fix Compilation Error when GraphQL Package Import has a Prefix](https://github.com/ballerina-platform/ballerina-standard-library/issues/4364)
- [[#4379] Fix Schema Generation Failure when Import is Missing](https://github.com/ballerina-platform/ballerina-standard-library/issues/4379)
- [[#4447] Fix non-isolated Function Pointers in Function Calls Within Isolated Functions](https://github.com/ballerina-platform/ballerina-standard-library/issues/4447)
- [[#4255] Fix Interceptors Returning Invalid Response for Maps](https://github.com/ballerina-platform/ballerina-standard-library/issues/4255)
- [[#4490] Fix Interceptors Returning Invalid Responses when Alias Present](https://github.com/ballerina-platform/ballerina-standard-library/issues/4490)

## [1.7.0] - 2023-04-10

### Added
- [[#4120] Add support to GraphQL design view by updating the schema](https://github.com/ballerina-platform/ballerina-standard-library/issues/4120)
- [[#3504] Add Support for Federation Subgraph](https://github.com/ballerina-platform/ballerina-standard-library/issues/3504)
- [[#4122] Add Parallel Execution for GraphQL Resolvers](https://github.com/ballerina-platform/ballerina-standard-library/issues/4122)

### Fixed
- [[#4172] Fix Compilation Failure when Type Alias is Used with Primitive Type](https://github.com/ballerina-platform/ballerina-standard-library/issues/4172)
- [[#4208] Fix Subscription Payload Returned with Invalid GraphQL Error Format](https://github.com/ballerina-platform/ballerina-standard-library/issues/4208)
- [[#4286] Fix Invalid Path Returning for Errors in Record Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/4286)

### Changed
- [[#3885] Allow Adding a Single Service Level Interceptor](https://github.com/ballerina-platform/ballerina-standard-library/issues/3885)
- [[#4206] Skip Additional Validation for Unused Operations in the Document](https://github.com/ballerina-platform/ballerina-standard-library/issues/4206)
- [[#4237] Exit the Listener When Panic Occurred](https://github.com/ballerina-platform/ballerina-standard-library/issues/4237)

## [1.6.0] - 2023-02-20

### Added
- [[#3569] Support Multiplexing with graphql-ws Subprotocol](https://github.com/ballerina-platform/ballerina-standard-library/issues/3569)
- [[#3942] Add Functionality to Send Ping Messages Periodically](https://github.com/ballerina-platform/ballerina-standard-library/issues/3942)
- [[#3943] Add Functionality to Check for Pong Messages Periodically](https://github.com/ballerina-platform/ballerina-standard-library/issues/3943)
- [[#3893] Add Support to Access GraphQL Field Information from Resolvers](https://github.com/ballerina-platform/ballerina-standard-library/issues/3893)

### Fixed
- [[#3865] Fix Incomplete Type Info Given in Compiler Errors Issued from GraphQL Compiler Plugin](https://github.com/ballerina-platform/ballerina-standard-library/issues/3865)
- [[#3721] Fix Passing Incorrect Values when a Resolver Method has an Enum as Input Parameter](https://github.com/ballerina-platform/ballerina-standard-library/issues/3721)
- [[#4038] Fix `__typename` Introspection not Working on Introspection Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/4038)
- [[#3337] Fix Allowing the use of non-distinct Service Objects as GraphQL Interfaces](https://github.com/ballerina-platform/ballerina-standard-library/issues/3337)

### Changed
- [[#3430] Parallelise GraphQL Document Validation](https://github.com/ballerina-platform/ballerina-standard-library/issues/3430)
- [[#3870] Add Service Error Handling Section to the Spec](https://github.com/ballerina-platform/ballerina-standard-library/issues/3870)
- [[#3709] Add Input Default Values Section to the Spec](https://github.com/ballerina-platform/ballerina-standard-library/issues/3709)
- [[#3941] Remove Support for Non-Compliant Subscription Requests](https://github.com/ballerina-platform/ballerina-standard-library/issues/3941)
- [[#3977] Remove Limitation on GraphQL Context Object Parameter Order](https://github.com/ballerina-platform/ballerina-standard-library/issues/3977)

## [1.5.0] - 2022-11-29

### Added
- [[#2891] Add Support for Disabling Introspection Queries](https://github.com/ballerina-platform/ballerina-standard-library/issues/2891)
- [[#3289] Support GraphQL interface with ballerina distinct object type](https://github.com/ballerina-platform/ballerina-standard-library/issues/3289)
- [[#3230] Add Service Interceptor Execution for Record Fields, Maps & Tables](https://github.com/ballerina-platform/ballerina-standard-library/issues/3230)
- [[#2913] Support Interfaces Implementing Interfaces](https://github.com/ballerina-platform/ballerina-standard-library/issues/2913)
- [[#3233] Add Service Level Interceptor Support for GraphQL Subscriptions](https://github.com/ballerina-platform/ballerina-standard-library/issues/3233)

### Fixed
- [[#3294] Fix GraphQL Dynamic Listener Is Not Working for Module Level Service Declaration](https://github.com/ballerina-platform/ballerina-standard-library/issues/3294)
- [[#3375] Fix Multiple Subscription Endpoints with the Same GraphQL Listener is Not Working](https://github.com/ballerina-platform/ballerina-standard-library/issues/3375)
- [[#3355] Fix Not Identifying Error Type as an Invalid Input Type](https://github.com/ballerina-platform/ballerina-standard-library/issues/3355)
- [[#3545] Fix Subscription Operations Allowed Before Server Has Acknowledged the Connection](https://github.com/ballerina-platform/ballerina-standard-library/issues/3545)
- [[#3556] Fix Returning Table from a Resolver Resulting in Runtime Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/3556)
- [[#3565] Fix Service Incorrectly Closing Connection when a Stream Returns an Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/3565)
- [[#3548] Fix Socket Connection Gets Closed when the Operation is Complete or If there is an Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/3548)
- [[#3466] Fix Resolver Returning Null when a Record has a Service Object as its Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/3466)
- [[#3579] Resolver Produces Null when Resolver Returns a Record Containing a Map of Service Objects as its Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/3579)
- [[#3062] Fix Allow to Attach a Service with Subscription to a HTTP2 Based Listener](https://github.com/ballerina-platform/ballerina-standard-library/issues/3601)
- [[#3628] Fix Compilation Failure when Other Annotations are Present](https://github.com/ballerina-platform/ballerina-standard-library/issues/3628)
- [[#3646] Fix Returning Incorrect Validation Errors for Input Object Fields with Default Values](https://github.com/ballerina-platform/ballerina-standard-library/issues/3646)
- [[#3661] Fix Stream not Closing After the Completion of the Subscription Operation](https://github.com/ballerina-platform/ballerina-standard-library/issues/3661)

### Changed
- [[#3062] Improve Compilation Error Messages To Be More Specific](https://github.com/ballerina-platform/ballerina-standard-library/issues/3062)
- [[#2848] All the Errors Are Reported for a Given Document in a Single Response](https://github.com/ballerina-platform/ballerina-standard-library/issues/2848)
- [[#3431] Introduce GraphQL Client Configuration](https://github.com/ballerina-platform/ballerina-standard-library/issues/3431)
- [[#3463] Updated API Docs to Reflect Slack to Discord Migration](https://github.com/ballerina-platform/ballerina-standard-library/issues/3463)
- [[#3791] Add Cause to GraphQL Payload Binding Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/3791)

## [1.4.1] - 2022-09-12

### Fixed
- [[#2897] Revert `Fix Invalid introspection response for fields with default value`](https://github.com/ballerina-platform/ballerina-standard-library/issues/3307)

## [1.4.0] - 2022-09-08

### Added
- [[#2898] Support Deprecation Support in GraphQL Services](https://github.com/ballerina-platform/ballerina-standard-library/issues/2898)
- [[#2001] Support GraphQL Interceptors for Query and Mutation operations](https://github.com/ballerina-platform/ballerina-standard-library/issues/2001)
- [[#3260] Log the Errors Returned from the Resolvers](https://github.com/ballerina-platform/ballerina-standard-library/issues/3260)

### Fixed
- [[#3069] Fix Enums with String Values Return String Value for Enum Name](https://github.com/ballerina-platform/ballerina-standard-library/issues/3069)
- [[#3067] Fix Single Quote Character Included in Field and Argument Names](https://github.com/ballerina-platform/ballerina-standard-library/issues/3067)
- [[#3068] Fix Anonymous Records Crashing the Service](https://github.com/ballerina-platform/ballerina-standard-library/issues/3068)
- [[#3115] Fix Not Initializing Context per Request in GraphQL Subscriptions](https://github.com/ballerina-platform/ballerina-standard-library/issues/3115)
- [[#3227] Fix Service Crashing when Map Field Does not Contain the Provided Key](https://github.com/ballerina-platform/ballerina-standard-library/issues/3227)
- [[#2897] Fix GraphiQL Schema not Generating for Default Values](https://github.com/ballerina-platform/ballerina-standard-library/issues/2897)
- [[#2897] Fix Invalid introspection response for fields with default value](https://github.com/ballerina-platform/ballerina-standard-library/issues/3307)

### Changed
- [[#3173] Improve the Error Message for Using Anonymous Records as Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/3173)
- [[#3288] Rename the GraphiQL config `enable` to `enabled`](https://github.com/ballerina-platform/ballerina-standard-library/issues/3288)

## [1.3.2] - 2022-07-11

### Fixed
- [[#3076] Fix Empty Input Arrays not Considering as Valid Inputs](https://github.com/ballerina-platform/ballerina-standard-library/issues/3076)

## [1.3.1] - 2022-05-31

### Fixed
- [[#2959] Fix Incorrectly Removing Other Services Through Code Modifier](https://github.com/ballerina-platform/ballerina-standard-library/issues/2959)

## [1.3.0] - 2022-05-30

### Added
- [[#1936] Integrate GraphiQL Client into GraphQL Package](https://github.com/ballerina-platform/ballerina-standard-library/issues/1936)
- [[#2532] Introduce GraphQL Subscription Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/2532)
- [[#2698] Support GraphQL Documentation](https://github.com/ballerina-platform/ballerina-standard-library/issues/2698)

### Changed
- [[#2838] Remove Spec Deviations in GraphQL File Upload](https://github.com/ballerina-platform/ballerina-standard-library/issues/2838)

### Fixed
- [[#2800] Fix Allowing Field Names Starting with `__` in Mutations](https://github.com/ballerina-platform/ballerina-standard-library/issues/2800)

## [1.2.1] - 2022-03-08

### Added
- [[#2620] Allow Intersection Types as Inputs](https://github.com/ballerina-platform/ballerina-standard-library/issues/2620)

### Fixed
- [[#2640] Fix inter-dependent fragments returning stack overflow error](https://github.com/ballerina-platform/ballerina-standard-library/issues/2640)
- [[#2649] Fix incorrectly invalidating `decimal` type inputs](https://github.com/ballerina-platform/ballerina-standard-library/issues/2649)
- [[#2656] Fix compiler plugin crash when recursive record type definitions present](https://github.com/ballerina-platform/ballerina-standard-library/issues/2656)
- [[#2696] Fix not Allowing to Pass `null` as Variable Input Value](https://github.com/ballerina-platform/ballerina-standard-library/issues/2696)
- [[#2733] Fix incorrectly validating listener init parameters when `check` expression is present](https://github.com/ballerina-platform/ballerina-standard-library/issues/2733)
- [[#2746] Fix incorrectly allowing record types as union type members](https://github.com/ballerina-platform/ballerina-standard-library/issues/2746)

## [1.2.0] - 2022-02-01

### Added
- [[#1475] Add CORS configure support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1475)

### Changed
- [[#2529] Remove the `context.add()` method](https://github.com/ballerina-platform/ballerina-standard-library/issues/2529)

### Fixed
- [[#2076] Refactor GraphQL error messages](https://github.com/ballerina-platform/ballerina-standard-library/issues/2076)
- [[#2500] Fix returning NPE when multiple file uploading](https://github.com/ballerina-platform/ballerina-standard-library/issues/2500)
- [[#2518] Fix Intermittently Skipping Fields when Executing Resources](https://github.com/ballerina-platform/ballerina-standard-library/issues/2518)
- [[#2552] Fix returning error when querying a union type includes a field returns an object](https://github.com/ballerina-platform/ballerina-standard-library/issues/2552)
- [[#2571] Fix Service Crashing when Fields Return Nullable, Union Type Arrays](https://github.com/ballerina-platform/ballerina-standard-library/issues/2571)
- [[#2578] Fix Incorrect Response Returning for GraphQL Scalar Type Arrays](https://github.com/ballerina-platform/ballerina-standard-library/issues/2578)
- [[#2598] Fix Resolving Union Type Names Incorrectly when the Field is Nullable](https://github.com/ballerina-platform/ballerina-standard-library/issues/2598)

## [1.1.0] - 2021-12-14

### Added
- [[#1837] Add Input Value List Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1837)
- [[#1882] Add File Uploading Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1882)

### Changed
- [[#2476] Deprecating the `context.add` function and introducing the `context.set` function](https://github.com/ballerina-platform/ballerina-standard-library/issues/2476)

### Fixed
- [[#2437] Pass `http:RequestContext` object to the `graphql:Context` Init Function](https://github.com/ballerina-platform/ballerina-standard-library/issues/2437)
- [[#2465] Disallow path parameters in GraphQL resource functions](https://github.com/ballerina-platform/ballerina-standard-library/issues/2465)
- [[#2480] Fix Input Object type variables return type cast error](https://github.com/ballerina-platform/ballerina-standard-library/issues/2480)
- [[#2481] Fix ignoring type validation of variables in a list](https://github.com/ballerina-platform/ballerina-standard-library/issues/2481)
- [[#2488] Validate the Record Filed Types when the Input Type is a Record](https://github.com/ballerina-platform/ballerina-standard-library/issues/2488)

## [1.0.1] - 2021-11-19

### Added
- [[#741] Add Default Directives 'skip' & 'include' Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/741)
- [[#2026] Implement auth error types](https://github.com/ballerina-platform/ballerina-standard-library/issues/2026)

### Changed
- [[#2398] Mark GraphQL Service type as distinct](https://github.com/ballerina-platform/ballerina-standard-library/issues/2398)

### Fixed
- [[#1988] Fix Fields Missing from the Response when an Error Occurred](https://github.com/ballerina-platform/ballerina-standard-library/issues/1988)
- [[#2041] Fix Invalid Type Inferring for List Element Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/2041)
- [[#2042] Fix NON_NULL Fields Returning null Value](https://github.com/ballerina-platform/ballerina-standard-library/issues/2042)
- [[#2018] Fix Ignoring Parser Invalidation of Variable Usages in Variable Definitions](https://github.com/ballerina-platform/ballerina-standard-library/issues/2018)
- [[#2356] Fix Service Detach Function Always Detaching the Latest Attached Service](https://github.com/ballerina-platform/ballerina-standard-library/issues/2356)

## [1.0.0] - 2021-10-09

### Added
- [[#1634] Add Alias Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1634)
- [[#1361] Add Variable Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1361)
- [[#1492] Add Mutation Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1492)
- [[#1723] Add Type Name Introspection](https://github.com/ballerina-platform/ballerina-standard-library/issues/1723)
- [[#1704] Add Block String Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1704)
- [[#1365] Add Input Object Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1365)
- [[#1906] Add Context Support](https://github.com/ballerina-platform/ballerina-standard-library/issues/1906)

### Changed
- [[#1597] Validate Max Query Depth at Runtime](https://github.com/ballerina-platform/ballerina-standard-library/issues/1597)

### Fixed
- [[#1622] Invalidate Returning any or anydata from GraphQL Resource Functions](https://github.com/ballerina-platform/ballerina-standard-library/issues/1622)
- [[#1688] Fix GraphQL Query Includes Unknown Fragments Returning an Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/1688)
- [[#1728] Fix Introspection not Working for `__type`](https://github.com/ballerina-platform/ballerina-standard-library/issues/1728)
- [[#1730] Fix Validating `__schema` Field Disregarding the Position](https://github.com/ballerina-platform/ballerina-standard-library/issues/1730)
- [[#1818] Fix NON_NULL Type Inputs with Default Values Shown as Nullable](https://github.com/ballerina-platform/ballerina-standard-library/issues/1818)
- [[#1879] Fix Nullable Record Fields Identifying as NON_NULL Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/1879)
- [[#1845] Fix not Allowing to Pass `null` as Input Value](https://github.com/ballerina-platform/ballerina-standard-library/issues/1845)
- [[#1803] Fix Not Allowing NON_NULL Type in Variable Definitions](https://github.com/ballerina-platform/ballerina-standard-library/issues/1803)
- [[#1911] Fix Variable Default Value With Invalid Type Retuning Error](https://github.com/ballerina-platform/ballerina-standard-library/issues/1911)
- [[#1912] Fix Nullable Variables Return Error when Value is not Present](https://github.com/ballerina-platform/ballerina-standard-library/issues/1912)
- [[#1912] GraphQL auth errors are not in proper format](https://github.com/ballerina-platform/ballerina-standard-library/issues/1920)
- [[#1953] Fix Allowing Record Fields to Have Invalid Types](https://github.com/ballerina-platform/ballerina-standard-library/issues/1953)
- [[#1983] Fix Not Allowing Int Value as Default Value in Float Type Variables](https://github.com/ballerina-platform/ballerina-standard-library/issues/1983)
- [[#1984] Fix Not Allowing to Pass Default Value to Enum Type Variables](https://github.com/ballerina-platform/ballerina-standard-library/issues/1984)
- [[#1990] Fix Accepting Enum Value as Default Value in String Type Variables](https://github.com/ballerina-platform/ballerina-standard-library/issues/1990)
- [[#1998] Fix Ignoring Parameters after Context Parameter](https://github.com/ballerina-platform/ballerina-standard-library/issues/1998)
- [[#2003] Fix Failing Input Object Validation with Null Values](https://github.com/ballerina-platform/ballerina-standard-library/issues/2003)

## [0.2.0.beta.2]  - 2021-07-06

### Changed
- [[#1190] Make GraphQL Resource Execution Non-Blocking](https://github.com/ballerina-platform/ballerina-standard-library/issues/1190)
- [[#1218] Set `BAD_REQUEST` status code for responses with document validation errors](https://github.com/ballerina-platform/ballerina-standard-library/issues/1218)
- [[#1507] Add Path Entry to the Error Detail](https://github.com/ballerina-platform/ballerina-standard-library/issues/1507)

### Fixed
- [[#1447] Fix Returning Empty Values when Fragments Inside Fragments Querying Service Object](https://github.com/ballerina-platform/ballerina-standard-library/issues/1447)
- [[#1429] Fix Compiler Plugin Crashes when a Service has a Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/1429)
- [[#1277] Fix Fields Missing when a Query Having Duplicate Fields](https://github.com/ballerina-platform/ballerina-standard-library/issues/1277)
- [[#1497] Fix GraphQL Parser not Parsing Float Values with Exp Values](https://github.com/ballerina-platform/ballerina-standard-library/issues/1497)
- [[#1489] Fix Input Value Coercion When Int Values Passed to Float Arguments](https://github.com/ballerina-platform/ballerina-standard-library/issues/1489)
- [[#1508] Fix Incorrectly Validating Invalid Operation Names when a Single Operation is Present in the Document](https://github.com/ballerina-platform/ballerina-standard-library/issues/1508)
- [[#1505] Fix Field Order Not Maintained in the GraphQL Response](https://github.com/ballerina-platform/ballerina-standard-library/issues/1505)
- [[#1526] Fix Parser Skipping Some Characters from Comments](https://github.com/ballerina-platform/ballerina-standard-library/issues/1526)
- [[#1576] Fix Incorrect Response Order in GraphQL Response](https://github.com/ballerina-platform/ballerina-standard-library/issues/1576)
- [[#1566] Make Locations Field an Optional Field in Error Details](https://github.com/ballerina-platform/ballerina-standard-library/issues/1566)
- [[#1608] Fix Empty Queries Validated at the Listener](https://github.com/ballerina-platform/ballerina-standard-library/issues/1608)

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
- [[#1252] Fix Incorrect Behavior in Validation EnumValues Field](https://github.com/ballerina-platform/ballerina-standard-library/issues/1251)
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
