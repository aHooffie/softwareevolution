module metrics


import IO;
import List;
import Set;
import String;
import util::FileSystem;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import volume;
import unitsize;


// Compute all lines of code in .java files.
// |project://JavaTest| 
void main(folder) {
	calculateUnitSize(folder);
	calculateVolume(folder);
}