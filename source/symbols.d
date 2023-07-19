module yslc.symbols;

import yslc.error;
import yslc.parser;

struct FunctionSymbol {
	string   name;
	string[] parameters;
}

class Symbols {
	FunctionSymbol[] functions;
	bool             success;

	this() {
		
	}

	bool FunctionExists(string name) {
		foreach (ref func ; functions) {
			if (func.name == name) {
				return true;
			}
		}

		return false;
	}

	FunctionSymbol GetFunction(string name) {
		foreach (ref func ; functions) {
			if (func.name == name) {
				return func;
			}
		}

		assert(0);
	}

	void Generate(ProgramNode program, bool safe = true) {
		functions = [];
		success   = true;

		foreach (ref child ; program.children) {
			if (child.type != NodeType.FunctionDef) {
				continue;
			}
			
			auto node = cast(FunctionDefNode) child;

			if (safe) {
				if (FunctionExists(node.name)) {
					ErrorFunctionDefinedTwice(node.file, node.line, node.name);
					success = false;
				}
			}
			
			FunctionSymbol func;
			func.name        = node.name;
			func.parameters  = node.parameters;
			functions       ~= func;
		}
	}
}
