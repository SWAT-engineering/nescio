module lang::nescio::Plugin

import lang::nescio::Syntax;
import lang::nescio::Checker;
import lang::nescio::API;

import lang::record::Syntax;
import ParseTree;

import IO;
import util::IDE;

import util::Reflective;
import lang::manifest::IO;

public str NESCIO_LANG_NAME = "nescio";

data NescioManifest 
 = nescioManifest(
      list[str] Source = ["src"],
      str Target = "generated"
   );
 
private loc configFile(loc file) =  project(file) + "META-INF" + "RASCAL.MF"; 

private loc project(loc file) {
   assert file.scheme == "project";
   return |project:///|[authority = file.authority];
}


PathConfig getDefaultPathConfig() = pathConfig(srcs = [], defs = []);

PathConfig config(loc file) {
   assert file.scheme == "project";

   p = project(file);
   cfgFile = configFile(file);
   mf = readManifest(#NescioManifest, cfgFile); 
   
   cfg = getDefaultPathConfig();
   
   cfg.srcs += [ p + s | s <- mf.Source] ;
   
   if (/^\|/ := mf.Target) {
      cfg.target = readTextValueString(#loc, mf.Target);
   }
   else {
      cfg.target = p + mf.Target;
   }
   
   return cfg;
}


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
	pcfg = config(input@\loc);
    model = nescioTModelFromTree(input, pcfg, langsConfig = langs); // your function that collects & solves
    types = getFacts(model);
  
  return input[@messages={*getMessages(model)}]
              [@hyperlinks=getUseDef(model)]
              [@docs=(l:"<prettyPrintAType(types[l])>" | l <- types)]
         ; 
}; 

void main() {
	registerLanguage(NESCIO_LANG_NAME, "nescio", start[Specification](str src, loc org) {
		return parse(#start[Specification], src, org);
 	});
 	
 	registerContributions(NESCIO_LANG_NAME, {
        commonSyntaxProperties,
        treeProperties(hasQuickFixes = false), // performance
        annotator(checkNescio(()))
    });
}
