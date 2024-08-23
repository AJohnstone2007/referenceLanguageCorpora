java -jar tools/art/art.jar v3 %1 !earleyTableIndexedData
g++ -O3 -I. -Itools/earlyFromARTV3InCpp -oARTEarleyTableIndexedPool tools/earlyFromARTV3InCpp/ARTEarleyTableIndexedPool.cpp
./ARTEarleyTableIndexedPool %2

