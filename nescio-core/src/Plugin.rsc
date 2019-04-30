module Plugin

import lang::nescio::Syntax;
import lang::nescio::Checker;
import lang::nescio::API;

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
    
Tree checkNescio(Tree input){
    model = nescioTModelFromTree(input); // your function that collects & solves
    types = getFacts(model);
  
  return input[@messages={*getMessages(model)}]
              [@hyperlinks=getUseDef(model)]
              [@docs=(l:"<prettyPrintAType(types[l])>" | l <- types)]
         ; 
}    

void main() {
	registerLanguage(LANG_NAME, "nescio", start[Program](str src, loc org) {
		return parse(#start[Program], src, org);
 	});
 	
 	registerContributions(LANG_NAME, {
        commonSyntaxProperties,
        treeProperties(hasQuickFixes = false), // performance
        annotator(checkNescio)
    });
}

void main2(){
	registerLanguage(RECORD_LANG_NAME, "record", start[Records](str src, loc org) {
		return parse(#start[Records], src, org);
 	});
	

}