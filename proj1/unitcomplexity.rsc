module unitcomplexity

import IO;
import List;
import Set;
import String;

import util::FileSystem;
import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import unitsize;
import volume;
import metrics;

// https://pmd.github.io/latest/pmd_java_metrics_index.html#cyclomatic-complexity-cyclo
// https://www.theserverside.com/feature/How-to-calculate-McCabe-cyclomatic-complexity-in-Java
//    M = E − N + 2P,
//    E = the number of edges of the graph.
//    N = the number of nodes of the graph.
//    P = the number of connected components.
// Add the amount of lines to the correct risk category.
list[real] categorizeUnitRisk(int risks, int nlines, list[real] categories) {
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

// Calculate the risk of a method.
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

// This is so bad and hacky, turn a method location like
// |java+method:///simpletest/coolclass/looper()|
// into "simpletest/coolclass/looper"
// Or another input: |java+method:///org/hsqldb/ParserBase/readDateTimeIntervalLiteral(org.hsqldb.Session)|
// --> org/hsqldb/ParserBase/readDateTimeIntervalLiteral
str cleanMethodName(loc name) {
	str s = "<name>"; // e.g.  |java+method:///simpletest/coolclass/looper()|
	str out = substring(s, size("|java+method:///"), findFirst(s, "("));
	//println("Method <name> cleaned to <out>");
	return out;
}


// Calculate unit complexity for a certain Eclipse Project.
list[real] calcUnitComp(M3 m3Model, list[loc] javaFiles) {
	println("Calculating unit complexity..");
	list[real] categories = [0.0, 0.0, 0.0, 0.0];
	int risks = 0;
	int fileCount = size(javaFiles);

	// Build up a map, mapping from javafile to SLOC.
	methodsx = toList(methods(m3Model));
	int nMethods = size(methodsx);
	map[str,int] methodSLOC = ();
	for (int i <- [0 .. nMethods]) {
		int methodSize = unitsize(readFile(methodsx[i]));
		str cleanName = cleanMethodName(methodsx[i]);
		methodSLOC[cleanName] = methodSize;
	}

	//iprintln(methodSLOC);

	for (int i <- [0 .. fileCount]) {
		// Create an AST of each file.
		Declaration ast = createAstFromFile(javaFiles[i], true);
		//str classPath = getClassPath(javaFiles[i]);
		str classPath = "?";

		// Calculate per method the risk and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, methodName, _, _, impl): {
				int sloc = 0;
				// This is incredibly hacky and ugly, but the whole situation is problematic because we don't know where the path of a source file begins.. bla
				if (classPath == "?") {
					//println("!!!!!!!!!!!!\nFinding class path!!!!!");
					orig = "<javaFiles[i]>";
					ind = size("project://");
					endInd = findFirst(orig, ".java|");
					s = substring(orig, ind, endInd);

					bool bad = false;
					while (true) {
						str toTry = s+"/<methodName>";
						//println("Trying <toTry> ...");
						try {
							sloc = methodSLOC[toTry];
							//println("Ok, it worked: <s>");
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

				// NOTE: in case of a method defined inside a method, we should disregard this case and not count it because it will be counted by the parent method.
				try {
					sloc = methodSLOC[classPath+"/<methodName>"];
				} catch NoSuchKey(a): {
					println("Found possible method inside another method: <methodName> - file: <javaFiles[i]> - key val: <classPath+methodName>");
					//return [];
					continue;
				}

				risks = calcCC(impl);
				categories = categorizeUnitRisk(risks, sloc, categories);
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

int rateUnitComp(list[real] c) {
	// remember, c[0] is the "safe" category which doesnt matter here
	if (c[1] <= 25.0 && c[2] < 0.001 && c[3] < 0.001)
		return RATING_DOUBLEPLUS; // ++ rating

	if (c[1] <= 30.0 && c[2] <= 5.0 && c[3] < 0.001)
		return RATING_PLUS; // + rating

	if (c[1] <= 40.0 && c[2] <= 10.0 && c[3] <= 5.0)
		return RATING_O; // o rating

	if (c[1] <= 50.0 && c[2] <= 15.0 && c[3] <= 5.0)
		return RATING_MINUS;

	return RATING_DOUBLEMINUS; // -- rating
}
