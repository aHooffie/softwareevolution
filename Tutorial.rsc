module Tutorial

import IO;
import List;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

void main () {
	myModel = createM3FromEclipseProject(|project://JavaTest|);
	//println(myModel);	

	//int numberOfClasses(loc cl, M3 model) = size([ c | c <- model.containment[cl], isClass(c)]);
	//map[loc class, int classCount] numberOfClassesTotal = (cl:numberOfClasses(cl, myModel) | <cl,_> <- myModel.containment, isClass(cl));
	//println(numberOfClassesTotal.classCount);


	// Print # of methods of classes in JavaTest.java
	int numberOfMethods(loc cl, M3 model) = size([ m | m <- model.containment[cl], isMethod(m)]);
	map[loc class, int methodCount] numberOfMethodsPerClass = (cl:numberOfMethods(cl, myModel) | <cl,_> <- myModel.containment, isClass(cl));
	println(numberOfMethodsPerClass.methodCount);

}
