module lang::record::nescio::NescioPlugin

import lang::record::Syntax;
import lang::nescio::API;
import util::Reflective;

import ParseTree;

StructuredGraph recordGraphCalculator(str moduleName, PathConfig pcfg) {
 	Tree pt = sampleRecord(moduleName, pcfg);
    return calculateFields(pt.top);
 }
  
public start[Records] sampleRecord(str name, PathConfig pcfg) = parse(#start[Records],  getModuleLocation(name, pcfg, extension = "record"));


//alias Fields = rel[str typeName, str field, str fieldType];
StructuredGraph calculateFields((Records) `<Record* records>`)  
	= ({} | it + calculateFields(r) | r <- records);
	
StructuredGraph calculateFields((Record) `record <Id rId> [ <Field* fields> ]`)
	= {<typeName([], "<rId>"), "<id>", typeName([], "<ty>")> | (Field) `<Type ty> <Id id>` <- fields};
