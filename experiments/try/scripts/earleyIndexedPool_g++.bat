java -jar tools/art/art.jar v3 %1 !earleyIndexedData
g++ -O3 -I. -Itools/earlyFromARTV3InCpp -oARTEarleyIndexedPool tools/earlyFromARTV3InCpp/ARTEarleyIndexedPool.cpp
./ARTEarleyIndexedPool %2

