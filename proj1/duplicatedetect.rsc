module duplicatedetect

import IO;
import List;
import Set;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import String;
import util::Resources;
import util::FileSystem;
import util::Math;
import volume;
import DateTime;

bool debug = false;

// returns a list of trimmed lines (leading+trailing whitespace removed)
list[str] trimSource(str src) {
	list[str] lines = split("\n", src);
	// Iterate over each line of the method
	int nLines = size(lines);
	list[str] ret = [];
	for (int i <- [0 .. nLines]) {
		trimmed = trim(lines[i]); // removes leading+trailing whitespace
		if (!startsWith(trimmed, "//") && size(trimmed) > 0)
			ret += trimmed;
	}
	if (debug)
		println("TRIMMED METHOD: <ret>");
	return ret;
}

// a simple hash function used to hash list of strings
int customHash(list[str] lines) {
	int hash = 7;
	int nLines = size(lines);
	for (i <- [0..nLines]) {
		str line = lines[i];
		int lineLen = size(line);
		for (j <- [0..lineLen]) {
			hash = hash*9 + charAt(line, j);
		}
	}
	return hash;
}


// Given a m3 java model, find all Java methods, and find percentage of duplicate code
real calcDuplication(M3 myModel) {
	t1 = now();
	if (debug)
		println("calcDuplication()");


	methodsx = toList(methods(myModel));
	nmethods = size(methodsx);
	if (debug)
		println("Number of methods: <nmethods>");


	// Code duplication detection: Iterate through EVERY combination of 6 consecutive src lines and
	// compute a hash and store it. Then count number of identical hashes but remember to only count
	// 1 instance of duplicates as 1, not 2..

	if (debug)
		println("\n\nDuplicate detection =========\n");

	// In this first loop, we are computing hashes for every blocks of 6 lines of code.
	// We use a very basic hash function to do this
	map[tuple[int,int],int] hashes = ();
	int numMethodSLOC = 0;

	for(int i <- [0 ..  nmethods]) {
		if (debug)
			println("i:<i>, methodName: <methodsx[i]>");
		src = readFile(methodsx[i]);
		list[str] trimmed = trimSource(src); // returns a list of trimmed lines
		numLines = size(trimmed);

		if (debug) {
			println("Trimmed method: <trimmed>");
			println("Num lines: <numLines>");
		}

		numMethodSLOC += numLines;
		if (numLines < 6)
			continue; // we require 6 lines for duplicate blocks

		for (int j <- [0 .. numLines-6]) {
			// collect 6 lines from index j
			list[str] collection = trimmed[j..j+6];
			// We need to be able to uniquely identify where this block of lines start
			// i = method number, j = line number inside method
			tuple[int,int] location = <i,j>;
			hashes = hashes + (location: customHash(collection));
		}
	}

	if (debug)
		println("Made list of trimmed methods and hashes");

	// Important step: sort hashes so they appear chronologically e.g. blocks of code following each other in functions
	hashesList = sort([ <x, hashes[x]> | x <- hashes]);
	if (debug)
		println("Hashes sorted: <hashesList>");
	nHashes = size(hashesList);

	map[tuple[int,int],list[tuple[int,int]]] dupLocs = ();

	map[tuple[int,int], bool] countedLocs = ();

	int nDupeLines = 0;
	tuple[int,int] prevMatch = <-1,-1>;
	for (int i <- [0 .. nHashes]) {
		if (debug && i % 100 == 0)
			println("i<i> / <nHashes>");
		for (int j <- [0 .. nHashes]) {
			if (j == i)
				continue;

			// First, check that hash is the same
			if (hashesList[i][1] != hashesList[j][1])
				continue;

			//println("dupLocs: <dupLocs>");
			if (hashesList[j][0] in dupLocs) {
				if (hashesList[i][0] in dupLocs[hashesList[j][0]]) {
					if (debug)
						println("1 SKIPPING Loc <hashesList[i][0]> match at <hashesList[j][0]>");
					continue;
				}
			}

			if (hashesList[j][0] in countedLocs) {
				//println("2x! SKIPPING Loc <hashesList[i][0]> match at <hashesList[j][0]>");
				continue;
			}

			// To prevent counting this pair of duplicate lines again, we should save the locations
			// in some data structure
			if (hashesList[i][0] in dupLocs) {
				dupLocs[hashesList[i][0]] = dupLocs[hashesList[i][0]] + [hashesList[j][0]];
			} else {
				dupLocs[hashesList[i][0]] = [hashesList[j][0]];
				//println("ADDED MORE OMG");
			}

			int toAdd = 6;
			
			// NOTE: If previous line had a match, this means we should only add 1 extra line
			// check for overlap
			if (hashesList[j][0][1] == prevMatch[1]+1 && hashesList[j][0][0] == prevMatch[0] ) {
				toAdd = 1;
				//println("2NICE CASE TOADD1");
			}
			// Note: not sure why this case is necessary? First line in first method case?
			else if (hashesList[i][0][0] == hashesList[j][0][0]) { // same method
				int diff = (hashesList[j][0][1] - hashesList[i][0][1]);
				if (diff > 0 && diff <= 6) {
					//println("o!!!!!! k CASE TOADD1 diff: <diff>");
					toAdd = 1;
				}
			}

			nDupeLines += toAdd;
			countedLocs[hashesList[j][0]] = true;
			prevMatch = hashesList[j][0];
			if (debug)
				println("method <methodsx[hashesList[i][0][0]]> i:<i>,j:<j> Loc <hashesList[i][0]> match at <hashesList[j][0]> toAdd=<toAdd>  method2: <methodsx[hashesList[j][0][0]]>");
		}
	}

	
	real pct = toReal(nDupeLines)/toReal(numMethodSLOC) * 100.0;
	if (debug) {
		println("NDUpeLines: <nDupeLines>");
		println("numMethodSLOC: <numMethodSLOC>");
		println("Duplication percentage: <pct>");
	}
	
	t_end = now();
	
	dur = t_end - t1;
	println("Duration taken by duplication code: <dur>");
	return pct;
}

