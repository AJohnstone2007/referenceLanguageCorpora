java -jar %1 v3 %2
javac -cp %1 ARTGeneratedParser.java ARTGeneratedLexer.java
java  -cp %1 ARTTest %3
