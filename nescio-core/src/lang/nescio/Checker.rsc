module lang::nescio::Checker

import lang::nescio::Syntax;
import lang::nescio::API;
import util::Math;
import ListRelation;
import Set;
import String;

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
    
Path toADT(current: (Pattern) `<Id id>`)
	= rootType("<id>");
 
Path toADT(current: (Pattern) `<Pattern p> / <Id id>`)
	= field(toADT(p), "<id>");
	
Path toADT(current: (Pattern) `<Pattern p> / [<Id id>]`)
	= fieldType(toADT(p), "<id>");	
	
Path toADT(current: (Pattern) `<Pattern p> / ** / <Id id>`)
	= deepMatchType(toADT(p), "<id>");		

Path toADT(Pattern p){
	throw "Operation not yet implemented";
}

// ----  Collect definitions, uses and requirements -----------------------


void collect(current: (Program) `module <ModuleId moduleName> <Import* imports> <Decl* decls>`, Collector c){
 	c.define("<moduleName>", moduleId(), current, defType(moduleType()));
    c.enterScope(current);
    collect(imports, c);
    currentScope = c.getScope();
    	collect(decls, c);
    c.leaveScope(current);
}

// ---- Modules and imports

private loc project(loc file) {
   assert file.scheme == "project";
   return |project://<file.authority>|;
}

private str __NESCIO_SUPPORTED_LANGS = "__nescioSupportedLangs";
private str __NESCIO_GRAPHS_QUEUE = "__nescioGraphsQueue";

PathConfig pathConfig(loc file) {
   assert file.scheme == "project";
   p = project(file);      
   return pathConfig(srcs = [ p + "nescio-src"]);
}
 
// TODO shall we:
// 1) admit importing modules from different languages? NOT
// 2) admit importing more than one module per language? 
void collect(current:(Import) `import <ModuleId name> from <Id langId>`, Collector c) {
	 if (LanguagesConf langs := c.getStack(__NESCIO_SUPPORTED_LANGS)[0] && "<langId>" in langs) {
	 	GraphCalculator gc = langs["<langId>"];
	 	StructuredGraph graph = gc("<name>", pathConfig(current@\loc));
	 	c.push(__NESCIO_GRAPHS_QUEUE, graph);
	 }
	 else
	 	c.report(error(current, "There is not a registered graph calculator for language %v", langId));
}

void collect(current: Pattern p, Collector c) {
	Path path = toADT(p);
	println(path);
	if (StructuredGraph graph := (c.getStack(__NESCIO_GRAPHS_QUEUE))[0] && !isValidPath(path, graph.definedFields)) {
		c.report(error(current, "Path is not valid"));
	}
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

TModel nescioTModelFromTree(Tree pt, LanguagesConf langsConfig = (), bool debug = false){
    if (pt has top) pt = pt.top;
    c = newCollector("collectAndSolve", pt, config=getNescioConfig());    // TODO get more meaningfull name
   	c.push(__NESCIO_SUPPORTED_LANGS, langsConfig);
    collect(pt, c);
    return newSolver(pt, c.run()).run();
}

private TypePalConfig getNescioConfig() = tconfig(
    //getTypeNamesAndRole = birdGetTypeNameAndRole,
    //getTypeInNamelessType = birdGetTypeInAnonymousStruct,
);


public start[Program] sampleNescio(str name) = parse(#start[Program], |project://nescio/nescio-src/<name>.nescio|);

list[Message] runNescio(str name, bool debug = false) {
    Tree pt = sampleNescio(name);
    TModel tm = nescioTModelFromTree(pt, debug = debug);
    return tm.messages;
}
 