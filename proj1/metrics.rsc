module metrics

import DateTime;
import IO;
import List;
import Set;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::FileSystem;
import util::Math;
import util::Resources;

import duplicatedetect;
import unitcomplexity;
import unitsize;
import volume;

// Global constants returned by rating functions in other modules.
public int RATING_DOUBLEMINUS = 1;
public int RATING_MINUS = 2;
public int RATING_O = 3;
public int RATING_PLUS = 4;
public int RATING_DOUBLEPLUS = 5;

// Test method to print out the trimmed methods in the java files given.
void testSourceTrimmer(list[loc] javaFiles) {
	int nFiles = size(javaFiles);

	for (int i <- [0 .. nFiles]) {
		str src = readFile(javaFiles[i]);
		str srcTrimmed = "";
		list[str] trimmed = trimSource(src); // gives a list of lines, no newline chars
		int nLines = size(trimmed);
		
		for (int j <- [0 .. nLines]) {
			srcTrimmed += trimmed[j] + "\n";
		}
		
		println("\n-------- Trimmed <javaFiles[i]> --------");
		println(srcTrimmed);
	}
}

// Method to pretty print the rating.
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

	//testSourceTrimmer(javaFiles);

	int volume = calcVolume(javaFiles);
	int volumeRating = rateVolume(volume / 1000);

	list[real] unitSizePct = calcUnitSize(m3Model);
	int unitSize = rateUnit(unitSizePct);

	list[real] unitComplexityPct = calcUnitComp(m3Model, javaFiles);
	int unitComplexity =  rateUnit(unitComplexityPct);

	//println("Calculating duplication percentage..");
	real dupPct = calcDuplication(m3Model);
	int dupRank = duplicationRank(dupPct);

	// Print all results.
	println("\n============ Metrics ============");
	println("Volume: <volume> lines of code.");
	println("Volume rating: <giveRating(volumeRating)>.");

	println("Unit size risk profile:");
	println("    \<= 15 lines of code:   <unitSizePct[0]> %.");
	println("    \<= 30 lines of code:   <unitSizePct[1]> %.");
	println("    \<= 60 lines of code:   <unitSizePct[2]> %.");
	println("    \>  60 lines of code:   <unitSizePct[3]> %.");
	println("Unit size rating: <giveRating(unitSize)>.");

	println("Unit complexity risk profile:");
	println("   simple,       without much risk (CC 1-10):     <unitComplexityPct[0]> %.");
	println("   more complex, moderate risk     (CC 11-20):    <unitComplexityPct[1]> %.");
	println("   complex,      high risk         (CC 21-50):    <unitComplexityPct[2]> %.");
	println("   untestable,   very high risk    (CC \>50):      <unitComplexityPct[3]> %.");
	println("Unit complexity rating: <giveRating(unitComplexity)>.");

	println("Duplication percentage: <dupPct>.");
	println("Duplication rank: <giveRating(dupRank)>.");

	int analysability = round(toReal(volumeRating + dupRank + unitSize) / 3.0);
	int changeability = round(toReal(unitComplexity + dupRank) / 2.0);
	int testability = round(toReal(unitComplexity + unitSize) / 2.0);
	int maintainability = round(toReal(volumeRating  + unitSize + unitComplexity + dupRank) / 4.0);

	println("\n============ Scores ============");
	println("Analysability rating:      <giveRating(analysability)> (volume + duplication + unitsize).");
	println("Changeability rating:      <giveRating(changeability)> (complexity + duplication).");
	println("Testability rating:        <giveRating(testability)> (complexity + unitsize).");
	println("Stability rating:          N/A (relies solely on the unit testing, which we have not calculated).");	
	println("Maintainability (overall): <giveRating(maintainability)> (volume + complexity + duplication + unitsize).");

	t2 = now() - t1;
	println("\nOperation completed in <t2.minutes>m <t2.seconds>s <t2.milliseconds>ms");
}