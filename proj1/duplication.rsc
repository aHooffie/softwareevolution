module duplication

import IO;
import List;
import Map;
import String;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::Resources;
import util::FileSystem;
import util::Math;

import metrics;
import volume;

int rateDuplication(real dupPct) {
	if (dupPct <= 3.0) {
		return RATING_DOUBLEPLUS;
	} else if (dupPct <= 5.0) {
		return RATING_PLUS;
	} else if (dupPct <= 10.0) {
		return RATING_O;
	} else if (dupPct <= 20.0) {
		return RATING_MINUS;
	} else {
		return RATING_DOUBLEMINUS;
	}	
}

// Check how many lines should be added to dupLines (either 1 or 6) - e.g. is it part of a bigger block of duplication.
int checkCodeBlock(list[tuple[int file, int line]] locationDuplicates, tuple[int file, int line] currentLocation) {
	int nLines;
	
	tuple[int file, int line] previous = <currentLocation.file, currentLocation.line - 1>;	
	if (previous in locationDuplicates) {
		nLines = 1;
	} else  {
		nLines = 6;
	}
	
	return nLines;
}

int calcDuplication(list[loc] javaFiles) {
	// Filter all useless lines out of the javaFiles & all files < 6 lines.	
	list[list[str]] trimmedFiles = [ trimSource(readFile(file)) | file <- javaFiles ];
	list[list[str]] filteredFiles = [ file | file <- trimmedFiles, size(file) > 6];
	
	int nFiles = size(filteredFiles);
	int dupLines = 0;
	map[str, tuple[int file, int line]] hashes = ();
	list[tuple[int file, int line]] locationDuplicates = []; 				
	
	
	// Loop over all files. Map every 6 lines to their location.
	for (int i <- [0 .. nFiles]) {
		int nLines = size(filteredFiles[i]);
	
		for (int j <- [0 .. nLines - 6]) {
			str currentSelection = toString(filteredFiles[i][j .. j + 6]);
			tuple[int file, int line] currentLocation = <i,j>;			
			
			// Check if the current 6 lines have already occurred before.
			if (currentSelection in hashes) {
				locationDuplicates = locationDuplicates + currentLocation;
				dupLines += checkCodeBlock(locationDuplicates, currentLocation);
			} else {
				hashes[currentSelection] = currentLocation;
			}
		}
	}

	return dupLines;
}

