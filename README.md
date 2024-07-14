# referenceLanguageCorpora (RLC)

This repository contains programming language grammars and example programs in those languages.

This collection is curated by Adrian Johnstone and Elizabeth Scott of the Centre for Software Language Engineering at Royal Holloway, University of London.

## Subdirectories

1. **languages** contains grammars and example inputs for well some well-known general purpose languages. The **rhul** subfolders contain examples that we have used in many of our research papers. For some languages we have also included large sets of examples drawn from publicly available repositories: we thank the owners for making the material available.
See the README.md file in individual directories for details on how these corpora were constructed.

2. **languages/ambiguityTest** contains 'torture' grammars designed to stress-test generalised parsing algorithms.

3. **experiments** contains scripts for running experiments using our own parser implementations, and data collected from those experiments.

## 'str' and 'tok' variants

The grammars and example inputs come in two flavours: tokenised (tok) and non-tokenised (str). Non-tokenised inputs are just normal example programs. The tokenised inputs have keyword-only lexical structure in which lexical elements whose pattern contains more than one lexeme are replaced by a keyword. This means, for instance, that all identifiers in a Java program are replaced by the keyword ID, all integer constants by the keyword INTEGER, all string constants by the keyword STRING and so on.

The purpose of the tokenised variants is to suppress the lexicalisation overhead for those algorithms that intermingle lexicalisation and parsing, enabling us to characterise the parser runtimes independently of the lexical complexity.

#### 'Full' and 'compressed white space' variants

For some inputs we provide compressed white space (**cws**) inputs in which every run of whitespace is replaced by a single space unless the run contains one or more newline characters, in which case the run is replaced by a single newline. 

The purpose of the **cws** variants is again to normalise lexer performance so that long runs of whitespace do not introduce lexicalisation overheads for experiments that focus on parser performance. 

The tokenisation process that produces the **tok** files automatically compresses white space.

## Running bulk experiments

The `runGTB` and `runART` scripts in **experiments** scan the entire **languages** directory structure, running experiments specified in **experiments/try** across all of the **str** and **tok** directories. 

The idea is that you load the **try**, **str** and **tok** directories with the elements that you want to characterise. After a run, the file **log.csv** will contain summary statistics.

You will need to edit `runGTB` and `runART` to specify the location of your GTB executables and your ART JAR. You can also specify the number of times each experiment is run; we use this to get 10 results for each experiment so as to smooth out timing irregularities by discarding the two fastest and two slowest runs,and then taking the mean runtimes of the remaining six.

**A full run can be time consuming.**

## Directory structure

0 RLC root

---

1 .. experiments

2 .... scripts *(a collection of ART and GTB stub scripts that are concatenated with grammars)*

2 .... `runGTB` *(script to scan directory stucture and run GTB stub scripts)*

2 .... `runART`  *(script to scan directory stucture and run ART stub scripts)*

2 .... **try** *(the subset of stub scripts to be used in the next run)*

3 ...... brnglr.gtb *(example script stub for running BRNGLR under GTB)*

3 ...... *(more script stubs...)*

---

1 .. languages

2 .... *(more languages...)*

---

2 .... java

3 ...... grammar

4 ........ *(more grammars for java...)*

4 ........ jls18 *(grammars from the Java Language Specification version 18)*

5 .......... doc *(provenance)*

5 .......... **str** *(grammars for jls18 that include full lexical rules)*

5 .......... **tok** *(grammars for jls18 that expect inputs to be 'tokenised')*

3 ...... corpus

4 ........ *(more corpora for Java...)*

4 ........ jfx	 *(a specific corpus for Java)*

5 .......... doc *(the provenance of these inputs)*

5 .......... src *(the original version of each input)*

5 .......... cws *(compressed white space version of each input)*

5 .......... **str** *(inputs to be scanned with full lexical structure)*

5 .......... **tok** *('tokenised' inputs to be scanned)*

## Other resources
 
You may also find the following pages useful.

* There is a large curated collection of 'official' language grammars at https://slebok.github.io/zoo/ (not owned or maintained by us)

* Our research papers at https://pure.royalholloway.ac.uk/en/persons/adrian-johnstone/publications

* Our production tool Ambiguity Retained Translation (ART) at https://github.com/AJohnstone2007/ART

You will find source code and pre-built executables for GTB and the tokenisers that produce our **tok** variants in the **old** directory of the ART repository.

Adrian Johnstone, July 2024
