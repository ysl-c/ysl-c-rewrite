module yslc.parser;

import std.conv;
import std.stdio;
import std.format;
import core.stdc.stdlib;
import yslc.error;
import yslc.lexer;

enum NodeType {
	Null,
	Program,
	FunctionDef,
	FunctionCall,
	Integer,
	String,
	Variable,
	Return,
	Asm,
	LocalDeclaration,
	IntVariable,
	Set,
	Addr,
	If
}

class Node {
	NodeType type;
	string   file;
	size_t   line;
	abstract string ToString();
}

class ProgramNode : Node {
	Node[] children;

	this() {
		type = NodeType.Program;
	}

	override string ToString() {
		string str = "Program:\n";
		
		foreach (ref child ; children) {
			str ~= child.ToString() ~ '\n';
		}
		
		return str;
	}
}

class FunctionDefNode : Node {
	string   name;
	string[] parameters;
	Node[]   functionBody;

	this() {
		type = NodeType.FunctionDef;
	}

	override string ToString() {
		string str = format("func %s ", name);

		foreach (ref param ; parameters) {
			str ~= param ~ ' ';
		}
		str ~= '\n';

		foreach (ref node ; functionBody) {
			str ~= node.ToString() ~ '\n';
		}

		str ~= "end";
		return str;
	}
}

class FunctionCallNode : Node {
	string name;
	Node[] parameters;

	this() {
		type = NodeType.FunctionCall;
	}

	override string ToString() {
		string str = format("call %s ", name);

		foreach (ref param ; parameters) {
			str ~= param.ToString() ~ ' ';
		}

		str ~= '\n';
		return str;
	}
}

class IntegerNode : Node {
	int value;

	this() {
		type = NodeType.Integer;
	}

	override string ToString() {
		return format("int %d", value);
	}
}

class StringNode : Node {
	string value;

	this() {
		type = NodeType.String;
	}

	override string ToString() {
		return format("string '%s'", value);
	}
}

class VariableNode : Node {
	string name;

	this() {
		type = NodeType.Variable;
	}

	override string ToString() {
		return format("variable %s", name);
	}
}

class ReturnNode : Node {
	Node value;

	this() {
		type = NodeType.Return;
	}

	override string ToString() {
		return format("return %s", value.ToString());
	}
}

class AsmNode : Node {
	string assembly;

	this() {
		type = NodeType.Asm;
	}

	override string ToString() {
		return format("asm %s\n", assembly);
	}
}

class LocalDeclarationNode : Node {
	Node declaration;

	this() {
		type = NodeType.LocalDeclaration;
	}

	override string ToString() {
		return format("local %s\n", declaration.ToString());
	}
}

class IntVariableNode : Node {
	string name;

	this() {
		type = NodeType.IntVariable;
	}

	override string ToString() {
		return format("int %s", name);
	}
}

class SetNode : Node {
	string var;
	Node   value;

	this() {
		type = NodeType.Set;
	}

	override string ToString() {
		return format("set %s %s", var, value.ToString());
	}
}

class AddrNode : Node {
	string var;

	this() {
		type = NodeType.Addr;
	}

	override string ToString() {
		return format("addr %s", var);
	}
}

class IfNode : Node {
	FunctionCallNode call;
	Node[]           ifBody;

	this() {
		type = NodeType.If;
	}

	override string ToString() {
		string str = format("if %s\n", call.ToString());

		foreach (ref node ; ifBody) {
			str ~= node.ToString() ~ '\n';
		}

		str ~= "end\n";
		return str;
	}
}

class Parser {
	ProgramNode tree;
	Lexer       lexer;
	size_t      i;
	bool        success;

	this() {
		tree    = new ProgramNode();
		success = true;
	}

	void Next() {
		++ i;

		if (i >= lexer.tokens.length) {
			auto lastToken = lexer.tokens[$ - 1];
			ErrorExpectedToken(lastToken.file, lastToken.line);
			exit(1);
		}
	}

	bool CorrectToken(TokenType correct) {
		if (lexer.tokens[i].type != correct) {
			ErrorUnexpectedToken(
				lexer.tokens[i].file, lexer.tokens[i].line, lexer.tokens[i].type
			);
			success = false;
			return false;
		}
		return true;
	}

	Node ParseFunctionDef() {
		auto node = new FunctionDefNode();
		node.file = lexer.tokens[i].file;
		node.line = lexer.tokens[i].line;

		// parse function name
		Next();
		if (!CorrectToken(TokenType.Identifier)) {
			return null;
		}
		node.name = lexer.tokens[i].contents;

		// parse parameters
		Next();
		while (lexer.tokens[i].type != TokenType.EndLine) {
			if (!CorrectToken(TokenType.Identifier)) {
				return null;
			}

			node.parameters ~= lexer.tokens[i].contents;
			Next();
		}

		// parse function body
		Next();
		while (
			(lexer.tokens[i].type != TokenType.Keyword) ||
			(lexer.tokens[i].contents != "end")
		) {
			if (lexer.tokens[i].type == TokenType.EndLine) {
				Next();
				continue;
			}
			node.functionBody ~= ParseStatement();
		}
		Next();

		return cast(Node) node;
	}

