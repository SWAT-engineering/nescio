module lang::nescio::Checker

import lang::nescio::Syntax;
import lang::nescio::API;
import util::Math;
import ListRelation;
import Set;
import String;

import util::Reflective;


extend analysis::typepal::TypePal;
extend analysis::typepal::TestFramework;

lexical ConsId =  "$" ([a-z A-Z 0-9 _] !<< [a-z A-Z _][a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _])\Reserved;

anno bool Type@bounded;

data AType
	= moduleType()
	| ruleType(str id)
	| trafoType(str id, list[AType] formals)
	| intType()
	| strType()
	| boolType()
	;
	
data IdRole
    = moduleId()
    | ruleId()
    | trafoId()
    | paramId()
    | constantId()
    ;
    
data PathRole
    = importPath()
    ;
    

str prettyPrintAType(moduleType()) = "moduleType";
str prettyPrintAType(ruleType(id)) = "ruleType <id>";
str prettyPrintAType(trafoType(id, formals)) = "trafoType <id>";
str prettyPrintAType(boolType()) = "bool";    
str prettyPrintAType(intType()) = "int";
str prettyPrintAType(strType()) = "str";
str prettyPrintAType(boolType()) = "bool";

// ----  Collect definitions, uses and requirements -----------------------


void collect(current: (Specification) `module <ModuleId moduleName> <Import* imports> <Decl* decls>`, Collector c){
 	c.define("<moduleName>", moduleId(), current, defType(moduleType()));
    c.enterScope(current);
    collect(imports, c);
    if ([] !:= c.getStack(__NESCIO_GRAPHS_QUEUE)) {
    	if (list[StructuredGraph] graphs := c.getStack(__NESCIO_GRAPHS_QUEUE)) {
    		c.push(__AGGREGATED_GRAPH, ({} | it + g | g <- graphs));
    	}
    	else
    		c.push(__AGGREGATED_GRAPH, {});
    }
    else
    	c.push(__AGGREGATED_GRAPH, {});
    currentScope = c.getScope();
    	collect(decls, c);
    c.leaveScope(current);
}

// ---- Modules and imports

