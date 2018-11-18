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

// https://pmd.github.io/latest/pmd_java_metrics_index.html#cyclomatic-complexity-cyclo
// https://www.theserverside.com/feature/How-to-calculate-McCabe-cyclomatic-complexity-in-Java

//    M = E − N + 2P,
//    E = the number of edges of the graph.
//    N = the number of nodes of the graph.
//    P = the number of connected components.

// Add the amount of lines to the correct risk category.
list[real] categorizeUnitRisk(risks, nlines, categories) {
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
str cleanMethodName(loc name) {
	str s = "<name>"; // e.g.  |java+method:///simpletest/coolclass/looper()|
	int i = 0;

	i += size("|java+method:///");

	str out = "";
	while (s[i] != "(") {
		out += s[i];
		i += 1;
	}

	return out;
}

// input: e.g.  |project://simpletest/src/simpletest/ayylmao.java|
// output       simpletest/ayylmao/
str getClassPath(loc projpath) {
	str s = "<projpath>";
	int i = findFirst(s, "src/");
	i += 4;

	out = "";

	while (true) {
		if (substring(s,i) == ".java|") {
			break;
		}
		out += s[i];
		i += 1;
	}
	out += "/";
	return out;
}

// Calculate unit complexity for a certain Eclipse Project.
list[real] calcUnitComp(M3 m3Model, javaFiles) {
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

	for (int i <- [0 .. fileCount]) {
		// Create an AST of each file.
		Declaration ast = createAstFromFile(javaFiles[i], true);
		str classPath = getClassPath(javaFiles[i]);

		// Calculate per method the risk and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, methodName, _, _, impl): {
				int sloc = 0;

				// NOTE: in case of a method defined inside a method, we should disregard this.
				try {
					sloc = methodSLOC[classPath+methodName];
				} catch NoSuchKey(a): {
					println("Found possible method inside method: <methodName> - file: <javaFiles[i]>");
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