	Node ParseReturn() {
		auto node = new ReturnNode();
		node.file = lexer.tokens[i].file;
		node.line = lexer.tokens[i].line;

		Next();
		node.value = ParseParameter();

		return cast(Node) node;
	}

	Node ParseFunctionCall() {
		auto node = new FunctionCallNode();
		node.file = lexer.tokens[i].file;
		node.line = lexer.tokens[i].line;

		node.name = lexer.tokens[i].contents;

		Next();
		while (lexer.tokens[i].type != TokenType.EndLine) {
			node.parameters ~= ParseParameter();
			Next();
		}

		return cast(Node) node;
	}

	Node ParseAsm() {
		auto node     = new AsmNode();
		node.file     = lexer.tokens[i].file;
		node.line     = lexer.tokens[i].line;
		node.assembly = lexer.tokens[i].contents;
		Next();
		return cast(Node) node;
	}

	Node ParseVariableDef() {
		if (!CorrectToken(TokenType.Keyword)) {
			return null;
		}

		Node ret;

		switch (lexer.tokens[i].contents) {
			case "int": {
				auto node = new IntVariableNode();

				Next();
				if (!CorrectToken(TokenType.Identifier)) {
					return null;
				}

				node.name = lexer.tokens[i].contents;
				Next();

				ret = cast(Node) node;
				break;
			}
			default: assert(0);
		}

		return ret;
	}

	Node ParseLocal() {
		auto node = new LocalDeclarationNode();
		Next();
		node.declaration = ParseVariableDef();

		return cast(Node) node;
	}

	Node ParseSet() {
		auto node = new SetNode();

		Next();
		if (!CorrectToken(TokenType.Identifier)) {
			ErrorUnexpectedToken(
				lexer.tokens[i].file, lexer.tokens[i].line, lexer.tokens[i].type
			);
			exit(1);
		}

		node.var = lexer.tokens[i].contents;

		Next();
		node.value = ParseParameter();
		Next();

		return cast(Node) node;
	}

	Node ParseAddr() {
		auto node = new AddrNode();

		Next();
		if (!CorrectToken(TokenType.Identifier)) {
			exit(1);
		}

		node.var = lexer.tokens[i].contents;
		Next();

		return cast(Node) node;
	}

	Node ParseIf() {
		auto node = new IfNode();

		Next();
		if (!CorrectToken(TokenType.Identifier)) {
			exit(1);
		}

		node.call = cast(FunctionCallNode) ParseFunctionCall();

		Next();
		while (
			(lexer.tokens[i].type != TokenType.Keyword) ||
			(lexer.tokens[i].contents != "end")
		) {
			if (lexer.tokens[i].type == TokenType.EndLine) {
				Next();
				continue;
			}
			node.ifBody ~= ParseStatement();
			Next();
		}

		return cast(Node) node;
	}

	Node ParseParameter() {
		Node ret;
	
		switch (lexer.tokens[i].type) {
			case TokenType.Identifier: {
				auto node = new VariableNode();
				node.file = lexer.tokens[i].file;
				node.line = lexer.tokens[i].line;
				node.name = lexer.tokens[i].contents;

				ret = cast(Node) node;
				break;
			}
			case TokenType.String: {
				auto node  = new StringNode();
				node.file = lexer.tokens[i].file;
				node.line = lexer.tokens[i].line;
				node.value = lexer.tokens[i].contents;

				ret = cast(Node) node;
				break;
			}
			case TokenType.Integer: {
				auto node  = new IntegerNode();
				node.file = lexer.tokens[i].file;
				node.line = lexer.tokens[i].line;
				node.value = parse!int(lexer.tokens[i].contents);

				ret = cast(Node) node;
				break;
			}
			default: {
				ErrorUnexpectedToken(
					lexer.tokens[i].file, lexer.tokens[i].line,
					lexer.tokens[i].type
				);
				success = false;
				return null;
			}
		}

		return ret;
	}

	Node ParseStatement(bool insideStatement = true) {
		while (lexer.tokens[i].type == TokenType.EndLine) {
			Next();
		}
	
		switch (lexer.tokens[i].type) {
			case TokenType.Keyword: {
				switch (lexer.tokens[i].contents) {
					case "func": {
						if (insideStatement) {
							ErrorFunctionInsideStatement(
								lexer.tokens[i].file, lexer.tokens[i].line
							);
							exit(1);
						}
					
						return ParseFunctionDef();
					}
					case "return": return ParseReturn();
					case "local":  return ParseLocal();
					case "int":    return ParseVariableDef();
					case "set":    return ParseSet();
					case "addr":   return ParseAddr();
					case "if":     return ParseIf();
					default: {
						ErrorUnexpectedKeyword(
							lexer.tokens[i].file, lexer.tokens[i].line,
							lexer.tokens[i].contents
						);
						success = false;
						exit(1);
					}
				}
			}
			case TokenType.Identifier: {
				return ParseFunctionCall();
			}
			case TokenType.Asm: {
				return ParseAsm();
			}
			default: {
				ErrorUnexpectedToken(
					lexer.tokens[i].file, lexer.tokens[i].line,
					lexer.tokens[i].type
				);
				success = false;
				return null;
			}
		}
	}

	void Parse() {
		for (i = 0; i < lexer.tokens.length; ++ i) {
			tree.children ~= ParseStatement(false);

			if (!success) {
				return;
			}
		}
	}
}

