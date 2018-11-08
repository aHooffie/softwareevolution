module main

import IO;
import List;
import Set;
import String;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

// Returns the number of source line codes of a method (disregars empty lines and singleline comments (//)
// NOTE: assumes that all source files use "\n" line endings, not "\r\n" !
int unitsize(src) {
	int nSrcLines = 0;
	println("SOURCE: <src>");

	// 1. Split the entire source code string into lines.
	lines = split("\n", src);
	println("LINES: <lines>");

	// Iterate over each line of the method
	int nLines = size(lines);
	for (int i <- [0 .. nLines]) {
		lineSrc = lines[i];
		// Trim leading and trailing whitespace
		lineLen = size(lineSrc);
		trimmed = trim(lineSrc);
		countThisLine = true;
		// Do not count comments
		if (startsWith(trimmed, "//") || size(trimmed) < 1) {
			countThisLine = false;
		}

		if (countThisLine) {
			nSrcLines += 1;
		}
		//println("Line <i> trimmed: <trimmed> - count:<nSrcLines>");
	}

	return nSrcLines;
}

void main () {
	myModel = createM3FromEclipseProject(|project://simpletest|);
	//println(myModel);

	//int numberOfClasses(loc cl, M3 model) = size([ c | c <- model.containment[cl], isClass(c)]);
	//map[loc class, int classCount] numberOfClassesTotal = (cl:numberOfClasses(cl, myModel) | <cl,_> <- myModel.containment, isClass(cl));
	//println(numberOfClassesTotal.classCount);


	// Print # of methods of classes in JavaTest.java
	int numberOfMethods(loc cl, M3 model) = size([ m | m <- model.containment[cl], isMethod(m)]);
	map[loc class, int methodCount] numberOfMethodsPerClass = (cl:numberOfMethods(cl, myModel) | <cl,_> <- myModel.containment, isClass(cl));
	println(numberOfMethodsPerClass.methodCount);

	methodsx = toList(methods(myModel));
	nmethods = size(methodsx);
	println("Number of methods: <nmethods>");

	int totalUnitSize = 0;
	for(int i <- [0 ..  nmethods]) {
		println("i:<i>, methodName: <methodsx[i]>");
		src = readFile(methodsx[i]);
		//println("SOURCE: <src>");
		totalUnitSize += unitsize(src);
	}

	println("Total Unit Size: <totalUnitSize>");
}

