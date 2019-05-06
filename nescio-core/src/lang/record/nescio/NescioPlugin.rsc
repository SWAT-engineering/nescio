module lang::record::nescio::NescioPlugin

import lang::record::Syntax;
import lang::nescio::API;

import ParseTree;

StructuredGraph recordGraphCalculator(str moduleName, PathConfig cfg) {
 	Tree pt = sampleRecord(moduleName);
    return calculateFields(pt.top);
 }
  
public start[Records] sampleRecord(str name) = parse(#start[Records], |project://nescio/nescio-src/<name>.record|);

//alias Fields = rel[str typeName, str field, str fieldType];
StructuredGraph calculateFields((Records) `<Record* records>`)  
	= ({} | it + calculateFields(r) | r <- records);
	
StructuredGraph calculateFields((Record) `record <Id rId> [ <Field* fields> ]`)
	= {<typeName([], "<rId>"), "<id>", typeName([], "<ty>")> | (Field) `<Type ty> <Id id>` <- fields};
