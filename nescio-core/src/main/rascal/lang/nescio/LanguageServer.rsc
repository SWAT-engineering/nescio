module lang::nescio::LanguageServer

import ParseTree;

import util::LanguageServer;
import util::Monitor;
import util::Reflective;

import lang::nescio::Syntax;

set[LanguageService] nescioLanguageContributor() {
    return {
        parser(getNescioParser()),
        outliner(nescioOutliner)
    };
}

list[DocumentSymbol] nescioOutliner(start[Specification] input) {
    jobStart("Nescio Outliner");
    l = input.src.top;
    jobStep("Nescio Outliner", l.file);
    list[DocumentSymbol] children = [];
    for (declaration <- input.top.declarations) {
        children += buildOutline(declaration);
    }
    jobEnd("Nescio Outliner");
    return [symbol("module <input.top.moduleId>", DocumentSymbolKind::\module(), input.src, children=children)];
}

list[DocumentSymbol] buildOutline(current:(Decl)`rule <Id id> : <Pattern _> =\> <Id _> <Args? _>`)
    = [symbol("rule <id>", DocumentSymbolKind::key(), current.src)];

list[DocumentSymbol] buildOutline(current:(Decl)`@(<JavaId _>) algorithm <Id id> <Formals? _>`)
    = [symbol("trafo <id>", DocumentSymbolKind::method(), current.src)];

list[DocumentSymbol] buildOutline(current:(Decl)`<Type _> <Id id> = <Expr _>`)
    = [symbol("constant <id>", DocumentSymbolKind::constant(), current.src)];

set[loc] singleDefinition(loc _, start[Specification] fullTree, Tree cursor)
    = defs(fullTree.top, cursor);

set[loc] defs(_, _) = {};

void main() {
    unregisterLanguage("Nescio", "nescio");
    registerLanguage(
        language(
            pathConfig(srcs=[|project://nescio-core/src/main/rascal|]),
            "Nescio",
            "nescio",
            "lang::nescio::LanguageServer",
            "nescioLanguageContributor"));
}
