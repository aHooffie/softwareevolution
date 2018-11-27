module volume

import IO;
import List;
import String;
import util::FileSystem;
import metrics;

// Give rating to volume.
int rateVolume(int kloc) {
	if (kloc < 67) {
		return RATING_DOUBLEPLUS;
	} else if (kloc < 247) {
		return RATING_PLUS;
	} else if (kloc < 666) {
		return RATING_O;
	} else if (kloc < 1311){
	   return RATING_MINUS;
	}

	return RATING_DOUBLEMINUS;
}

// Compute all lines of code in .java files.
int unitsize (str src) {
	return size(trimSource(src));
}

// Compute all lines of code in .java files.
int calcVolume(list[loc] javaFiles) {
	return sum([ unitsize(readFile(file)) | file <- javaFiles ]);
}

list[str] trimSource(str src) {
	list[str] result = [];
	list[str] lines = split("\n", src);
	bool inMLC = false; 
	
	// Remove whitespace lines and SLC. 
	list[str] trimmed = [ trim(line) | line <- lines];
	trimmed = [ line | line <- trimmed, !(startsWith(line, "//")), size(line) > 0];
	
	// Loop over the rest of the source, checking for MLC.
	int nLines = size(trimmed);
	for (int i <- [0 .. nLines]) {
		str line = trimmed[i];
		
		// Check if a MLC starts on current line. 
		if (!inMLC) {
			if (startsWith(line, "/*")) {
				inMLC = true;
			} else if (contains(line, "/*")) {
				inMLC = true;
				result += line;
			}
		}

		// Check if a MLC ends on current line.
		if (inMLC) {
			if (endsWith(line, "*/")) {
				inMLC = false;
				continue;
			} else if (contains(line, "*/")) {
				inMLC = false;
			} else {
				continue;
			}
		}
		
		//		/* bla */ int x = 1; /* lol */   <-- in this case, this line will be skipped = bad
		// 		println("/* This will be handled correctly? */");
		result += line;
	}

	return result;
}