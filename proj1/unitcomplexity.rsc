module unitcomplexity

import IO;
import List;
import Set;
import String;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import util::FileSystem;

import metrics;
import unitsize;
import volume;

// Add the amount of lines to the correct risk category, based on SIG paper.
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

// Calculate unit complexity for a certain Eclipse Project.
list[real] calcUnitComp(M3 m3Model, list[loc] javaFiles) {
	list[real] categories = [0.0, 0.0, 0.0, 0.0];
	int risks, sloc = 0;
	int fileCount = size(javaFiles);

	for (int i <- [0 .. fileCount]) {
		Declaration ast = createAstFromFile(javaFiles[i], true);

		// Calculate per method the risk and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, methodName, _, _, impl): {
				sloc = size(readFileLines(impl.src));
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