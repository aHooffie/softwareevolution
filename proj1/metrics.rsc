module metrics

import IO;
import unitsize;
import unitcomplexity;
import volume;

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

// Compute all lines of code in .java files.
void main(folder) {
	int volume = calcVolume(folder);
	
	list[real] unitSizePct = calcUnitSize(folder);
	int unitSize = rateUnitSize(unitSizePct);

	list[real] unitComplexityPct = calcUnitComp(folder);
	int unitComplexity =  rateUnitComp(unitComplexityPct);
	
	// Print the corresponding rating. 	
	iprintln("Total volume: <volume> lines of code.");
	iprintln("Volume Rating: <giveRating(rateVolume(volume / 1000))>");
	
	iprintln("Unit size per category in %: <unitSizePct>.");
	iprintln("Unit size rating: <giveRating(unitSize)>");	
	
	iprintln("Unit complexity per category in %: <unitComplexityPct>.");
	iprintln("Unit complexity rating: <giveRating(unitComplexity)>");		
	
	int stability = 1 // unit testing
	int analysability = (volume + unitSize) / 2 // + stability + duplication 
	int changeability = (unitComplexity) // + duplication
	int testability = (unitComplexity + unitSize) // + stability

	iprintln("Analysability rating: <giveRating(analysability)>");		
	iprintln("Changeability rating: <giveRating(changeability)>");
	iprintln("Stability rating: <giveRating(stability)>");
	iprintln("Testability rating: <giveRating(testability)>");
}