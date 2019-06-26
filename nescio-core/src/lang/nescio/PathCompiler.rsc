module lang::nescio::PathCompiler

import ListRelation;
import Set;
import String;
import Map;
import IO;

import analysis::graphs::Graph;

import lang::nescio::Syntax;
import lang::nescio::API;
import lang::nescio::Checker;

data JavaType = javaIntType() | javaStringType() | javaBooleanType();

alias TransformationDescriptor = tuple[str javaClass, lrel[JavaType javaType, str val] args];

alias RuleSpec = tuple[Path path, TransformationDescriptor trafo];

alias Rules = map[str ruleName, RuleSpec rule];

tuple[JavaType, str] evalExpr((Expr) `<NatLiteral lit>`, TModel model, map[Id, ConstantDecl] constants)
	= <javaIntType(), "<lit>">;

tuple[JavaType, str] evalExpr((Expr) `<BoolLiteral lit>`, TModel model, map[Id, ConstantDecl] constants)
	= <javaBooleanType(), "<lit>">;
	
tuple[JavaType, str] evalExpr((Expr) `<HexIntegerLiteral lit>`, TModel model, map[Id, ConstantDecl] constants)
	= <javaIntType(), "<lit>">;	 
	
tuple[JavaType, str] evalExpr((Expr) `<BitLiteral lit>`, TModel model, map[Id, ConstantDecl] constants)
	= <javaIntType(), "<lit>">;	 
	
tuple[JavaType, str] evalExpr((Expr) `<StringLiteral lit>`, TModel model, map[Id, ConstantDecl] constants)
	= <javaStringType(), "<lit>">;	 	

tuple[JavaType, str] evalExpr((Expr) `<Id id>`, TModel model, map[Id, ConstantDecl] constants)
	= evalExpr(e, model, constants)
	when (ConstantDecl) `<Type ty> <Id id> = <Expr e>` := constants[id];

str getModuleName(current: (Specification) `module <ModuleId moduleName> <Import* imports> <Decl* decls>`)
//	= ["<part>" | part <- moduleName.moduleName][-1];
	= "<moduleName>";
	
Rules evalNescio(current: (Specification) `module <ModuleId moduleName> <Import* imports> <Decl* decls>`, TModel model, StructuredGraph graph){
	Rules rules = ();
	
	map[Id, ConstantDecl] constantDecls = (() | it + (id : cd) | (Decl) `<ConstantDecl cd>` <- decls, (ConstantDecl) `<Type ty> <Id id> = <Expr e>` := cd);
	
	list[Id] ordered = reverse(order({<id, id1> | (Decl) `<Type ty> <Id id> = <Id id2>` <- decls}));
	
	list[ConstantDecl] orderedConstants = [constantDecls[id] | id <- ordered] +  [constantDecls[id] | id <- domain(constantDecls) - ordered];
	
	map[Id, tuple[JavaType, str]] constants = ();
	
	map[Id, str] javaClasses = ();
	
	for ((ConstantDecl) `<Type ty> <Id id> = <Expr e>` <- orderedConstants) {
		tuple[JavaType, str] constantVal = evalExpr(e, model, constantDecls);
		constants = constants + (id : constantVal);
	}
	
	for ((Decl) `@ (<JavaId javaId>) algorithm <Id id> <Formals? fls>` <- decls) {
 		javaClasses = javaClasses + (id : "<javaId>");
 	}
 	
 	for ((Decl) `rule <Id ruleName> : <Pattern p> =\> <Id algo> <Args? args>` <- decls) {
 		try {
 			rules = rules + ("<ruleName>" : <toADT(p, graph), <javaClasses[algo], [evalExpr(e, model, constants) |aargs <- args, e <- aargs.args]>>);
 		}
 		catch _:{
 		};
 	} 	
	
	return rules;	
}

PathConfig getDefaultPathConfig() = pathConfig(srcs = [], defs = []);

Rules evalNescio(loc nescioFile, str lang, GraphCalculator gc) {
	start[Specification] nescioSpec = parse(#start[Specification], nescioFile);
	PathConfig pcfg = getDefaultPathConfig();
	TModel nescioModel = nescioTModelFromTree(nescioSpec, pcfg, langsConfig = (lang:gc));
	StructuredGraph g = gc(getModuleName(nescioSpec.top), pcfg);
	if (getMessages(nescioModel) != [])
  		throw "Problems checking nescio file";
  	return evalNescio(nescioSpec.top, nescioModel, g);
}
