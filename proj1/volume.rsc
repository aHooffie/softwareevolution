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

int unitsize (str src) {
	return size(trimSource(src));
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

// Compute all lines of code in .java files.
int calcVolume(list[loc] javaFiles) {
	return sum([ unitsize(readFile(file)) | file <- javaFiles ]);
}


//// return <newInMLC, countThisLine> tuple
//// NOTE!! Does not handle when /* or */ are inside string quotes ("/*") ?!
//tuple[bool,bool] skipMultilineComments(str trimmed, bool inMLC) {
//	bool count_line = false;
//
//	if (!inMLC) {
//		if (startsWith(trimmed, "/*")) {
//			inMLC = true;
//		}
//		else if (contains(trimmed, "/*")) {
//			inMLC = true;
//			// this line did not start with /*, so it had some code, so count it
//			count_line = true;
//		}
//	}
//
//	// try to skip to */ if in a multilinecomment
//	if (inMLC) {
//		int ind;
//		str substr = trimmed;
//		while (true) {
//			ind = findFirst(substr, "*/");
//			//println("FindFirst substr: <substr>");
//			if (ind != -1 && ind == size(substr)-2) { // means that this line begins with /* and ends with a */ , with no code in the middle, so don't count this line
//				inMLC = false;
//				break;
//			}
//			else if (ind != -1) {
//				// ok, we found a */ that was not at the end of the string.
//				// Now check whether there is some code, or whether a new /* comment starts
//				// Skip past all/any whitespace
//				int j = ind+2; // jump past */
//				while (substr[j] == " " || substr[j] == "\t") {
//					j += 1;
//				}
//				substr = substring(substr, j);
//				int ind2 = findFirst(substr, "/*");
//				if (ind2 > 0 || ind2 == -1) {
//					// ok, means there was some code on this line, so count it!
//					count_line = true;
//					if (ind2 > 0)
//						inMLC = true;
//					break;
//				} else if (ind2 == 0) {
//					// It starts wtih a /* right away, so no code!
//					continue;
//				}
//			}
//			else { // ind == -1
//				// means we could not find any */
//				inMLC = true;
//				break;
//			}
//		}
//	} else {
//		// not in MLC
//		count_line = true;
//	}
//
//	return <inMLC,count_line>;
//}