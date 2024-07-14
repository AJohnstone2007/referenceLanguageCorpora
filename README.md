# referenceLanguageCorpora (RLC)

This repository contains programming language grammars and example programs in those languages.

This collection is curated by Adrian Johnstone and Elizabeth Scott of the Centre for Software Language Engineering at Royal Holloway, University of London.

## Subdirectories

1. **languages** contains grammars and example inputs for well some well-known general purpose languages. The **rhul** subfolders contain examples that we have used in many of our research papers. For some languages we have also included large sets of examples drawn from publicly available repositories: we thank the owners of those repos for making the material available.
See the README.md file in individual directories for details on how these corpora were constructed.

2. **languages/ambiguityTest** contains 'torture' grammars designed to stress-test generalised parsing algorithms.

3. **experiments** contains scripts for running experiments using our own parser implementations, and data collected from those experiments.

## Directory structure

The scripts in **experiments** scan the directory structure, running experiments across the whole repo which can be time consuming. You can suppress elements by moving them out of the directories that the scripts scan.

RLC root

.. experiments

.. languages

.... c

......grammar

........ansic

..........str

..........tok

......corpus

........rhul

..........doc

..........src

..........str

..........tok

## Other resources
 
You may also find the following pages useful.

* Our production tool Ambiguity Retained Translation (ART) at https://github.com/AJohnstone2007/ART

* Our research papers at https://pure.royalholloway.ac.uk/en/persons/adrian-johnstone/publications

* There is a large curated collection of 'official' language grammars at https://slebok.github.io/zoo/ 

Adrian Johnstone, July 2024
