java -jar tools/art/art.jar v3 %1 !earleyTableIndexedData
bcc32 -I. -Itools/earlyFromARTV3InCpp tools/earlyFromARTV3InCpp/ARTEarleyTableIndexedPool.cpp
ARTEarleyTableIndexedPool %2

