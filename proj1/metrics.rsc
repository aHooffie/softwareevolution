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
	list[real] unitSize = calcUnitSize(folder);
	list[real] unitComplexity = calcUnitComp(folder);
	
	// Print the corresponding rating. 	
	iprintln("Total volume: <volume> lines of code.");
	iprintln("Volume Rating: <giveRating(rateVolume(volume / 1000))>");
	
	iprintln("Unit size per category in %: <unitSize>.");
	iprintln("Unit size rating: <giveRating(rateUnitSize(unitSize))>");	
	
	iprintln("Unit complexity per category in %: <unitComplexity>.");
	iprintln("Unit complexity rating: <giveRating(rateUnitComp(unitComplexity))>");		
	
	// 	

}