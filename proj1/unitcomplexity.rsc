module unitcomplexity

import IO;
import List;
import Set;
import String;

import util::FileSystem;
import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import metrics;
import unitsize;
import volume;

// Add the amount of lines to the correct risk category.
list[real] categorizeCC(int risks, int nlines, list[real] categories) {
	if (risks <= 10) {
		categories[0] += nlines;
	} else if (risks <= 20) {
		categories[1] += nlines;
	} else if (risks <= 50) {
		categories[2] += nlines;
	} else {
		categories[3] += nlines;
	}

	return categories;
}

// Calculate the risk of a method, based on Landman's article.
int calcCC(Statement impl) {
	int rating = 1;

	visit(impl) {
		case \case(_): rating += 1;
		case \catch(_, _): rating += 1;
		case \conditional(_, _, _): rating += 1;
		case \do(_, _): rating += 1;
		case \for(_, _, _, _): rating += 1;
		case \for(_, _, _): rating += 1;
		case \foreach (_, _, _): rating += 1;
		case \if(_, _, _): rating += 1;
		case \if(_, _): rating += 1;
		case \while(_, _): rating += 1;
		case \infix(_, "&&", _): rating += 1;
		case \infix(_, "||", _): rating += 1;
	}

	return rating;
}

// This turns a method location like |java+method:///simpletest/coolclass/looper()|
// into the string "simpletest/coolclass/looper".
// Or another input: |java+method:///org/hsqldb/ParserBase/readDateTimeIntervalLiteral(org.hsqldb.Session)|
// --> org/hsqldb/ParserBase/readDateTimeIntervalLiteral
str cleanMethodName(loc name) {
	str s = "<name>";
	str out = substring(s, size("|java+method:///"), findFirst(s, "("));
	return out;
}

// Build up a map of all the methods in the files, mapping them from javafile to SLOC.
map[str, int] calculateMethods(M3 m3Model) {
	map[str, int] methodSLOC = ();
	methodsx = toList(methods(m3Model));
	int nMethods = size(methodsx);
	
	for (int i <- [0 .. nMethods]) {
		int methodSize = unitsize(readFile(methodsx[i]));
		str cleanName = cleanMethodName(methodsx[i]);
		methodSLOC[cleanName] = methodSize;
	}
	
	return methodSLOC;
}

// I don't quite understand what you are doing here..  
list[real] visitMethod(str methodName, loc javaFile, Statement impl, map[str, int] methodSLOC, list[real] categories) {
	int sloc = 0;
	
	//str classPath = getClassPath(javaFiles[i]);
	str classPath = "?";
	
	if (classPath == "?") {
		orig = "<javaFile>";
		ind = size("project://");
		endInd = findFirst(orig, ".java|");
		s = substring(orig, ind, endInd);

		bool bad = false;
		while (true) {
			str toTry = s+"/<methodName>";
			try {
				sloc = methodSLOC[s+"/<methodName>"];
				classPath = s;
				break;
			} catch NoSuchKey(a): {
				t = findFirst(s, "/");
				if (t == -1) {
					println("Could not find SLOC for method <orig>/<methodName>, possibly a method inside a method..");
					bad = true;
					break;
				}
				// Skip past the first /
				s = substring(s, t+1);
			}
		}
		if (bad) {
			// Possibly, we tried a method inside a method, so try next method in this file..
			continue;
		}
	}

	// NOTE: in case of a method defined inside a method, we should disregard this.
	try {
		sloc = methodSLOC[classPath+"/<methodName>"];
	} catch NoSuchKey(a): {
		println("Found possible method inside another method: <methodName> - file: <javaFile> - key val: <classPath+methodName>");
		//return [];
		continue;
	}

	risks = calcCC(impl);
	categories = categorizeCC(risks, sloc, categories);
	
	return categories;
}


// Calculate unit complexity for a certain Eclipse Project.
list[real] calcUnitComp(M3 m3Model, list[loc] javaFiles) {
	int risks = 0;
	int fileCount = size(javaFiles);
	list[real] categories = [0.0, 0.0, 0.0, 0.0];
	
	// Map all methods to their respective SLOC. 
	map[str, int] methodSLOC = calculateMethods(m3Model);

	for (int i <- [0 .. fileCount]) {
		Declaration ast = createAstFromFile(javaFiles[i], true);

		// Calculate per method the risk and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, methodName, _, _, impl): { 
				categories = visitMethod(methodName, javaFiles[i], impl, methodSLOC, categories);
			}
		}
	}

	// Calculate percentages per category.
	totalLines = sum(categories);
	if (totalLines != 0) {
		for (int k <- [0 .. 4]) {
			categories[k] = (categories[k] * 100) / totalLines;
		}
	}

	return categories;
}
