module lang::record::Plugin

import lang::nescio::Plugin;

import lang::nescio::Syntax;
import lang::record::Syntax;

import lang::record::nescio::NescioPlugin;

import ParseTree;
import util::IDE;

private str RECORD_LANG_NAME = "record";

void main() {
	registerLanguage(NESCIO_LANG_NAME, "nescio", start[Program](str src, loc org) {
		return parse(#start[Program], src, org);
 	});
 	
 	registerContributions(NESCIO_LANG_NAME, {
        commonSyntaxProperties,
        treeProperties(hasQuickFixes = false), // performance
        annotator(checkNescio((RECORD_LANG_NAME:recordGraphCalculator)))
    });

	registerLanguage(RECORD_LANG_NAME, "record", start[Records](str src, loc org) {
		return parse(#start[Records], src, org);
 	});
}