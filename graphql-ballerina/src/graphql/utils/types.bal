public type InvalidDocumentError distinct error;

type Error InvalidDocumentError;

type Id int|string;

type Scalar int|string|float|boolean|Id;
