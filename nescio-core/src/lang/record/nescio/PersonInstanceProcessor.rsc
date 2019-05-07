module lang::record::nescio::InstanceProcessor

import IO;

extend lang::std::Layout;

start syntax RecordInstance = Row* rows;

syntax Row = Word type ":" { Word ","}+ words;

lexical Word
	= StringCharacter* chars;	
	
lexical StringCharacter
	= [0-9A-Za-z]
	| " "
	;
	
tuple[str, lrel[int, int]] HideAge(RecordInstance program){
	lrel[int, int] matches = [];
	visit (program) {
		case (Row) `<Word ty> : <Word _>, <Word _>, <Word age>, <Word _>, <Word _>`: {
			if ((Word) `Person` :=ty) 
				matches +=  <(age@\loc).offset, (age@\loc).length>;
		}
	}
	return <"HideAge", matches>;
}

tuple[str, lrel[int, int]] HideAge(RecordInstance program){
	lrel[int, int] matches = [];
	visit (program) {
		case (Row) `<Word ty> : <Word _>, <Word _>, <Word age>, <Word _>, <Word _>`: {
			if ((Word) `Person` :=ty) 
				matches +=  <(age@\loc).offset, (age@\loc).length>;
		}
	}
	return <"HideAge", matches>;
}

 lrel[int, int] HideCityNameWorkAddress2(RecordInstance program, Word cityIndex){
	lrel[int, int] matches = [];
	visit (program) {
		case (Row) `<Word ty> : <Word i>, <Word name>, <Word _>`: {
			if ((Word) `City` :=ty && i := cityIndex) { 
				matches +=  <(name@\loc).offset, (name@\loc).length>;
			}
		}
	}
	return matches;
}

 lrel[int, int] HideCityNameWorkAddress1(RecordInstance program, Word addressIndex){
	lrel[int, int] matches = [];
	visit (program) {
		case (Row) `<Word ty> : <Word i>, <Word _>, <Word _>, <Word city>`: {
			if ((Word) `Address` :=ty && i := addressIndex) { 
				matches += HideCityNameWorkAddress2(program, city);
			}
		}
	}
	return matches;
}


tuple[str, lrel[int, int]] HideCityNameWorkAddress(RecordInstance program){
	lrel[int, int] matches = [];
	visit (program) {
		case (Row) `<Word ty> : <Word _>, <Word _>, <Word _>, <Word _>, <Word address>`: {
			if ((Word) `Person` :=ty) { 
				matches += HideCityNameWorkAddress1(program, address);
			}
		}
	}
	return <"HideCityNameWorkAddress", matches>;
}



//Person/workAddress/city/name 
tuple[str, lrel[int, int]] HC1(RecordInstance program){
	lrel[int, int] matches = [];
	// this matches a city
	for ((Row) `<Word ty> : <Word _>, <Word name>, <Word _>` <- HC2(program)){
		matches +=  <(name@\loc).offset, (name@\loc).length>;
	};
	return <"HC", matches>;
}

list[Row] HC4(RecordInstance program){
	visit (program) {
		case row:(Row) `<Word ty> : <Word a>, <Word _>, <Word _>, <Word _>, <Word _>`: {
			if ((Word) `Person` :=ty) {
				list[Row] rows = [];
				rows += row;
				println("<row>");
				return rows;
			}
		}
	}
}
	

list[Row] HC3(RecordInstance program){
	// this matches a person
	list[Row] rows = [];
	
	dummyFun = void(Word workAddress) {
		visit (program) {
			case row:(Row) `<Word ty> : <Word a>, <Word _>, <Word _>, <Word _>`: {
				if ((Word) `Address` :=ty && a == workAddress) { 
					rows += row; 
				}
			}
		}
	};
	
	for ((Row) `<Word _> : <Word _>, <Word _>, <Word _>, <Word workAddress>, <Word _>` <- HC4(program)){
		dummyFun(workAddress);
	};
	println("HC3 rows: <size(rows)>");
	
	return rows;
}


list[Row] HC2(RecordInstance program){
	// this matches an address
	list[Row] rows = [];
	
	dummyFun = void(Word city) {
		visit (program) {
			case row: (Row) `<Word ty> : <Word c>, <Word _>, <Word _>`: {
				if ((Word) `City` :=ty && c == city) { 
					rows += row;
				}
			}
		}
	};
	for ((Row) `<Word ty> : <Word _>, <Word _>, <Word _>, <Word city>` <- HC3(program)){
		dummyFun(city);
	};
	println("HC2 rows: <size(rows)>");
	return rows;
}



rel[str, lrel[int, int]] applyRules(RecordInstance program) {
	rel[str, lrel[int, int]] result = {};
	result += HideAge(program);
	//result += HideCityNameWorkAddress(program);
	result += HC1(program);
	return result;
}

rel[str, lrel[int, int]] run(str fileName) {
	start[RecordInstance] prog = parse(#start[RecordInstance], |project://nescio/nescio-src/<fileName>.person|);
	return applyRules(prog.top);
}

