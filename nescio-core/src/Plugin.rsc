module Plugin

import lang::nescio::Syntax;
import lang::record::Syntax;
import ParseTree;

import IO;
import util::IDE;


private str LANG_NAME = "nescio";
private str RECORD_LANG_NAME = "record";

Contribution commonSyntaxProperties 
    = syntaxProperties(
        fences = {<"{","}">,<"(",")">}, 
        lineComment = "//", 
        blockComment = <"/*","*","*/">
    );

void main() {
	registerLanguage(LANG_NAME, "nescio", start[Program](str src, loc org) {
		return parse(#start[Program], src, org);
 	});
	
	registerContributions(LANG_NAME, {
        commonSyntaxProperties
    });
}

void main2(){
	registerLanguage(RECORD_LANG_NAME, "record", start[Records](str src, loc org) {
		return parse(#start[Records], src, org);
 	});
	

}