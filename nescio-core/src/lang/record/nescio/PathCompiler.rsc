module lang::record::nescio::NescioPlugin

import lang::nescio::API;
import lang::nescio::PathCompiler;

/*
data Path
    = field(Path src, str fieldName)
    | rootType(str typeName)
    | fieldType(Path src, str typeName)
    | deepMatchType(Path src, str typeName)
    ;
*/

str compile(str name, root(typeName), Index index) =
	"tuple[str, lrel[int, int]] <name>(RecordInstance program, Word <fieldName>){
	'	lrel[int, int] matches = [];
	'	visit (program) {
	'		case (Row) `\<Word ty\> : \<Word i\>, \<Word name\>, \<Word _\>`: {
	'			if ((Word) `City` :=ty && i := cityIndex) { 
	'				matches +=  \<(name@\\loc).offset, (name@\\loc).length\>;
	'			}
	'		}
	'	}
	'	return \<\"<name>\", matches\>;
	'";
   
str compile(str name, field(Path src, str fieldName), Index index) =
	"tuple[str, lrel[int, int]] <name>(RecordInstance program, Word <fieldName>){
	'	lrel[int, int] matches = [];
	'	visit (program) {
	'		case (Row) `\<Word ty\> : \<Word i\>, \<Word name\>, \<Word _\>`: {
	'			if ((Word) `City` :=ty && i := cityIndex) { 
	'				matches +=  \<(name@\\loc).offset, (name@\\loc).length\>;
	'			}
	'		}
	'	}
	'	return \<\"<name>\", matches\>;
	'";
   
str compileTopLevel(str name, field(Path src, str fieldName), Index index) =
	"tuple[str, lrel[int, int]] <name>(RecordInstance program, Word <fieldName>){
	'	lrel[int, int] matches = [];
	'	visit (program) {
	'		case (Row) `\<Word ty\> : \<Word i\>, \<Word name\>, \<Word _\>`: {
	'			if ((Word) `City` :=ty && i := cityIndex) { 
	'				matches +=  \<(name@\\loc).offset, (name@\\loc).length\>;
	'			}
	'		}
	'	}
	'	return \<\"<name>\", matches\>;
	'";

alias Index = lrel[str recordName, str fieldName, str fieldType, int index]; 	

str compile(list[Rule] rules, Records records) =
	"module lang::record::nescio::InstanceProcessor	
	'
	'extend lang::std::Layout;
	'
	'start syntax RecordInstance = Row* rows;
	'
	'syntax Row = Word type \":\" { Word \",\"}+ words;
	'lexical Word = StringCharacter* chars;
	'lexical StringCharacter = [0-9A-Za-z] | \" \";
	'
	'rel[str, lrel[int, int]] applyRules(RecordInstance program) {
	'	rel[str, lrel[int, int]] result = {};
	'<for (<name, path> <- rules){>
	'	result += <name>(program);
	'<}>
	'	return result;
	'}
	'
	'rel[str, lrel[int, int]] run(str fileName) {
	'	start[RecordInstance] prog = parse(#start[RecordInstance], |project://nescio/nescio-src/\<fileName\>.person|);
	'	return applyRules(prog.top);
	'}
	'"
	when index := createIndex(records);
	