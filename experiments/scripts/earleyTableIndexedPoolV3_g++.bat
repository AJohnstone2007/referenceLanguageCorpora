java -jar %1 v3 %2 !earleyTableIndexedData
g++ -O3 -I. -Itools/earlyFromARTV3InCpp -oARTEarleyTableIndexedPool tools/earlyFromARTV3InCpp/ARTEarleyTableIndexedPool.cpp
./ARTEarleyTableIndexedPool %3


