# Proposal: GraphQL Context

_Owners_: @Nuvindu @ThisaruGuruge @DimuthuMadushan @shafreenAnfar     
_Reviewers_: @shafreenAnfar @ThisaruGuruge    
_Created_: 2022/03/28   
_Updated_: 2022/03/30     
_Issue_: [#2821](https://github.com/ballerina-platform/ballerina-standard-library/issues/2821)

## Summary
GraphQL Subscription is one of the three operations in GraphQL. However, the Ballerina GraphQL package only supports query and mutation. This proposal is to introduce subscription support for the Ballerina GraphQL package.
## Goals
* Provide GraphQL subscription support for Ballerina GraphQL services.
## Non-Goals
* Add a Pub/Sub module to the Ballerina GraphQL package to provide APIs for the users to simplify their code.
## Motivation
GraphQL subscriptions are widely used in real-time applications. Using subscriptions, GraphQL servers can send data continuously to the clients while maintaining a persistent connection. However, at the moment such applications cannot be developed using the Ballerina GraphQL package as it only supports `query` and `mutation` operations. Hence, there is a need to support `subscription` operations also.

On the other hand, the Ballerina GraphQL package is not spec-compliant until the `subscription` operation is supported.

## Description
### Overview
There are a few challenges in implementing a `subscription` operation. First, there should be a way to clearly distinguish `subscription` resolvers from `mutation` and `query` operations. So that the GraphQL package can generate the schema from the code.

Second, unlike `mutation` and `query` operations, the `subscription` operation requires a persistent connection. Unbounded events are continuously pushed to the client using the persistent connection. The same event might be pushed across multiple persistent connections.

The proposed solution addresses all the above while minimizing the code that has to be written to provide a better user experience.
#### Subscription Resolver

Subscription resolvers use resource functions with the `get` accessor. This is because subscription resolvers don’t mutate the application state. The return value of the subscription resolver is the Ballerina stream. The stream can be any type.

The returned stream is mapped to one or more connections. Since the connection must be persistent, HTTP connections are upgraded to WebSocket connections. Underline implementation reads the stream in a loop and pushes the data to mapped WebSocket connections until the end of the stream or an error is returned.

The following is an example resolver for graphql subscription.

```ballerina 
 resource function get message() returns stream<string,error?> { ... }
```

Both `query` operation and `subscription` use resource functions to represent them. Unlike `query` operations, `subscription` operations only allow returning streams. This allows the GraphQL engine to distinguish one from the other.
### Writing a GraphQL Subscription Service

Writing a GraphQL service with subscriptions must not be complicated from the developer’s perspective. Following is how the GraphQL subscription service can be written.
#### Initiate a Pipe Instance in the GraphQL Service

An array of [Pipes](#pipe) has to be instantiated first. These pipes can be used to produce and consume messages. A detailed explanation of the Pipe can be found later. This array will hold a separate pipe for each subscribed client.

```ballerina
  service /graphql on new graphql:Listener(4000) {
     Pipe[] pipes;
     ...
  }
  ``` 
#### Subscription Resolver

As mentioned earlier the subscription resolver must return a stream. An instance of the return stream can be created with the help of the Pipe. Therefore a new pipe instance must be instantiated here and added that to the pipes array. Then a stream must be returned using the `consumeStream` method of the pipe. To do this, the Pipe uses Ballerina’s dependent type feature.

```ballerina 
 resource function get message() returns stream<string,error?> {
      Pipe pipe = new(10);
      pipes.push(pipe);
      return pipe.consumeStream();  
 }
```

#### Triggering Events

The event source of subscriptions could be anything, in this case, the event source is the `addMessage` mutation resolver. Once the message is received from the event source, the message can be produced to each pipe in the pipe array. The produced message can be consumed from the pipe using the `consumeStream` method.


```ballerina
 remote function addMessage(string msg) {
    for pipe in pipes {
      pipe.produce(msg, timeout = 10);
    }
    ...
 }
```


### Pipe
The Pipe allows you to send data from one place to another. Following are the APIs of the Pipe. There is one method to produce and two methods to consume. Users can use either option as they wish but not both at once. The implementation of the `consumeStream` usually uses the `consume` method to provide its functionality.


```ballerina 
    public class Pipe {

        public function init(int 'limit) { ...//sets a limit }
        
        // produces data into the pipe
        // if full, blocks
        public isolated function produce(any data, decimal timeout) = external;
    
        // returns data in the pipe
        // if empty, blocks
        public isolated function consume(decimal timeout, typedesc<any> t = <>) returns t|error = external;
    
        // returns a stream 
        // data produced to the pipe can be fetched by the stream
        public isolated function consumeStream(decimal timeout, typedesc<any> t|error = <>) returns stream<t, error?> = external;
    
    }
```


The pipe can hold up to n number of data. In case the pipe is full, the `producer` method blocks until there is a free slot to produce data. On the other hand, in case the pipe is empty, the `consumer` method blocks until there is some data to consume. This behavior is somewhat similar to `go channels`. A timeout must be set to the `produce` and `consume` methods to regulate the waiting time in the blocking state.


### Filtering Events

Subscription resolvers can be designed to filter data according to the input parameters as shown below.
#### Custom Generator

The user has to create a new generator function to filter data from the stream.  And it can be configured any way the user prefers.


```ballerina
  class CustomGenerator {
    private stream<Person, error?> originalStream;
    private any data;
    function init(stream<Person, error?> originalStream, any data) {
        self.originalStream = originalStream;
        self.data = data;
    }
    public isolated function next() returns record {| Person value; |}|error? {
        MsgRecord|error? msgRecord = self.originalStream.next();
        if msgRecord is MsgRecord {
            Person person = msgRecord.value;
            if(self.data == person.getAge()){
                return { value: person };
            }
        }
        return;
    }
  }
 
  type MsgRecord record {|
    Person value;
  |};
 ```

#### Subscription Resolver

A new custom generator instance has to be created here using the original stream and the input data. Then a new stream must be created using that custom generator. It must be returned after that.


```ballerina
  resource function get personDetails(int age) returns stream<Person,error?>{
      Pipe pipe = new(10);
      pipes.push(pipe);   
      stream<Person, error?> originalStream = pipe.consumeStream();
      CustomGenerator customGenerator = new(originalStream, age);
      stream<Person, error?> filteredStream = new(customGenerator);
      return filteredStream;
  }
```
