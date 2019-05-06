module lang::nescio::PathCompiler

import ListRelation;
import Set;
import String;

import lang::nescio::API;

alias TransformationDescriptor = tuple[str javaClass, lrel[str javaClass, str val] args];

alias TransformationPlan = rel[TransformationDescriptor desc, rel[loc begin, loc end]];

alias TransformationPlanProducer = TransformationPlan(str fileName, PathConfig cfg);

alias Rule = tuple[str ruleName, Path path];

alias PathCompiler = TransformationPlanProducer(list[Rule]);