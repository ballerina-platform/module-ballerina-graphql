import ballerina/io;
import ballerina/stringutils;

isolated function parse(string documentString) returns Document|Error {
    Token[] tokens = tokenize(documentString);

    if (tokens[0].value == "{") {
        Token openBraceToken = tokens.remove(0);
        Operation operation = check parseShortHandNotation(tokens);
        return {
            operations: [operation]
        };
    } else {
        Operation operation = check parseGeneralNotation(tokens);
        return {
            operations: [operation]
        };
    }
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

isolated function parseShortHandNotation(Token[] tokens) returns Operation|InvalidDocumentError {
    OperationType 'type = OPERATION_QUERY;
    return getOperationRecord('type, tokens);
}

isolated function parseGeneralNotation(Token[] tokens) returns Operation|InvalidDocumentError {
    OperationType operationType = check getOperationType(tokens);
    Token operationToken = tokens.remove(0);
    string operationName = operationToken.value;
    if (operationName == OPEN_BRACE) {
        return getOperationRecord(operationType, tokens);
    } else {
        Token openBraceToken = tokens.remove(0);
        string openBraceTokenValue = openBraceToken.value;
        if (openBraceTokenValue == OPEN_BRACE) {
            return getOperationRecord(operationType, tokens, operationName);
        } else {
            return getExpectedSyntaxError(openBraceToken, OPEN_BRACE, VALIDATION_TYPE_NAME);
        }
    }
}

isolated function getOperationRecord(OperationType 'type, Token[] tokens, string name = "") returns
Operation|InvalidDocumentError {
    Token[] fields = check getFields(tokens);
    if (name == "") {
        return {
            'type: 'type,
            fields: fields
        };
    } else {
        return {
            'type: 'type,
            fields: fields,
            name: name
        };
    }
}

isolated function getFields(Token[] tokens) returns Token[]|InvalidDocumentError {
    Token[] fields = [];
    int count = 0;
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
            fields[count] = token;
            count += 1;
        }
    }
    return getExpectedSyntaxError(fields[count-1], VALIDATION_TYPE_NAME, "<EOF>");
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
