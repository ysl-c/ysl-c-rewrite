module yslc.lexer;

import std.conv;
import std.string;
import std.algorithm;
import yslc.error;
import yslc.language;
import yslc.preprocessor;

enum TokenType {
	Null,
	Identifier,
	Keyword,
	String,
	Integer,
	Asm,
	EndLine
}

struct Token {
	TokenType type;
	string    contents;
	string    file;
	size_t    line;
}

class Lexer {
	CodeLine[] lines;
	Token[]    tokens;
	size_t     line;
	size_t     col;
	bool       inString;
	string     reading;
	bool       success;

	this() {
		success = true;
	}

	void AddToken(TokenType type) {
		tokens  ~= Token(type, reading, lines[line].file, lines[line].line);
		reading  = "";
	}

	void AddReading() {
		if (reading.strip() == "") {
			return;
		}
		else if (reading.isNumeric()) {
			AddToken(TokenType.Integer);
		}
		else if (keywords.canFind(reading)) {
			AddToken(TokenType.Keyword);
		}
		else {
			AddToken(TokenType.Identifier);
		}
	}

	void LexLine() {
		auto thisLine = lines[line];
		
		for (col = 0; col < thisLine.contents.length; ++ col) {
			auto ch = thisLine.contents[col];

			switch (ch) {
				case '"': {
					inString = !inString;

					if (!inString) {
						AddToken(TokenType.String);
					}
					break;
				}
				case '#': {
					if (inString) {
						reading ~= ch;
					}
					else {
						return;
					}
					
					break;
				}
				case '\\': {
					if (!inString) {
						reading ~= ch;
						break;
					}

					++ col;
					auto escaped = Escape(thisLine.contents[col]);

					if (escaped == 0) {
						ErrorUnknownEscape(
							thisLine.file, thisLine.line, thisLine.contents[col]
						);
						success = false;
						return;
					}

					reading ~= escaped;
					break;
				}
				case '\t':
				case ' ': {
					if (inString) {
						reading ~= ch;
						break;
					}

					if (reading == "asm") {
						auto assembly = lines[line].contents[col .. $].strip();

						tokens ~= Token(
							TokenType.Asm, assembly, lines[line].file,
							lines[line].line
						);
						reading = "";
						AddToken(TokenType.EndLine);
						return;
					}
				
					AddReading();
					break;
				}
				default: {
					reading ~= ch;
				}
			}
		}

		if (inString) {
			ErrorIncompleteString(thisLine.file, thisLine.line);
			success = false;
			return;
		}

		AddReading();
		AddToken(TokenType.EndLine);
	}

	void Lex() {
		for (line = 0; line < lines.length; ++ line) {
			LexLine();
		}
	}
}
