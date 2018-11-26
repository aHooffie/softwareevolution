module unitsize

import IO;
import List;
import Set;
import String;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::FileSystem;

import metrics;
import volume;

// Add the amount of lines to the right category of method sizes.
list[real] calcUnitSize(int nlines, list[real] categories) {
	if (nlines <= 15) {
		categories[0] += nlines;
	} else if (nlines <= 30) {
		categories[1] += nlines;
	} else if (nlines <= 60) {
		categories[2] += nlines;
	} else {
		categories[3] += nlines;
	}

	return categories;
}

// Max. percentages per rating (found in reader).
// ++ = [3] = 0, [2] = 0, [1] <= 25%, [0] >= 75%
// + = [3] = 0, [2] = 5, [1] = 30%, [0] >
// o = [3] = 0, [2] = 10, [1] = 40, [0]>
// - = [3] = 5, [2] = 15, [1] = 50, [0]>
// -- = REST

// Method to rate the unit size based on the risk profile percentages, SIG article (p. 6). 
int rateUnitSize(list[real] categories) {
	if (categories[3] == 0 && categories[2] == 0 && categories[1] <= 25) {
		return RATING_DOUBLEPLUS;
	}

	if (categories[3] == 0 && categories[2] <= 5 && categories[1] <= 30) {
		return RATING_PLUS;
	}

	if (categories[3] == 0 && categories[2] <= 10 && categories[1] <= 40) {
		return RATING_O;
	}

	if (categories[3] <= 5 && categories[2] <= 15 && categories[1] <= 50) {
		return RATING_MINUS;
	}

	return RATING_DOUBLEMINUS;
}

list[real] calcUnitSize(M3 myModel) {
	list[real] categories = [0.0, 0.0, 0.0, 0.0];

	// Get all methods from the project.
	methodsx = toList(methods(myModel));
	nmethods = size(methodsx);

	// Calculate lines per method. Put them in the right category (<15, <30, <60, >60 lines).
	for (int i <- [0 .. nmethods]) {
		src = readFile(methodsx[i]);
		categories = calcUnitSize(unitsize(src), categories);
	}

	// Calculate percentages.
	totalLines = sum(categories);
	if (totalLines != 0) {
		for (int k <- [0 .. 4]) {
			categories[k] = (categories[k] * 100) / totalLines;
		}
	}

	return categories;
}
