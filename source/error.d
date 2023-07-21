module yslc.error;

import std.stdio;
import core.stdc.stdlib;
import yslc.lexer;

void ErrorBegin(string fname, size_t line) {
	version (Windows) {
		stderr.writef("%s:%d: error: ", fname, line + 1);
	}
	else {
		stderr.writef("\x1b[1m%s:%d: \x1b[31merror:\x1b[0m ", fname, line + 1);
	}
}

void ErrorUnknownEscape(string fname, size_t line, char ch) {
	ErrorBegin(fname, line);
	stderr.writefln("Unknown escape sequence \\%c", ch);
}

void ErrorNoSuchFile(string fname, size_t line, string file) {
	ErrorBegin(fname, line);
	stderr.writefln("No such file exists: '%s'", file);
}

void ErrorUnknownDirective(string fname, size_t line, string directive) {
	ErrorBegin(fname, line);
	stderr.writefln("Unknown directive: '%s'", directive);
}

void ErrorIncompleteString(string fname, size_t line) {
	ErrorBegin(fname, line);
	stderr.writeln("Incomplete string");
}

void ErrorExpectedToken(string fname, size_t line) {
	ErrorBegin(fname, line);
	stderr.writeln("Expected token");
}

void ErrorUnexpectedToken(string fname, size_t line, TokenType token) {
	ErrorBegin(fname, line);
	stderr.writefln("Unexpected token: %s", token);
}

void ErrorUnexpectedKeyword(string fname, size_t line, string keyword) {
	ErrorBegin(fname, line);
	stderr.writefln("Unexpected keyword: %s", keyword);
}

void ErrorFunctionDefinedTwice(string fname, size_t line, string name) {
	ErrorBegin(fname, line);
	stderr.writefln("Function '%s' defined twice", name);
}

void ErrorFunctionDefInsideFunction(string fname, size_t line) {
	ErrorBegin(fname, line);
	stderr.writeln("Function definitions cannot be defined inside of functions");
}

void ErrorNoSuchFunction(string fname, size_t line, string name) {
	ErrorBegin(fname, line);
	stderr.writefln("No such function '%s'", name);
}

void ErrorWrongParameterAmount(
	string fname, size_t line, ulong expected, ulong got
) {
	ErrorBegin(fname, line);
	stderr.writefln(
		"Wrong amount of parameters, expected %d, got %d", expected, got
	);
}
