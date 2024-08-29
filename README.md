# Reference Language Corpora (RLC)

This repository contains programming language grammars and example programs in those languages.

This collection is curated by Adrian Johnstone and Elizabeth Scott of the Centre for Software Language Engineering at Royal Holloway, University of London.

## Subdirectories

**languages** contains grammars and example inputs for well some well-known general purpose languages. The **rhul** subfolders contain examples that we have used in many of our research papers. For some languages we have also included large sets of examples drawn from publicly available repositories: we thank the owners for making the material available.
See the README.md file in individual directories for details on how these corpora were constructed.

**experiments** contains scripts for running experiments using our own parser implementations, and data collected from those experiments.

## 'org', 'cws' and 'tok' variants

The example inputs come in three flavours: the original strings as produced by the programmer (org), compressed whitespace versions (cws) and tokenised versions(tok). 

**org** inputs are just normal example programs. 

**cws** inputs contain the same strings as the corresponding **org** input except that every run of whitespace is replaced by a single space unless the run contains one or more newline characters, in which case the run is replaced by a single newline. The purpose of the **cws** variants is to normalise lexer performance so that long runs of whitespace do not introduce lexicalisation overheads for experiments that focus on parser performance. 

**tok** inputs have keyword-only lexical structure in which lexical elements whose pattern contains more than one lexeme are replaced by a keyword. This means, for instance, that all identifiers in a Java program are replaced by the keyword ID, all integer constants by the keyword INTEGER, all string constants by the keyword STRING and so on.

## Running experiments

`experiments/RunExp.java` scans the entire **languages** directory structure, running experiments specified in **experiments/try** and producing `log.csv`, `timeSummary.csv` and `spaceSummary.csv`

## Directory structure

0 RLC root

---

1 .. experiments

2 .... scripts *(a collection of ART and GTB stub scripts that are concatenated with grammars)*

2 .... results *(results from some of our experimental runs)*	

2 .... `RunExp.java` *(Scan directory stucture and run experiments)*

2 .... **try** *(the subset of scripts to be used in the next run)*

---

1 .. languages

2 .... *(more languages...)*

---

2 .... java

3 ...... build *( language standards and programs to construct the corpora )*

3 ...... grammar

4 ........ *(more grammars for java...)*

4 ........ jls18 *(grammars from the Java Language Specification version 18)*

5 .......... **org** *(grammar group for jls18 that include full lexical rules)*

5 .......... **tok** *(grammar group for jls18 that expect inputs to be 'tokenised')*

3 ...... corpus

4 ........ *(more corpora for Java...)*

4 ........ jfx	 *(a specific corpus for Java)*

5 .......... **org** *(the original version of each input)*

5 .......... **cws** *(compressed white space version of each input)*

5 .......... **tok** *('tokenised' input group)*

## Other resources
 
You may also find the following pages useful.

* There is a large curated collection of 'official' language grammars at https://slebok.github.io/zoo/ (not owned or maintained by us)

* Our research papers at https://pure.royalholloway.ac.uk/en/persons/adrian-johnstone/publications

* Our production tool Ambiguity Retained Translation (ART) at https://github.com/AJohnstone2007/ART

You will find source code and pre-built executables for GTB and the tokenisers that produce our **tok** variants in the **old** directory of the ART repository.

Adrian Johnstone, August 2024
