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

// global constants returned by rating functions in other modules
public int RATING_DOUBLEMINUS = 1;
public int RATING_MINUS = 2;
public int RATING_O = 3;
public int RATING_PLUS = 4;
public int RATING_DOUBLEPLUS = 5;

str giveRating(int rating) {
	if (rating == RATING_DOUBLEMINUS) {
		return "--";
	} else if (rating == RATING_MINUS) {
		return "-";
	} else if (rating == RATING_O) {
		return "o";
	} else if (rating == RATING_PLUS) {
		return "+";
	} else if (rating == RATING_DOUBLEPLUS) {
		return "++";
	} else {
		throw "Unexpected rating: <rating>";
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
	println("\n============ Metrics ============");
	println("Volume: <volume> lines of code.");
	println("Volume rating: <giveRating(volumeRating)>");

	//println("Unit size per category in %: <unitSizePct>.");
	println("Unit size risk profile:");
	println("    \<= 15 lines of code:   <unitSizePct[0]> %");
	println("    \<= 30 lines of code:   <unitSizePct[1]> %");
	println("    \<= 60 lines of code:   <unitSizePct[2]> %");
	println("    \>  60 lines of code:   <unitSizePct[3]> %");
	println("Unit size rating: <giveRating(unitSize)>");

	//println("Unit complexity per category in %: <unitComplexityPct>.");
	println("Unit complexity risk profile:");
	println("   simple,       without much risk (CC 1-10):     <unitComplexityPct[0]> %");
	println("   more complex, moderate risk     (CC 11-20):    <unitComplexityPct[1]> %");
	println("   complex,      high risk         (CC 21-50):    <unitComplexityPct[2]> %");
	println("   untestable,   very high risk    (CC \>50):      <unitComplexityPct[3]> %");
	println("Unit complexity rating: <giveRating(unitComplexity)>");

	println("Duplication percentage: <dupPct>");
	println("Duplication rank: <giveRating(dupRank)>");

	//int stability = 1; // unit testing
	int analysability = round(toReal(volumeRating + dupRank + unitSize) / 3.0); // + unit testing
	int changeability = round(toReal(unitComplexity + dupRank) / 2.0);
	int testability = round(toReal(unitComplexity + unitSize) / 2.0); // + unit testing

	// overall maintainability is an average of everything
	real maintainability = toReal(volumeRating  + unitSize + unitComplexity + dupRank) / 4.0; // + unit testing

	println("\n============ Scores ============");
	println("Analysability rating:      <giveRating(analysability)> (volume + duplication + unitsize (+unittesting))");
	println("Changeability rating:      <giveRating(changeability)> (complexity + duplication)");
	println("Stability rating:          N/A (relies solely on unit testing metric which we have not calculated)");
	println("Testability rating:        <giveRating(testability)> (complexity + unitsize (+unittesting))");
	println("Maintainability (overall): <giveRating(round(maintainability))> (volume + complexity + duplication + unitsize (+unittesting))");

	t2 = now() - t1;
	println("\nOperation completed in <t2.minutes>m <t2.seconds>s <t2.milliseconds>ms");
}

