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
import util::Math;
import DateTime;

// This method prints out the trimmed methods in the java files given.
// This is to test whether the source trimmer is functioning as expected
void testSourceTrimmer(list[loc] javaFiles) {
	int nFiles = size(javaFiles);

	for (int i <- [0 .. nFiles]) {
		str src = readFile(javaFiles[i]);
		list[str] trimmed = trimSource(src); // gives a list of lines, no newline chars
		int nLines = size(trimmed);
		str srcTrimmed = "";
		for (int j <- [0 .. nLines]) {
			srcTrimmed += trimmed[j] + "\n";
		}
		println("\n-------- Trimmed <javaFiles[i]> --------");
		println(srcTrimmed);
	}
}

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
// Example invocation: main(|project://smallsql|);
void main(loc project) {
	t1 = now();
	println("Building M3 model for project <project> and getting list of Java files..");
	M3 m3Model = createM3FromEclipseProject(project);
	list[loc] javaFiles = [ f | f <- find(project, "java"), isFile(f) ];

	// testSourceTrimmer(javaFiles);

	int volume = calcVolume(javaFiles);
	int volumeRating = rateVolume(volume / 1000);

	list[real] unitSizePct = calcUnitSize(m3Model);
	int unitSize = rateUnitSize(unitSizePct);

	list[real] unitComplexityPct = calcUnitComp(m3Model, javaFiles);
	int unitComplexity =  rateUnitComp(unitComplexityPct);

	println("Calculating duplication percentage..");
	real dupPct = calcDuplication(m3Model);
	int dupRank = duplicationRank(dupPct);


	// Print the results
	println("============ Metrics ============");
	println("Volume: <volume> lines of code.");
	println("Volume rating: <giveRating(volumeRating)>");

	println("Unit size per category in %: <unitSizePct>.");
	println("Unit size rating: <giveRating(unitSize)>");

	println("Unit complexity per category in %: <unitComplexityPct>.");
	println("Unit complexity rating: <giveRating(unitComplexity)>");

	println("Duplication percentage: <dupPct>");
	println("Duplication rank: <giveRating(dupRank)>");

	//int stability = 1; // unit testing
	int analysability = (volume + dupRank + unitSize) / 3; // + unit testing
	int changeability = (unitComplexity + dupRank) / 2;
	int testability = (unitComplexity + unitSize) / 2; // + unit testing

	// overall maintainability is an average of everything
	real maintainability = toReal(volumeRating  + unitSize + unitComplexity + dupRank) / 4.0; // + unit testing

	println("\n============ Scores ============");

	println("Analysability rating: <giveRating(analysability)>");
	println("Changeability rating: <giveRating(changeability)>");
	println("Stability rating: N/A (depends on unit testing metric which we have not calculated)");
	println("Testability rating: <giveRating(testability)>");
	println("Maintainability (overall): <giveRating(round(maintainability))>");

	t2 = now() - t1;
	println("\nDone after <t2>");
}

