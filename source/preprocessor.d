module yslc.preprocessor;

import std.uni;
import std.file;
import std.path;
import std.array;
import std.string;
import std.algorithm;
import core.stdc.stdlib;
import yslc.error;
import yslc.split;

struct CodeLine {
	string file;
	size_t line;
	string contents;
}

CodeLine[] RunPreprocessor(
	string file, string[] includePaths, ref string[] included
) {
	CodeLine[] ret;
	string[]   code    = readText(file).replace("\r\n", "\n").split("\n");
	bool       success = true;

	foreach (i, ref line ; code) {
		if (line.empty()) {
			continue;
		}
	
		if (line[0] == '%') {
			auto parts = Split(file, i, line, &success);

			switch (parts[0]) {
				case "%include": {
					string localPath = dirName(file) ~ "/" ~ parts[1];

					if (included.canFind(localPath)) {
						break;
					}
					
					if (!exists(localPath)) {
						bool exist = false;

						foreach (ref path ; includePaths) {
							localPath = path ~ "/" ~ parts[1];
							
							if (exists(localPath)) {
								exist = true;

								if (included.canFind(localPath)) {
									break;
								}

								included ~= localPath;
								
								ret ~= RunPreprocessor(
									localPath, includePaths, included
								);
								
								break;
							}
						}

						if (exist) {
							break;
						}
						
						ErrorNoSuchFile(file, i, localPath);
						success = false;
						break;
					}

					included ~= localPath;
					ret      ~= RunPreprocessor(localPath, includePaths, included);
					break;
				}
				default: {
					ErrorUnknownDirective(file, i, parts[0]);
					success = false;
					break;
				}
			}
		}
		else if (line.strip().empty()) {
			continue;
		}
		else if (line.strip()[0] == '#') {
			// comment
			continue;
		}
		else {
			ret ~= CodeLine(
				file, // file name
				i,    // line number
				line  // line contents
			);
		}
	}

	if (!success) {
		exit(1);
	}

	return ret;
}
