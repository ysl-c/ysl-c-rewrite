module yslc.language;

const string[] keywords = [
	"func",
	"end",
	"return",
	"int",
	"local",
	"set"
];

char Escape(char ch) {
	switch (ch) {
		case 'n': return '\n';
		case 'e': return '\x1b';
		case 't': return '\t';
		case 'r': return '\r';
		default:  return 0;
	}
}

enum VariableType {
	Integer,
	Pointer
}

struct Variable {
	VariableType type;
	string       name;
	string       labelName;
}
