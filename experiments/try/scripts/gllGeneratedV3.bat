java -jar %1 v3 %2
javac -cp %1 ARTGeneratedParser.java ARTGeneratedLexer.java
rem gotcha: on Windows entries are separated by ; but on Unix :
java -cp .;%1 ARTV3TestGenerated %3


