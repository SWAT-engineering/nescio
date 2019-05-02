module lang::nescio::Plugin

import lang::nescio::Syntax;
import lang::nescio::Checker;
import lang::nescio::API;

import lang::record::Syntax;
import ParseTree;

import IO;
import util::IDE;


public str NESCIO_LANG_NAME = "nescio";

public Contribution commonSyntaxProperties 
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

Tree(Tree) checkNescio(map[str, GraphCalculator] langs) = Tree(Tree input){
    model = nescioTModelFromTree(input, langsConfig = langs); // your function that collects & solves
    types = getFacts(model);
  
  return input[@messages={*getMessages(model)}]
              [@hyperlinks=getUseDef(model)]
              [@docs=(l:"<prettyPrintAType(types[l])>" | l <- types)]
         ; 
}; 

void main() {
	registerLanguage(NESCIO_LANG_NAME, "nescio", start[Program](str src, loc org) {
		return parse(#start[Program], src, org);
 	});
 	
 	registerContributions(NESCIO_LANG_NAME, {
        commonSyntaxProperties,
        treeProperties(hasQuickFixes = false), // performance
        annotator(checkNescio)
    });
}
