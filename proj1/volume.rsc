module volume

import IO;
import List;
import String;
import util::FileSystem;

// Returns the number of source line codes of all Java-files in a folder.
// Ignores lines with only comments or whitelines.
// NOTE: assumes that all source files use "\n" line endings, not "\r\n" !
int unitsize (src) {
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
str rateVolume(kloc) {
	if (kloc < 67) {
		return "++";
	} else if (kloc < 247) {
		return "+";
	} else if (kloc < 666) {
		return "o";
	} else if (kloc < 1311){
	 return "-";
	} else {
		return "--";
	}
}

// Compute all lines of code in .java files.
// |project://JavaTest| 
void main(folder) {
	javaFiles = [ f | f <- find(folder, "java"), isFile(f) ];
	int fileCount = size(javaFiles);
	int volume = 0;
	
	for (int i <- [0 ..  fileCount]) {
		src = readFile(javaFiles[i]);
		volume += unitsize(src);
	}
	
	println("Total volume: <volume> lines of code.");
	println("Volume Rating: <rateVolume(volume / 1000)>");
}