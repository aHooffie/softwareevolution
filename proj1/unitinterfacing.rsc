module unitinterfacing

import IO;
import List;
import Set;
import String;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::FileSystem;

import metrics;
import unitsize;
import volume;

// Add the amount of lines to the correct parameters category, based on SIG book.
list[real] categorizeParameters(int parameters, int nlines, list[real] categories) {
	if (parameters <= 2) {
		categories[0] += nlines;
	} else if (parameters <= 4) {
		categories[1] += nlines;
	} else if (parameters <= 6) {
		categories[2] += nlines;
	} else {
		categories[3] += nlines;
	}

	return categories;
}

// Calculate unit interfacing for a certain Eclipse Project ( = amount of params).
list[real] calcUnitInterfacing(list[loc] javaFiles) {
	list[real] categories = [0.0, 0.0, 0.0, 0.0];
	int fileCount = size(javaFiles);
	int params, sloc;	

	for (int i <- [0 .. fileCount]) {
		Declaration ast = createAstFromFile(javaFiles[i], true);

		// Calculate per method the amount of parameters and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, _, params, _, impl): {
				nparams = size(params);
				sloc = size(readFileLines(impl.src));
				categories = categorizeParameters(nparams, sloc, categories);
			}			
		}
	}

	// Calculate percentages per category.
	totalLines = sum(categories);
	if (totalLines != 0) {
		for (int k <- [0 .. 4]) {
			categories[k] = (categories[k] * 100) / totalLines;
		}
	}
	
	return categories;
}