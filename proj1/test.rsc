module \test

import metrics;
import unitsize;
import volume;
import IO;

// Test suite for comment stripping utility.
// Use :test in rascal console to run tests.


// Basic multilinecomment example, should give 0 SLOC
test bool testCommentStrip1() {
	str s = "/************\n" +
			 "* comment  *\n" +
			 "***********/\n";
	return unitsize(s) == 0;
}

// Multiline comments: More advanced example, should return 1 SLOC.
test bool testCommentStrip2() {
	str s = "/* comment */ int x = 5;\n" +
			"// comment\n";
	return unitsize(s) == 1;
}

// Test multilinecomment after some code in same line
test bool testCommentStrip3() {
	str s = "int x = 5; /* comment */\n" +
			"// comment\n";
	return unitsize(s) == 1;
}

// Multiline comments in beginning and ending of a line that contains code.
test bool testCommentStrip4() {
	str s = "/* comment */ int x = 5; /* comment2 */\n" +
			"// comment\n";
	return unitsize(s) == 1;
}

// Test multilinecomment after some code in same line
test bool testCommentStrip5() {
	str s = "/* comment \n" +
			" * stuff */ int x =5;\n";
	return unitsize(s) == 1;
}

// Test multilinecomment after some code in same line
test bool testCommentStrip6() {
	str s = "/* comment \n" +
			" * stuff */ int x =5; /*lol*/ /* hehe */ /* test */\n";
	return unitsize(s) == 1;
}

test bool testCommentStrip7() {
	str s = "/* comment \n" +
			" * stuff */  /*lol*/ /* hehe */ /* test */\n";
	return unitsize(s) == 0;
}

test bool testCommentStrip8() {
	str s = "int x=1; /* stuff */  /*lol*/ /* hehe */ /* test */\n";
	return unitsize(s) == 1;
}

test bool testCommentStrip9() {
	str s1 = "/* stuff */  /*lol*/ /* hehe */ /* test */ int x = 2;\n";
	str s2 = "/* stuff */  /*lol*/ /* hehe */ /* test */           \n";
	return unitsize(s1) == 1 && unitsize(s2) == 0;
}


// More advanced example, should return 1 SLOC.
test bool testCommentStrip10() {
	str s = "/* comment */ int x = 5;\n" +
			"// comment\n";
	return unitsize(s) == 1;
}


// Basic single-line comment example, has 1 SLOC
test bool testCommentStrip11() {
	str s = "// comment\n" +
			 "int x = 5;\n" +
			 "// comment2\n";
	return unitsize(s) == 1;
}

// Test weird longer /*** **/ comments with more stars
test bool testCommentStrip12() {
	str s = "// comment\n" +
			 "/*********/ int x = 5; /** comment /*****/\n" +
			 "// comment2\n";
	return unitsize(s) == 1;
}

// A typical multiline comment in hsqldb
test bool testCommentStrip13() {
	str s = "/**\n" +
 "* Represents an SQL VIEW based on a query expression\n" +
 "*\n" +
 "* @author leptipre@users\n" +
 "* @author Fred Toussi (fredt@users dot sourceforge.net)\n" +
 "* @version 2.3.0\n" +
 "* @since 1.7.0\n" +
 "*/\n" +
"public class View extends TableDerived {\n";

	return unitsize(s) == 1;
}

test bool testCommentStrip14() {
	str s = "/**\n" +
     "* Establishes a connection to the server.\n" +
     "*/\n" +
     "public int x = 2\n";
	return unitsize(s) == 1;
}
