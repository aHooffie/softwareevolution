module unitcomplexity

import IO;
import List;
import Set;
import String;

import util::FileSystem;
import lang::java::m3::AST;
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

// Calculate unit complexity for a certain Eclipse Project.
list[real] calcUnitComp(folder) {
	list[real] categories = [0.0, 0.0, 0.0, 0.0];
	int risks = 0;	

	// Get all Java files from the project.
	javaFiles = [ f | f <- find(folder, "java"), isFile(f) ];
	int fileCount = size(javaFiles);
	 
	for (int i <- [0 .. fileCount]) {
		// Create an AST of each file. 
		Declaration ast = createAstFromFile(javaFiles[i], true);
		
		// Calculate per method the risk and add the amount of lines to corresponding category.
		visit(ast) {
			case \method(_, _, _, _, impl): {
				iprintln(impl);
				risks = calcCC(impl);
				categories = categorizeUnitRisk(risks, 10, categories); // TO DO: Calculate method lines.
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