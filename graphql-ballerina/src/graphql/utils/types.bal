type Error distinct error;

type Scalar int|string|float|boolean;

type OutputObject map<Result>|OutputService;

type Result OutputObject|OutputObject?[]|Scalar|Scalar[]|();

public type Schema record {
   string name;
   int id;
   string birthDate;
};