data PathConfig(loc target = |cwd:///|);

private loc project(loc file) {
   assert file.scheme == "project";
   return |project://<file.authority>|;
}

private str __NESCIO_GRAPHS_QUEUE = "__nescioGraphsQueue";
private str __AGGREGATED_GRAPH = "__nescioAggregatedGraph";
private str __NESCIO_USED_LANGUAGE = "__nescioUsedLanguage";

void collect(current:(Import) `import <ModuleId name> from <Id langId>`, Collector c) {
	 LanguagesConf langs = c.getConfig().langsConfig;
	 PathConfig pathConf = c.getConfig().pathConfig;
	 if ("<langId>" in langs) {
	 	GraphCalculator gc = langs["<langId>"];
	 	try {
	 		StructuredGraph graph = gc("<name>", pathConf);
	 		c.push(__NESCIO_GRAPHS_QUEUE, graph);
		 	if ([] !:= c.getStack(__NESCIO_USED_LANGUAGE)){
		 		if (str usedLang := c.top(__NESCIO_USED_LANGUAGE), "<langId>" !:= usedLang) 
	 				c.report(error(current, "All imports in this module need to be of the first imported language %v", "<langId>"));
		 	}
		 	else 
		 		c.push(__NESCIO_USED_LANGUAGE, "<langId>");
	 	}
	 	catch IO(msg):{
	 		c.report(error(current, "Module %v not found", "<name>"));
	 	};
	 }
	 else
	 	c.report(error(current, "There is not a registered graph calculator for language %v", "<langId>"));
}

void collect(current: Pattern p, Collector c) {
	//println(path);
	if (StructuredGraph graph := c.top(__AGGREGATED_GRAPH)) {
		Path path = toADT(p, graph);
		if (!isValidPath(path, graph)) 
			c.report(error(current, "Path is not valid"));
	}
	else
		c.report(error(current, "Cannot check path since there is not a registered graph calculator"));
}

void collect(current: (Decl) `rule <Id id> : <Pattern pattern> =\> <Id trId> <Args? args>`, Collector c){
 	c.define("<id>", ruleId(), current, defType(ruleType("<id>")));
	collect(pattern, c);
	c.use(trId, {trafoId()});
	for (aargs <- args, e <- aargs.args) {
		collect(e, c);
	}
	c.require("transformations arguments", current, 
			  [trId] + [e | aargs <- args, e <- aargs.args], void (Solver s) {
			ty = s.getType(trId);  
			if (trafoType(_, formals) := ty) {
				argTypes = [ s.getType(e) | aargs <- args, e <- aargs.args];
				s.requireEqual(atypeList(argTypes), atypeList(formals), error(current, "Wrong type of arguments for the transformation"));
			}	
			else{
				s.report(error(current, "Transformation arguments only apply to transformation types but got %t", ty));
			}
		});
}

void collect(current: (Decl) `rule <Id id> : <Pattern pattern> =\> <Id trId> <Args? args>`, Collector c){
 	c.define("<id>", ruleId(), current, defType(expr));
	// collect(pattern, c);
	c.use(trId, {trafoId()});
	for (aargs <- args, e <- aargs.args) {
		collect(e, c);
	}
	c.require("transformations arguments", current, 
			  [trId] + [e | aargs <- args, e <- aargs.args], void (Solver s) {
			ty = s.getType(trId);  
			if (trafoType(id,formals) := ty) {
				argTypes = [ s.getType(e) | aargs <- args, e <- aargs.args];
				s.requireEqual(atypeList(argTypes), atypeList(formals), error(current, "Wrong type of arguments for the transformation"));
			}	
			else{
				s.report(error(current, "Transformation arguments only apply to transformation types but got %t", ty));
			}
		});
}

void collect(current: (Decl) `@ (<JavaId jId>) algorithm <Id id> <Formals? fs>`, Collector c) {
	for (afs <- fs, f <- afs.formals) 
		collect(f, c);
	c.define("<id>", trafoId(), current, defType([f | afs <- fs, f <- afs.formals], AType(Solver s) {
     		return trafoType("<id>", [s.getType(f) | afs <- fs, f <- afs.formals]);
    })); 
}

void collect(current: (ConstantDecl) `<Type ty> <Id id> = <Expr e>`, Collector c) {
	c.define("<id>", constantId(), current, defType(ty));
	collect(ty, c);
	collect(e, c);
	c.requireEqual(e, ty, error(e, "Expected %t, got: %t", ty, e));
}

void collect(current:(Formal) `<Type ty> <Id id>`, Collector c){
	c.define("<id>", paramId(), current, defType(ty));
	collect(ty, c);
}
    
void collect(current:(Type)`str`, Collector c) {
	c.fact(current, strType());
}

void collect(current:(Type)`bool`, Collector c) {
	c.fact(current, boolType());
}  

void collect(current:(Type)`int`, Collector c) {
	c.fact(current, intType());
} 

void collect(current: (Expr) `<Id id>`, Collector c){
    c.use(id, {constantId(), paramId()});
}

void collect(current: (Expr) `<BoolLiteral lit>`, Collector c){
    c.fact(current, boolType());
}

void collect(current: (Expr) `<StringLiteral lit>`, Collector c){
    c.fact(current, strType());
}


void collect(current: (Expr) `<HexIntegerLiteral nat>`, Collector c){
    c.fact(current, intType());
}

void collect(current: (Expr) `<BitLiteral nat>`, Collector c){
    c.fact(current, intType());
}

void collect(current: (Expr) `<NatLiteral nat>`, Collector c){
    c.fact(current, intType());
}

// ----  Examples & Tests --------------------------------
alias LanguagesConf = map[str langId, GraphCalculator gc];

data TypePalConfig(
    LanguagesConf langsConfig = (),
    PathConfig pathConfig = pathConfig()
);


TModel nescioTModelFromTree(Tree pt, PathConfig pcfg, LanguagesConf langsConfig = (), bool debug = false){
    if (pt has top) pt = pt.top;
    c = newCollector("collectAndSolve", pt, config=getNescioConfig(langsConfig, pcfg));
   	collect(pt, c);
    return newSolver(pt, c.run()).run();
}

private TypePalConfig getNescioConfig(LanguagesConf langsConfig, PathConfig pathConf) = tconfig(
	langsConfig = langsConfig,
	pathConfig = pathConf
    //getTypeNamesAndRole = birdGetTypeNameAndRole,
    //getTypeInNamelessType = birdGetTypeInAnonymousStruct,
);


public start[Specification] sampleNescio(str name) = parse(#start[Specification], |project://nescio/nescio-src/<name>.nescio|);

list[Message] runNescio(str name, bool debug = false) {
    Tree pt = sampleNescio(name);
    TModel tm = nescioTModelFromTree(pt, debug = debug);
    return tm.messages;
}
 