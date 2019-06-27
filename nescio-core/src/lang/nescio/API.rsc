module lang::nescio::API

import Relation;
import Set;
import IO;
import ParseTree;
import lang::nescio::Syntax;

data TypeName = typeName(list[str] modules, str name);

data Path
    = field(Path src, str fieldName)
    | rootType(TypeName typeName)
    | fieldType(Path src, TypeName typeName)
    | deepMatchType(Path src, TypeName typeName)
    ;
    

TypeName toTypeName((ModuleId) `<{Id "::"}+ moduleName>`) = typeName(lst[0..-1], lst[-1])
	when lst := ["<id>" | id <- moduleName];
    
Path toADT(current: (Pattern) `<ModuleId id>`, StructuredGraph g)
	= resolvePath(rootType(toTypeName(id)), g);
 
Path toADT(current: (Pattern) `<Pattern p> / <Id id>`, StructuredGraph g)
	= resolvePath(field(toADT(p, g), "<id>"), g);
	
Path toADT(current: (Pattern) `<Pattern p> / [<ModuleId id>]`, StructuredGraph g)
	= resolvePath(fieldType(toADT(p, g), toTypeName(id)), g);	
	
Path toADT(current: (Pattern) `<Pattern p> / ** / <ModuleId id>`, StructuredGraph g)
	= resolvePath(deepMatchType(toADT(p, g), toTypeName(id)), g);		

Path toADT(Pattern p, StructuredGraph g){
	throw "Operation not yet implemented";
}

data LanguageConf = languageConf(GraphCalculator gc,  ModulesComputer mc, ModuleMapper mm);

alias LanguagesConf = map[str langId, LanguageConf lc];

alias StructuredGraph = rel[TypeName typeName, str field, TypeName fieldType];

alias Types = set[TypeName typeName];

data PathConfig = pathConfig(list[loc] srcs = []);

alias ModuleMapper = loc(TypeName);

alias GraphCalculator = StructuredGraph(list[loc] modules);

alias ModulesComputer = list[loc](TypeName initial);

StructuredGraph computeAggregatedStructuredGraph(start[Specification] spec, ModulesComputer mc, GraphCalculator gc) {
	list[TypeName] initialModules = [toTypeName(moduleId) |(Import) `import <ModuleId moduleId>` <- spec.top.imports];
	list[loc] allModuleFiles = ([] | it +  mc(initialModule) | TypeName initialModule <- initialModules);
	return gc(allModuleFiles); 
}

StructuredGraph computeAggregatedStructuredGraph(loc nescioFile, ModulesComputer mc, GraphCalculator gc) {
	start[Specification] spec = parse(#start[Specification], nescioFile);
	return computeAggregatedStructuredGraph(spec, mc, gc);
}


data NamedPattern
	=  pattern(str name, Path path);
	
data ResolutionException = typeNameDuplication(str name)
						 | notResolved(str name);


TypeName resolveType(typeName([], name), StructuredGraph fields) {
	set[TypeName] allTypesWithName = {t1 | <t1:typeName(_, name), _, _> <- fields } 
		+ {t1| <_, _, t1:typeName(_, name)> <- fields };
	if (size(allTypesWithName) > 1)
		throw typeNameDuplication(name);
	else if (size(allTypesWithName) == 0)
		throw notResolved(name);
	else
		return getOneFrom(allTypesWithName);
	
}

default TypeName resolveType(TypeName tn:typeName(pkg, name), StructuredGraph fields) = tn;

Path resolvePath(rootType(typeName),StructuredGraph fields) =
	rootType(resolveType(typeName, fields));
	
Path resolvePath(field(src, fieldName), StructuredGraph fields) =
	field(resolvePath(src, fields), fieldName);
 	
Path resolvePath(fieldType(src, typedName), StructuredGraph fields) =
	fieldType(resolvePath(src, fields), resolveType(typedName, fields));
	
Path resolvePath(deepMatchType(src, typedName), StructuredGraph fields) =
	deepMatchType(resolvePath(src, fields), resolveType(typedName, fields));	 	

Types getTypes(field(Path src, str fieldName), StructuredGraph fields)
	= {fieldType | <typeName, fieldName, fieldType> <- fields, typeName in getTypes(src, fields)}; 

Types getTypes(fieldType(Path src, TypeName fieldType), StructuredGraph fields)
	= {fieldType | <typeName, _, fieldType> <- fields, typeName in getTypes(src, fields)};

Types getTypes(deepMatchType(Path src, TypeName typeName), StructuredGraph fields)
	= typeName in range(graph+) ? {typeName} : {}  
	when graph := {<tn, fieldType> | <tn, _, fieldType> <- fields};
	
		
Types getTypes(rootType(typeName), StructuredGraph fields)
	= {typeName | <typeName, _, _> <- fields};
		
/*bool isValidPath(Path p, StructuredGraph fields) =
	_ <- [t | t <- types, t in leaves] 
	when leaves := {fieldType | row:<_, _, fieldType> <- fields, fieldType notin domain(fields)},
		 types := getTypes(p, fields); 
*/

bool isValidPath(Path p, StructuredGraph fields) =
	_ <- [t | t <- types] 
	when types := getTypes(resolvePath(p, fields), fields);