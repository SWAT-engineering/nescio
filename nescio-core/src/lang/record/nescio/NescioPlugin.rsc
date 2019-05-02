module lang::record::nescio::NescioPlugin

import lang::record::Syntax;
import lang::nescio::API;

import ParseTree;

StructuredGraph recordGraphCalculator(str moduleName, PathConfig cfg) {
 	Tree pt = sampleRecord(moduleName);
    return graph(moduleName, calculateFields(pt.top));
 }
  
public start[Records] sampleRecord(str name) = parse(#start[Records], |project://nescio/nescio-src/<name>.record|);

//alias Fields = rel[str typeName, str field, str fieldType];
Fields calculateFields((Records) `<Record* records> <Instance* instances>`)  
	= ({} | it + calculateFields(r) | r <- records);
	
Fields calculateFields((Record) `record <Id rId> [ <Field* fields> ]`)
	= {<"<rId>", "<id>", "<ty>"> | (Field) `<Type ty> <Id id>` <- fields};
