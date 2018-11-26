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
map[str, int] mapMethods(M3 m3Model) {
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


/* Returns a tuple <foundClassPath, classPath>
   This method is calle for each Java file in the Eclipse project.
   Given a method name, a java filename and our map that maps from Java method to SLOC, try to construct the
   filepath which exists in the map. The reason we have to do this is a bit complicated. Basically,
   when we are getting a list of java files, they may not have the same "base path" as when we are getting a list of methods.
   So we have to try to match by starting with the full path and cutting off parts of it until we find a match.

   Example inputs:
   		javaFileName : |project://myProject/src/myProject/classOne.java|
        methodName   : helloWorld
        methodSLOC   :
            ("myProject/classOne/helloWorld":19,
	         "myProject/classOne/main":37,
	         "myProject/classTwo/coolMethod":11,
	         "myProject/classTwo/bestMethod":15)

   In this case, notice that the javaFileName has a longer base path than the paths in methodSLOC.
   So we need to find the right substring of javaFileName which exists in the map.
   So start at the longest path with the original javaFileName: "myProject/src/myProject/classOne/helloWorld",
   then cut off one part at a time until we find a match in methodSLOC.
   In this case, we want to return <true, myProject/classOne>
   because "myProject/classOne" is the base path in the methodSLOC.
   Then, we can use this path for other methods in the same file.
*/
tuple[bool, str] getClassPath(str javaFileName, str methodName, map[str, int] methodSLOC) {
	str orig = javaFileName;
	int ind = size("project://");
	int endInd = findFirst(orig, ".java|");
	str s = substring(orig, ind, endInd);
	str classPath = "?";
	bool foundClassPath = false;

	while (true) {
		str toTry = s+"/<methodName>";
		try {
			// see if this path is in the map, statement below with raise exception if it doesn't exist
			methodSLOC[toTry];
			classPath = s; // ok, it worked
			foundClassPath = true;
			break;
		} catch NoSuchKey(a): {
			t = findFirst(s, "/");
			if (t == -1) {
				println("Could not find SLOC for method <orig>/<methodName>, possibly a method inside a method..");
				break;
			}
			// Skip past the first / and try next guess
			s = substring(s, t+1);
		}
	}

	return <foundClassPath, classPath>;
}


// I don't quite understand what you are doing here..
// Possible to split this somehow still?
list[real] visitMethod(list[real] categories, map[str, int] methodSLOC, list[loc] javaFiles, int risks, int fileCount) {
	for (int i <- [0 .. fileCount]) {
		Declaration ast = createAstFromFile(javaFiles[i], true);
		str classPath = "?";
		bool foundClassPath = false;

		// Calculate per method the risk and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, methodName, _, _, impl): {
				if (!foundClassPath) {
					<foundClassPath,classPath> = getClassPath("<javaFiles[i]>", methodName, methodSLOC);
					if (!foundClassPath) {
						// it seems like we tried a method inside a method, so try next method in this file
						continue;
					}
				}

				// in case of a method defined inside a method, we should disregard this case and not count it because it will be counted by the parent method.
				int sloc = 0;
				try {
					sloc = methodSLOC[classPath+"/<methodName>"];
				} catch NoSuchKey(a): {
					println("Found possible method inside another method: <methodName> - file: <javaFiles[i]> - key val: <classPath+methodName>");
					continue;
				}

				risks = calcCC(impl);
				categories = categorizeCC(risks, sloc, categories);
			}
		}
	}

	return categories;
}

// Calculate unit complexity for a certain Eclipse Project.
list[real] calcUnitComplexity(M3 m3Model, list[loc] javaFiles) {
	int risks = 0;
	int fileCount = size(javaFiles);
	list[real] categories = [0.0, 0.0, 0.0, 0.0];

	// Map all methods to their respective SLOC.
	map[str, int] methodSLOC = mapMethods(m3Model);

	// Visit the methods and calculate their risk profile per category.
	categories = visitMethod(categories, methodSLOC, javaFiles, risks, fileCount);

	// Calculate percentages per category.
	totalLines = sum(categories);
	if (totalLines != 0) {
		for (int k <- [0 .. 4]) {
			categories[k] = (categories[k] * 100) / totalLines;
		}
	}

	return categories;
}
