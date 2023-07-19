module yslc.compiler;

import std.stdio;
import std.format;
import yslc.error;
import yslc.parser;
import yslc.symbols;
import yslc.language;

class Compiler {
	string[]   output;
	bool       success;
	string     lastFunction;
	Variable[] globals;
	Variable[] locals;
	Symbols    symbols;

	void CreateGlobal(VariableType type, string name) {
		globals ~= Variable(type, name, format("__var__%s", name));
	}

	void CreateLocal(VariableType type, string name) {
		locals ~= Variable(
			type, name, format("__func__%s.__var__%s", lastFunction, name)
		);
	}

	bool VariableExists(string name) {
		foreach (ref local ; locals) {
			if (local.name == name) {
				return true;
			}
		}

		foreach (ref global ; globals) {
			if (global.name == name) {
				return true;
			}
		}

		return false;
	}

	string GetVariable(string name) {
		foreach (ref local ; locals) {
			if (local.name == name) {
				return local.labelName;
			}
		}

		foreach (ref global ; globals) {
			if (global.name == name) {
				return global.labelName;
			}
		}

		assert(0);
	}

	void CompileFunctionDef(FunctionDefNode node) {
		output ~= format("goto __func_end__%s", node.name);
		output ~= format("label __func__%s", node.name);

		lastFunction = node.name;

		foreach (ref param ; node.parameters) {
			writeln("hi2");
			CreateLocal(VariableType.Integer, param);
		}
		writeln(locals);

		foreach (ref bodyNode ; node.functionBody) {
			if (bodyNode.type == NodeType.FunctionDef) {
				ErrorFunctionDefInsideFunction(node.file, node.line);
				success = false;
				return;
			}
			
			CompileNode(bodyNode);
		}

		output ~= "return";

		foreach (ref local ; locals) {
			output ~= format("label %s", local.labelName);

			switch (local.type) {
				case VariableType.Pointer:
				case VariableType.Integer: {
					output ~= "word 0";
					break;
				}
				default: assert(0);
			}

			writeln("hi");
		}

		output ~= format("label __func_end__%s", node.name);
		locals  = [];
	}

	void CompileFunctionCall(FunctionCallNode node) {
		if (!symbols.FunctionExists(node.name)) {
			ErrorNoSuchFunction(node.file, node.line, node.name);
			success = false;
			return;
		}

		auto func = symbols.GetFunction(node.name);

		if (node.parameters.length != func.parameters.length) {
			ErrorWrongParameterAmount(
				node.file, node.line, func.parameters.length,
				node.parameters.length
			);
			success = false;
			return;
		}

		foreach (i, ref param ; node.parameters) {
			switch (param.type) {
				case NodeType.Integer: {
					auto pnode = cast(IntegerNode) param;
					
					output ~= format(
						"set __func__%s.__var__%s %d", node.name,
						func.parameters[i], pnode.value
					);
					break;
				}
				case NodeType.String: {
					assert(0); // TODO
				}
				case NodeType.Variable: {
					auto pnode = cast(VariableNode) param;

					output ~= format(
						"copy __func__%s.__var__%s %s",
						node.name, func.parameters[i], GetVariable(pnode.name)
					);
					break;
				}
				default: assert(0);
			}
		}

		output ~= format("gosub __func__%s", node.name);
	}

	void CompileAsm(AsmNode node) {
		output ~= format("asm %s", node.assembly);
	}

	void CompileNode(Node node) {
		switch (node.type) {
			case NodeType.FunctionDef: {
				CompileFunctionDef(cast(FunctionDefNode) node);
				break;
			}
			case NodeType.FunctionCall: {
				CompileFunctionCall(cast(FunctionCallNode) node);
				break;
			}
			case NodeType.Asm: {
				CompileAsm(cast(AsmNode) node);
				break;
			}
			default: assert(0);
		}
	}

	void Compile(ProgramNode program) {
		success  = true;
		output  ~= "goto __func__main";
		output  ~= "return";
	
		foreach (ref child ; program.children) {
			CompileNode(child);
		}
	}
}
