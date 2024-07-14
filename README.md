# referenceLanguageCorpora (RLC)

This repository contains programming language grammars and example programs in those languages.

This collection is curated by Adrian Johnstone and Elizabeth Scott of the Centre for Software Language Engineering at Royal Holloway, University of London.

## Subdirectories

1. **languages** contains grammars and example inputs for well some well-known general purpose languages. The **rhul** subfolders contain examples that we have used in many of our research papers. For some languages we have also included large sets of examples drawn from publicly available repositories: we thank the owners of those repos for making the material available.
See the README.md file in individual directories for details on how these corpora were constructed.

2. **languages/ambiguityTest** contains 'torture' grammars designed to stress-test generalised parsing algorithms.

3. **experiments** contains scripts for running experiments using our own parser implementations, and data collected from those experiments.

## 'str' and 'tok' variants

The grammars and example inputs come in two flavours: tokenised (tok) and non-tokenised (str). Non-tokenised inputs are just normal example programs. The tokenised inputs have keyword-only lexical structure in which lexical elements whose pattern contains more than one lexeme are replaced by a keyword. This means, for instance, that all identifiers in a Java program are replaced by the keyword ID, all integer constants by the keyword INTEGER, all string constants by the keyword STRING and so on.

The purpose of the tokenised variants is to suppress the lexicalisation overhead for those algorithms that intermingle lexicalisation and parsing, enabling us to characterise the parser runtimes independently of the lexical complexity.

#### 'Full' and 'compressed white' space variants

For some inputs we provide compressed white space (**cws**) inputs in which every run of whitespace is replaced by a single space unless the run contains one or more newline characters, in which case the run is replaced by a single newline.

The purpose of the **cws** is again to normalise lexer performance so that long runs of whitespace do not introduce lexicalisation overheads for experiments that focus on parser performance. If you want 'real world' performance figues, then use the full variants.  

## Directory structure

The runGTB and runART scripts in **experiments** scan the entire **languages** directory structure, running experiments across all of the **str* and **tok** directories. 

A full run can be time consuming. You can suppress elements by moving them out of the directories that the scripts scan.

0 RLC root

---

1 .. experiments

2 .... runGTB (scann directory stucture and run GTB stubs)

2 .... runART  (scan directory stucture and run ART stubs)

3 ...... **scripts** (contains partial ART and GTB scripts that are concatenated with grammars)

4 ........ brnglr.gtb

4 ........ (more)

---

1 .. languages

2 .... java

3 ...... grammar

4 ........ jls13 (a specific grammar version)

5 .......... doc (the provenance of this grammar)

5 .......... **str** (grammars that include lexical rules)

5 .......... **tok** (grammars that expect inputs to be 'tokenised')

---

3 ...... corpus

4 ........ rhul (examples from our research papers)

5 .......... doc (the provenance of these inputs)

5 .......... src (the original version of each input)

5 .......... cws (compressed white space version of each input)

5 .......... **str** (inputs with full lexical structure)

5 .......... **tok** ('tokenised' inputs)

## Other resources
 
You may also find the following pages useful.

* Our production tool Ambiguity Retained Translation (ART) at https://github.com/AJohnstone2007/ART

* Our research papers at https://pure.royalholloway.ac.uk/en/persons/adrian-johnstone/publications

* There is a large curated collection of 'official' language grammars at https://slebok.github.io/zoo/ 

Adrian Johnstone, July 2024
