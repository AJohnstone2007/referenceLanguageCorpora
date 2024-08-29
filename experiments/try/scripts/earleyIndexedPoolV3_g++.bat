java -jar %1 v3 %2 !earleyIndexedData
g++ -O3 -I. -Itools/earlyFromARTV3InCpp -oARTEarleyIndexedPool tools/earlyFromARTV3InCpp/ARTEarleyIndexedPool.cpp
./ARTEarleyIndexedPool %3

