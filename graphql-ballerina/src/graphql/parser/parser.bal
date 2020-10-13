import ballerina/io;
import ballerina/stringutils;

isolated function parse(string documentString) returns Document|Error {
    Token[] tokens = tokenize(documentString);

    if (tokens[0].value == "{") {
        parseShortHandNotation(tokens);
    } else {
        Operation operation = check parseGeneralNotation(tokens);
        return {
            operations: [operation]
        };
    }
    return NotImplementedError("Not Implemented");
}

isolated function tokenize(string document) returns Token[] {
    Token[] tokens = [];
    string[] lines = stringutils:split(document, "\n");
    int lineNumber = 0;
    foreach string line in lines {
        lineNumber += 1;
        parseByColumns(line, lineNumber, tokens);
    }
    return tokens;
}

isolated function parseByColumns(string line, int lineNumber, Token[] tokens) {
    string[] words = stringutils:split(line, "\\s+");
    foreach string word in words {
        if (word == "") {
            continue;
        }
        int columnNumber = <int>'string:indexOf(line, word);
        Token token = {
            value: word,
            line: lineNumber,
            column: columnNumber
        };
        tokens.push(token);
    }
}

isolated function parseShortHandNotation(Token[] tokens) {
    io:println("Shorthand Notation");
}

isolated function parseGeneralNotation(Token[] tokens) returns Operation|InvalidDocumentError {
    OperationType operationType = check getOperationType(tokens);
    Token operationToken = tokens.remove(0);
    string operationName = operationToken.value;
    if (operationName == OPEN_BRACE) {
        return getOperation(tokens);
    } else {
        Token openBraceToken = tokens.remove(0);
        string openBraceTokenValue = openBraceToken.value;
        if (openBraceTokenValue == OPEN_BRACE) {
            return getOperation(tokens, operationName);
        } else {
            return getExpectedSyntaxError(openBraceToken, OPEN_BRACE, VALIDATION_TYPE_NAME);
        }
    }
}

isolated function getOperation(Token[] tokens, string name = "") returns Operation|InvalidDocumentError {
    string[] fields = check getFields(tokens);
    if (name == "") {
        return {
            'type: OPERATION_QUERY,
            fields: fields
        };
    } else {
        return {
            'type: OPERATION_QUERY,
            fields: fields,
            name: name
        };
    }
}

isolated function getFields(Token[] tokens) returns string[]|InvalidDocumentError {
    string[] fields = [];
    int count = 0;
    Token lastToken = tokens[0];
    foreach Token token in tokens {
        string value = token.value;
        if (value == OPEN_BRACE) {
            string message = "Ballerina GraphQL does not support multi-level queries yet.";
            return InvalidDocumentError(message);
        } else if (value == CLOSE_BRACE) {
            if (fields.length() == 0) {
                return getExpectedSyntaxError(token, VALIDATION_TYPE_NAME, CLOSE_BRACE);
            }
            return fields;
        } else {
            fields[count] = value;
            lastToken = token;
            count += 1;
        }
    }
    return getExpectedSyntaxError(lastToken, VALIDATION_TYPE_NAME, "<EOF>");
}

isolated function getOperationType(Token[] tokens) returns OperationType|InvalidDocumentError {
    Token token = tokens.remove(0);
    var operationType = token.value;
    if (operationType is OperationType) {
        return operationType;
    } else {
        return getUnexpectedSyntaxError(token, VALIDATION_TYPE_NAME);
    }
}

isolated function printArray(string[] array) {
    foreach string s in array {
        io:println("    " + s);
    }
}
