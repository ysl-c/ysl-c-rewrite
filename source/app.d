module yslc.app;

import std.file;
import std.array;
import std.stdio;
import yslm.split;
import yslm.compiler;
import yslm.compileModule;
import yslm.targets.x86_16;
import yslc.lexer;
import yslc.parser;
import yslc.symbols;
import yslc.compiler;
import yslc.preprocessor;

int main(string[] args) {
	string   inFile;
	string   outFile;
	bool     verbose;
	string[] includePaths;
	bool     lexerDebug;
	bool     parserDebug;
	bool     showSymbols;
	bool     showYSLM;
	
	for (size_t i = 1; i < args.length; ++ i) {
		if (args[i][0] == '-') {
			switch (args[i]) {
				case "-o": {
					++ i;
					outFile = args[i];
					break;
				}
				case "-v": {
					verbose = true;
					break;
				}
				case "-i": {
					++ i;
					includePaths ~= args[i];
					break;
				}
				case "-ld": {
					lexerDebug = true;
					break;
				}
				case "-pd": {
					parserDebug = true;
					break;
				}
				case "--functions": {
					showSymbols = true;
					break;
				}
				case "--yslm": {
					showYSLM = true;
					break;
				}
				default: {
					stderr.writefln("Unknown option '%s'", args[i]);
					return 1;
				}
			}
		}
		else {
			if (inFile != "") {
				stderr.writeln("Source file set multiple times");
				return 1;
			}

			inFile = args[i];
		}
	}

	string[] included;
	auto     lines = RunPreprocessor(inFile, includePaths, included);

	auto lexer  = new Lexer();
	lexer.lines = lines;

	lexer.Lex();

	if (!lexer.success) {
		stderr.writeln("Lexing failed");
		return 1;
	}

	if (lexerDebug) {
		writeln(lexer.tokens);
		return 0;
	}

	auto parser  = new Parser();
	parser.lexer = lexer;
	parser.Parse();

	if (!parser.success) {
		stderr.writeln("Parsing failed");
		return 1;
	}

	if (parserDebug) {
		writeln(parser.tree.ToString());
		return 0;
	}

	auto symbols = new Symbols();
	symbols.Generate(parser.tree);

	if (showSymbols) {
		foreach (ref func ; symbols.functions) {
			string str = func.name;
			
			foreach (ref param ; func.parameters) {
				str ~= param ~ ' ';
			}

			writeln(str);
		}
		return 0;
	}

	if (!symbols.success) {
		stderr.writeln("Symbol generation failed");
		return 1;
	}

	auto compiler    = new Compiler();
	compiler.symbols = symbols;

	compiler.Compile(parser.tree);

	if (!compiler.success) {
		stderr.writeln("Compilation failed");
		return 1;
	}

	if (showYSLM) {
		writeln(compiler.output.join("\n"));
		return 0;
	}

	string[] assembly;

	bool          yslmSuccess = true;
	CompileModule mod         = new Target_x86_16();

	assembly ~= mod.CompileOrg("0x100");
	
	foreach (i, ref line ; compiler.output) {
		auto parts  = Split("<YSL-C out>", i, line, &yslmSuccess);
		assembly   ~= CompileLine("<YSL-C out>", i, parts, &yslmSuccess, mod);
	}

	if (!yslmSuccess) {
		stderr.writeln("YSL-M assembly gen failed");
		return 1;
	}

	std.file.write(outFile, assembly.join("\n"));

	return 0;
}
