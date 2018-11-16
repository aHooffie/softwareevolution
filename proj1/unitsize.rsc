module unitsize

import IO;
import List;
import Set;
import String;
import util::FileSystem;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import volume;

// Add the amount of lines to the right category of method sizes.
list[real] calcUnitSize(nlines, categories) {
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

// Ugly as fuck. Works for now.
int rateUnitSize(categories) {
	if (categories[3] == 0 && categories[2] == 0) {
		if (categories[1] <= 25) {
			return 4;
		} 
	}
	
	if (categories[3] == 0 && categories[2] <= 5) {
		if (categories[1] <= 30) {
			return 3;
		}
	}
	
	if (categories[3] == 0 && categories[2] <= 10) {
		if (categories[1] <= 40) {
			return 2;
		}
	}
	
	if (categories[3] <= 5 && categories[2] <= 15) {
		if (categories[1] <= 50) {
			return 1;
		}
	}		
		
	return 0;		
}

// duplicates: 967.
list[real] calcUnitSize(folder) {
	list[real] categories = [0.0, 0.0, 0.0, 0.0];

	// Get all methods from the project.
	myModel = createM3FromEclipseProject(folder);	
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