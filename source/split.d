module yslc.split;

import std.range;
import yslc.error;

// used to be responsible for lexing the whole code
// now it is only used for the preprocessor
string[] Split(string file, size_t line, string str, bool* success) {
	string[] ret;
	string   reading;
	bool     inString;

	for (size_t i = 0; i < str.length; ++ i) {
		switch (str[i]) {
			case '\t':
			case ' ': {
				if (inString) {
					reading ~= str[i];
					break;
				}

				if (!reading.empty()) {
					ret ~= reading;
				}
				
				reading  = "";
				break;
			}
			case '"': {
				inString = !inString;
				break;
			}
			case '\\': {
				++ i;
				switch (str[i]) {
					case 'n': {
						reading ~= '\n';
						break;
					}
					case 'r': {
						reading ~= '\r';
						break;
					}
					case 'e': {
						reading ~= '\x1b';
						break;
					}
					default: {
						ErrorUnknownEscape(
							file, line, str[i]
						);
						*success = false;
					}
				}
				break;
			}
			default: {
				reading ~= str[i];
				break;
			}
		}
	}

	if (!reading.empty()) {
		ret ~= reading;
	}

	return ret;
}
