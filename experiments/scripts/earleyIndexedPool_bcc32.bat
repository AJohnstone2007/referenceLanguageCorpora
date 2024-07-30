java -jar tools/art/art.jar v3 %1 !earleyIndexedData
bcc32 -I. -Itools/earlyFromARTV3InCpp tools/earlyFromARTV3InCpp/ARTEarleyIndexedPool.cpp
ARTEarleyIndexedPool %2

