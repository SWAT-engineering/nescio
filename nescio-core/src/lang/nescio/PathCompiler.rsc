module lang::nescio::PathCompiler

import ListRelation;
import Set;
import String;
import Map;
import IO;
import ParseTree;

import analysis::graphs::Graph;

import lang::nescio::Syntax;
import lang::nescio::API;
import lang::nescio::Checker;

data JavaType = javaIntType() | javaStringType() | javaBooleanType();

alias TransformationDescriptor = tuple[str javaClass, lrel[JavaType javaType, str val] args];

alias RuleSpec = tuple[Path path, TransformationDescriptor trafo];

alias Rules = map[str ruleName, RuleSpec rule];

tuple[JavaType, str] evalExpr((Expr) `<NatLiteral lit>`, map[Id, ConstantDecl] constants)
	= <javaIntType(), "<lit>">;

tuple[JavaType, str] evalExpr((Expr) `<BoolLiteral lit>`, map[Id, ConstantDecl] constants)
	= <javaBooleanType(), "<lit>">;
	
tuple[JavaType, str] evalExpr((Expr) `<HexIntegerLiteral lit>`, map[Id, ConstantDecl] constants)
	= <javaIntType(), "<lit>">;	 
	
tuple[JavaType, str] evalExpr((Expr) `<BitLiteral lit>`, map[Id, ConstantDecl] constants)
	= <javaIntType(), "<lit>">;	 
	
tuple[JavaType, str] evalExpr((Expr) `<StringLiteral lit>`, map[Id, ConstantDecl] constants)
	= <javaStringType(), "<lit>">;	 	

tuple[JavaType, str] evalExpr((Expr) `<Id id>`, map[Id, ConstantDecl] constants)
	= evalExpr(e, constants)
	when (ConstantDecl) `<Type ty> <Id id> = <Expr e>` := constants[id];

str getModuleName(current: (Specification) `module <ModuleId moduleName> <Import* imports> <Decl* decls>`)
//	= ["<part>" | part <- moduleName.moduleName][-1];
	= "<moduleName>";
	
Rules evalNescio(current: (Specification) `module <ModuleId moduleName> forLanguage <Id lang> rootNode <ModuleId rootNode> <Import* imports> <Decl* decls>`, StructuredGraph graph){
	Rules rules = ();
	
	map[Id, ConstantDecl] constantDecls = (() | it + (id : cd) | (Decl) `<ConstantDecl cd>` <- decls, (ConstantDecl) `<Type ty> <Id id> = <Expr e>` := cd);
	
	list[Id] ordered = reverse(order({<id, id1> | (Decl) `<Type ty> <Id id> = <Id id2>` <- decls}));
	
	list[ConstantDecl] orderedConstants = [constantDecls[id] | id <- ordered] +  [constantDecls[id] | id <- domain(constantDecls) - ordered];
	
	map[Id, tuple[JavaType, str]] constants = ();
	
	map[Id, str] javaClasses = ();
	
	for ((ConstantDecl) `<Type ty> <Id id> = <Expr e>` <- orderedConstants) {
		tuple[JavaType, str] constantVal = evalExpr(e, constantDecls);
		constants = constants + (id : constantVal);
	}
	
	for ((Decl) `@ (<JavaId javaId>) algorithm <Id id> <Formals? fls>` <- decls) {
 		javaClasses = javaClasses + (id : "<javaId>");
 	}
 	
 	for ((Decl) `rule <Id ruleName> : <Pattern p> =\> <Id algo> <Args? args>` <- decls) {
 		try {
 			rules = rules + ("<ruleName>" : <toADT(p, resolveType(toTypeName(rootNode), graph), graph), <javaClasses[algo], [evalExpr(e, constants) |aargs <- args, e <- aargs.args]>>);
 		}
 		catch _:{
 		};
 	} 	
	
	return rules;	
}

PathConfig getDefaultPathConfig() = pathConfig(srcs = [], defs = []);

TypeName getRoot((start[Specification]) `module <ModuleId _> forLanguage <Id _> rootNode <ModuleId rootNode> <Import* _> <Decl* _>`, StructuredGraph graph) =
	resolveType(toTypeName(rootNode), graph);
	
TypeName getRoot(loc nescioSpec, StructuredGraph graph) = getRoot(parseNescio(nescioSpec), graph);

	
TypeName getRoot(loc nescioSpec, StructuredGraph graph) = getRoot(parseNescio(nescioSpec), graph);


list[TypeName] getImported((start[Specification]) `module <ModuleId _> forLanguage <Id _> rootNode <ModuleId _> <Import* imported> <Decl* _>`, StructuredGraph graph) =
	[resolveType(toTypeName(i.moduleId), graph) | Import i <- imported];
	
TypeName getImported(loc nescioSpec, StructuredGraph graph) = getImported(parseNescio(nescioSpec), graph);	

Rules evalNescio(start[Specification] nescioSpec, StructuredGraph graph) = evalNescio(nescioSpec.top, graph);

Rules evalNescio(loc nescioSpec, StructuredGraph graph) = evalNescio(parseNescio(nescioSpec), graph);

