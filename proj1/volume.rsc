module volume

import IO;
import List;
import String;
import util::FileSystem;
import metrics;

list[str] trimSourceOld(str src) {
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

// return <newInMLC, countThisLine> tuple
// NOTE!! Does not handle when /* or */ are inside string quotes ("/*") ?!
tuple[bool,bool] skipMultilineComments(str trimmed, bool inMLC) {
	bool count_line = false;

	if (!inMLC) {
		if (startsWith(trimmed, "/*")) {
			inMLC = true;
		}
		else if (contains(trimmed, "/*")) {
			inMLC = true;
			// this line did not start with /*, so it had some code, so count it
			count_line = true;
		}
	}

	// try to skip to */ if in a multilinecomment
	if (inMLC) {
		int ind;
		str substr = trimmed;
		while (true) {
			ind = findFirst(substr, "*/");
			//println("FindFirst substr: <substr>");
			if (ind != -1 && ind == size(substr)-2) { // means that this line begins with /* and ends with a */ , with no code in the middle, so don't count this line
				inMLC = false;
				/*line_ended_with_end_of_multilinecomment = true;
				break;*/
				//return <inMLC, true>;
				//count_line = true;
				break;
			}
			else if (ind != -1) {
				// ok, we found a */ that was not at the end of the string.
				// Now check whether there is some code, or whether a new /* comment starts
				// Skip past all/any whitespace
				int j = ind+2; // jump past */
				while (substr[j] == " " || substr[j] == "\t") {
					j += 1;
				}
				substr = substring(substr, j);
				int ind2 = findFirst(substr, "/*");
				if (ind2 > 0 || ind2 == -1) {
					// ok, means there was some code on this line, so count it!
					//ret += trimmed;
					//line_ended_with_end_of_multilinecomment = true;
					count_line = true;
					if (ind2 > 0)
						inMLC = true;
					break;
				} else if (ind2 == 0) {
					// It starts wtih a /* right away, so no code!
					continue;
				}
			}
			else { // ind == -1
				// means we could not find any */
				inMLC = true;
				break;
			}
		}
	} else {
		// not in MLC
		count_line = true;
	}


	return <inMLC,count_line>;
}

list[str] trimSource(str src) {
	list[str] lines = split("\n", src);
	// Iterate over each line of the method
	int nLines = size(lines);
	list[str] ret = [];
	bool inMLC = false; // in multi-line comment
	for (int i <- [0 .. nLines]) {
		str trimmed = trim(lines[i]); // removes leading+trailing whitespace

		if (startsWith(trimmed, "//"))
			continue;
		if (size(trimmed) < 1)
			continue;

		bool countThis;
		<inMLC,countThis> = skipMultilineComments(trimmed, inMLC);
		if (countThis)
			ret += trimmed;
	}

	return ret;
}

int unitsize (str src) {
	return size(trimSource(src));
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
