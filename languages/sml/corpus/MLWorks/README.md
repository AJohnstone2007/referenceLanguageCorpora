## Provenance

ml-works collected from https://github.com/Ravenbrook/mlworks 5 July 2022 15.30 BST

## Procedure for creating flattened directories

1. Unzip one of the source zip files
2. dir /b /s xyz-master\*.lll > xyzFlatten.bat
3. Use emacs to convert each line <file> of xyzSourceCopy.bat to: copy <file> xyzSource
4. Run xyzFlatten.bat

## Summary file counts after flattening

Github		|Directory	|In zip		|After flat copy	|(lost)	|[proportion]
download	|		|Files		|Files	|Bytes		|	|	
---		|---		|---		|---	|---		|---	|---
mlWorks-master	|mlwSource	|1 984		|1 798	|13 188 297	 |(186)	|[-9.4%]

## SML corpus: compress comments and spaces, and attach a terminating ;

ART directive !compressWhitespaceSML idSML idSML replaces all strings of whitespace with either a single space, or if the string contains a newline, a single '\n'

In addition, all Unicode characters that are not ASCII are mapped to \uXXXX.

Batchfile SML\filter.bat creates smlSourceCompressed from the files in smlSource

See ART source file ARTCompressWhiteSpaceSML.java for details of the compression
