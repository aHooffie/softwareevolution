module metrics

import IO;
import Set;
import List;
import unitsize;
import unitcomplexity;
import volume;
import duplicatedetect;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::Resources;
import util::FileSystem;

str giveRating(int rating) {
	if (rating == 0) {
		return "--";
	} else if (rating == 1) {
		return "-";
	} else if (rating == 2) {
		return "o";
	} else if (rating == 3) {
		return "+";
	} else {
		return "++";
	}
}

// Entry point, starts calculations of all relevant metrics
void main(loc project) {
	M3 m3Model = createM3FromEclipseProject(project);
	list[loc] javaFiles = [ f | f <- find(project, "java"), isFile(f) ];
	//println("Project Java files: <javaFiles>");
	
	// Test code to check whether comment stripping works properly - prints out trimmed methods
	/*
	for (int i <- [0 .. size(javaFiles)]) {
		trimmed = trimSource(readFile(javaFiles[i]));
		println("TRIMMED <javaFiles[i]>: <trimmed>");
	}
	return; */

	int volume = calcVolume(javaFiles);
	println("Total volume: <volume> lines of code. Volume Rating: <(rateVolume(volume / 1000))>");
	
	list[real] unitSizePct = calcUnitSize(m3Model);
	int unitSize = rateUnitSize(unitSizePct);
	println("Unit size: <unitSize> - unit size pct: <unitSizePct>");

	list[real] unitComplexityPct = calcUnitComp(m3Model, javaFiles);
	
	println("unitComplexityPct: <unitComplexityPct>");
	
	int unitComplexity = 1337; //todo
	//int unitComplexity =  rateUnitComp(unitComplexityPct);
	
	println("Calculating duplication percentage..");
	real dupPct = calcDuplication(m3Model);
	println("Duplication percentage: <dupPct>");
	
	// Print the corresponding rating. 	
	
	
	
	println("Unit size per category in %: <unitSizePct>.");
	println("Unit size rating: <giveRating(unitSize)>");	
	
	println("Unit complexity per category in %: <unitComplexityPct>.");
	println("Unit complexity rating: <giveRating(unitComplexity)>");		
	
	int stability = 1; // unit testing
	int analysability = (volume + unitSize) / 2; // + stability + duplication 
	int changeability = (unitComplexity); // + duplication
	int testability = (unitComplexity + unitSize); // + stability

	println("Analysability rating: <giveRating(analysability)>");		
	println("Changeability rating: <giveRating(changeability)>");
	println("Stability rating: <giveRating(stability)>");
	println("Testability rating: <giveRating(testability)>");
}

