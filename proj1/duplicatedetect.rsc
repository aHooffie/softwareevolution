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

int debug = 0;


// a simple hash function used to hash list of strings
int customHash(list[str] lines) {
	int hash = 7;
	int nLines = size(lines);
	for (i <- [0..nLines]) {
		str line = lines[i];
		int lineLen = size(line);
		for (j <- [0..lineLen]) {
			hash = hash*11 + charAt(line, j);
		}
	}
	return hash;
}

int duplicationRank(real dupPct) {
	if (dupPct <= 3.0)
		return 4; // ++
	if (dupPct <= 5.0)
		return 3; // +
	if (dupPct <= 10.0)
		return 2; // o
	if (dupPct <= 20.0)
		return 1; // -

	return 0; // --
}

// Given a m3 java model, find all Java methods, and find percentage of duplicate code
real calcDuplication(M3 myModel) {
	t1 = now(); // timing

	if (debug > 0)
		println("========= calcDuplication() =========");


	methodsx = toList(methods(myModel));
	nmethods = size(methodsx);
	if (debug > 0)
		println("Number of methods: <nmethods>");


	// Code duplication detection: Iterate through EVERY combination of 6 consecutive src lines and
	// compute a hash and store it. Then count number of identical hashes but remember to only count
	// 1 instance of duplicates as 1, not 2..

	// In this first loop, we are computing hashes for every blocks of 6 lines of code.
	// We use a very basic hash function to do this. We also map hashes to locations to quickly find collissions later
	map[tuple[int,int],int] hashes = ();
	int totalSLOC = 0;

	map[int, list[tuple[int,int]]] hashToLocationsMap = ();

	for(int i <- [0 ..  nmethods]) {
		if (debug > 1)
			println("i:<i>, methodName: <methodsx[i]>");
		src = readFile(methodsx[i]);
		list[str] trimmed = trimSource(src); // returns a list of trimmed lines
		numLines = size(trimmed);

		if (debug > 1) {
			println("Num lines: <numLines>");
		}

		totalSLOC += numLines;
		if (numLines < 6)
			continue; // we require 6 lines for duplicate blocks

		for (int j <- [0 .. numLines-6]) {
			// collect 6 lines from index j
			list[str] collection = trimmed[j..j+6];
			// We need to be able to uniquely identify where this block of lines start
			// i = method number, j = line number inside method
			tuple[int,int] location = <i,j>;
			int hash = customHash(collection);
			hashes = hashes + (location: hash);

			if (hash in hashToLocationsMap) {
				hashToLocationsMap[hash] = hashToLocationsMap[hash] + location;
			} else {
				hashToLocationsMap[hash] = [location];
			}
		}
	}

	t2 = now();

	if (debug > 0)
		println("Made list of trimmed methods and hashes, duration: <t2-t1>");

	// Important step: sort hashes so they appear chronologically e.g. blocks of code following each other in functions
	hashesList = sort([ <x, hashes[x]> | x <- hashes]);
	if (debug > 1)
		println("Hashes sorted: <hashesList>");
	nHashes = size(hashesList);

	map[tuple[int,int],list[tuple[int,int]]] dupLocs = ();
	map[tuple[int,int], bool] countedLocs = ();

	dursum = duration(0,0,0,0,0,0,0);

	int nDupeLines = 0;
	tuple[int,int] prevMatch = <-1,-1>;

	for (int i <- [0 .. nHashes]) {
		if (debug > 0 && i % 1000 == 0)
			println("i<i> / <nHashes>");

		hi = hashesList[i];
		hi_0 = hi[0]; // location
		otherLocsSameHash = sort(hashToLocationsMap[hi[1]]);

		int nCollissions = size(otherLocsSameHash); // includes this current entry
		for (int j <- [0 .. nCollissions]) {
			hj_0 = otherLocsSameHash[j];
			if (hj_0 == hi_0) { // it's the same location
				//println("SKipped <hj_0> , <hi_0>");
				continue;
			}

			if (hj_0 in dupLocs) {
				if (hi_0 in dupLocs[hj_0]) {
					if (debug > 1)
						println("1 SKIPPING Loc <hashesList[i][0]> match at <hashesList[j][0]>");
					continue;
				}
			}

			if (hj_0 in countedLocs) {
				//println("2x! SKIPPING Loc <hi_0> match at <hj_0>");
				continue;
			}

			// To prevent counting this pair of duplicate lines again, we should save the locations
			// in some data structure
			if (hi_0 in dupLocs) {
				dupLocs[hi_0] = dupLocs[hi_0] + [hj_0];
			} else {
				dupLocs[hi_0] = [hj_0];
				//println("ADDED MORE OMG");
			}

			int toAdd = 6;

			// NOTE: If previous line had a match, this means we should only add 1 extra line
			// check for overlap
			if (hj_0[1] == prevMatch[1]+1 && hj_0[0] == prevMatch[0] ) {
				toAdd = 1;
				//println("2NICE CASE TOADD1");
			}
			// Note: not sure why this case is necessary? First line in first method case?
			else if (hi_0[0] == hj_0[0]) { // same method
				int diff = (hj_0[1] - hi_0[1]);
				if (diff > 0 && diff <= 6) {
					//println("o!!!!!! k CASE TOADD1 diff: <diff>");
					toAdd = 1;
				}
			}

			nDupeLines += toAdd;
			countedLocs[hj_0] = true;
			prevMatch = hj_0;
			if (debug > 1)
				println("meth1 <hashesList[i][0][0]> i:<i>, Loc <hashesList[i][0]> match at <hj_0> toAdd=<toAdd>  meth2: <hj_0[0]>");
		}
	}


	real pct = toReal(nDupeLines)/toReal(totalSLOC) * 100.0;
	if (debug > 0) {
		println("Number of duplicate lines: <nDupeLines>");
		println("Total source lines of code: <totalSLOC>");
		println("Duplication percentage: <pct>");
	}

	dur = now() - t1;
	println("Duration taken by duplication code: <dur> - SLOC: <totalSLOC> - Duplicate lines: <nDupeLines>");
	return pct;
}

