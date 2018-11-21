module volume

import IO;
import List;
import String;
import util::FileSystem;
import metrics;

list[str] trimSource(str src) {
	list[str] lines = split("\n", src);
	// Iterate over each line of the method
	int nLines = size(lines);
	list[str] ret = [];
	bool inMLC = false; // in multi-line comment
	for (int i <- [0 .. nLines]) {
		trimmed = trim(lines[i]); // removes leading+trailing whitespace

		if (startsWith(trimmed, "//"))
			continue;
		if (size(trimmed) < 1)
			continue;

		if (!inMLC) {
			if (startsWith(trimmed, "/*")) {
				inMLC = true;
			}
			else if (contains(trimmed, "/*")) {
				inMLC = true;
				// this line did not start with /*, so it had some code, so count it
				ret += trimmed;
			}
		}
		// even if we just found out this line starts a MLC, check if it also ends on the same line.
		// NOTE: this endsWith+contains method calls can probably be optimized into 1 "findFirst" or similar call by being smart
		// and still, will give wrong result if there's a case like
		//		/* bla */ int x=1; /* lol */   <-- in this case, this line will be skipped = bad
		if (inMLC) {
			if (endsWith(trimmed, "*/")) {
				inMLC = false;
				// no code on this line, so continue to next (this is not 100% sure! - gives wrong result in some cases)
				continue;
			}
			else if (contains(trimmed, "*/")) {
				// this line did not end with */, so possibly there is code here, so count this line
				inMLC = false;
			}
		}

		if (inMLC)
			continue;

		ret += trimmed;
	}

	return ret;
}

int unitsize (str src) {
	return size(trimSource(src));
}

// Returns the number of source line codes of all Java-files in a folder.
// Ignores lines with only comments or whitelines.
// NOTE: assumes that all source files use "\n" line endings, not "\r\n" !
int unitsizeOld (str src) {
	lines = split("\n", src);

	int nSrcLines = 0;
	int nLines = size(lines);

	// Trim all lines of trailing whitespace.
	for (int j <- [0 .. nLines]) {
		lines[j] = trim(lines[j]);
	}

	// Do not count comments && whitelines
	for (int i <- [0 .. nLines]) {
		lineLen = size(lines[i]);
		countThisLine = true;

		if (startsWith(lines[i], "//") || lineLen < 1) {
			countThisLine = false;
		}

		if (startsWith(lines[i], "/*")) { // TO DO: Find /* in middle of code.
			countThisLine = false;
			skippedLines = skipMultilineComment(lines, i);
			nSrcLines -= skippedLines;
		}

		if (countThisLine) {
			nSrcLines += 1;
		}
	}

	return nSrcLines;
}

// Count the lines of comment in a multiline comment.
int skipMultilineComment(lines, index) {
	lineCount = 0;

	while (!startsWith(lines[index], "*/") && !endsWith(lines[index], "*/")) {
		lineCount += 1;
		index += 1;
	}

	return lineCount;
}

// Give rating to volume.
int rateVolume(int kloc) {
	if (kloc < 67) {
		return RATING_DOUBLEPLUS; // ++
	} else if (kloc < 247) {
		return RATING_PLUS; // +;
	} else if (kloc < 666) {
		return RATING_O; // o
	} else if (kloc < 1311){
	   return RATING_MINUS; // -
	}

	return RATING_DOUBLEMINUS; // --
}

// Compute all lines of code in .java files.
int calcVolume(list[loc] javaFiles) {
	int fileCount = size(javaFiles);
	int volume = 0;

	for (int i <- [0 ..  fileCount]) {
		src = readFile(javaFiles[i]);
		volume += unitsize(src);
	}

	return volume;
}
