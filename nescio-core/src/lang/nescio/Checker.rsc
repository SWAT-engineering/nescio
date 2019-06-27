module lang::nescio::Checker

import lang::nescio::Syntax;
import lang::nescio::API;
import util::Math;
import ListRelation;
import Set;
import String;
import IO;

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


void collect(current: (Specification) `module <ModuleId moduleName> forLanguage <Id langId> rootNode <ModuleId rootId> <Import* imports> <Decl* decls>`, Collector c){
 	c.define("<moduleName>", moduleId(), current, defType(moduleType()));
    c.enterScope(current);
    
    LanguagesConf langs = c.getConfig().langsConfig;
	if ("<langId>" in langs) {
	 	if (languageConf(GraphCalculator gc,  ModulesComputer mc, ModuleMapper mm) := langs["<langId>"]) {
			collectImports([i | i <- imports], gc, mc, mm, c);
		}
	}
	else
	 	c.report(error(langId, "There is not a registered graph calculator for language %v", "<langId>"));
	
	collectRootNode(rootId, c);
	
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

private str __AGGREGATED_GRAPH = "__nescioAggregatedGraph";
private str __ROOT_NODE = "__nescioRootNode";

void collectRootNode(ModuleId rootId, Collector c) {
	if (StructuredGraph graph := c.top(__AGGREGATED_GRAPH)) {
		try {
			TypeName rootType = resolveType(toTypeName(rootId), graph);
			c.push(__ROOT_NODE, rootType);
		}
		catch typeNameDuplication(typeName): {
			c.report(error(rootId, "Type <rootType> is duplicated"));
		}
		catch notResolved(typeName):{ 
			c.report(error(rootId, "Type <rootType> could not be resolved"));
		};
	}
}

void collectImports(list[Import] imports, GraphCalculator gc,  ModulesComputer mc, ModuleMapper mm, Collector c) {
	 list[loc] modules = [];
	 for ((Import) `import <ModuleId moduleName>` <- imports) {
	 	TypeName moduleType = toTypeName(moduleName);
	 	loc moduleLoc = mm(moduleType);
	 	if (!exists(moduleLoc))
	 		c.report(error(current, "Module %v not found", "<name>"));
	 	else
	 		modules = modules + mc(moduleType);
	 }	 
	 c.push(__AGGREGATED_GRAPH, gc(modules));
}

void collect(current: Pattern p, Collector c) {
	//println(path);
	if (TypeName rootType := c.top(__ROOT_NODE)) {
		if (StructuredGraph graph := c.top(__AGGREGATED_GRAPH)) {
			try {
				Path path = toADT(p, rootType, graph);
				if (!isValidPath(path, graph)) 
					c.report(error(current, "Path is not valid"));
			}
			catch typeNameDuplication(typeName): {
				c.report(error(current, "Type <typeName> is duplicated"));
			}
			catch notResolved(typeName):{ 
				c.report(error(current, "Type <typeName> could not be resolved"));
			};
		}
		else
			c.report(error(current, "Cannot check path since there is not a registered graph calculator"));
	}
	else 
		c.report(error(current, "Cannot check path since there is not a validly defined root node"));
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
 