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

	println("Project Java files: <javaFiles>");

	int volume = calcVolume(javaFiles);

	list[real] unitSizePct = calcUnitSize(m3Model);
	int unitSize = rateUnitSize(unitSizePct);
	println("Unit size: <unitSize> - unit size pct: <unitSizePct>");

	list[real] unitComplexityPct = calcUnitComp(m3Model, javaFiles);

	iprintln("unitComplexityPct: <unitComplexityPct>");

	//int unitComplexity =  rateUnitComp(unitComplexityPct);

	println("Calculating duplication percentage..");
	real dupPct = calcDuplication(m3Model);
	println("Duplication percentage: <dupPct>");

	// Print the corresponding rating.

	iprintln("Total volume: <volume> lines of code.");
	iprintln("Volume Rating: <giveRating(rateVolume(volume / 1000))>");

	iprintln("Unit size per category in %: <unitSizePct>.");
	iprintln("Unit size rating: <giveRating(unitSize)>");

	iprintln("Unit complexity per category in %: <unitComplexityPct>.");
	iprintln("Unit complexity rating: <giveRating(unitComplexity)>");

	int stability = 1; // unit testing
	int analysability = (volume + unitSize) / 2; // + stability + duplication
	int changeability = (unitComplexity); // + duplication
	int testability = (unitComplexity + unitSize); // + stability

	iprintln("Analysability rating: <giveRating(analysability)>");
	iprintln("Changeability rating: <giveRating(changeability)>");
	iprintln("Stability rating: <giveRating(stability)>");
	iprintln("Testability rating: <giveRating(testability)>");
}

