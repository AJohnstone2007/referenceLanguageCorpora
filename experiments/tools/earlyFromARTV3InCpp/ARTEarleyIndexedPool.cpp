#include<stdlib.h>
#include<stdio.h>
#include<ctype.h>
#include<string.h>

#include "ARTStaticSlotArray.h"
#include "ARTMain.cpp"

  int epsilonSPPFNode;

  // An accepting slot is a single integer index into the tables in the
  // ARTSlotArray structure: that is a 1:0
  int acceptingSlotsSet;

  // An Earley item is a slot x input position x SPPF node : nothing, that is a
  // 3:0
   int earleyItemSlotOffset = 0; // An element of the enumeration
   int earleyItemIndexOffset = 1;
   int earleyItemSPPFNodeOffset = 2;

  int* eSets; // An integer array holding an array of pool sets
  int qSet, qPrimeSet, rSet, vSet;

  // An hMap is a map from nonterminal |-> SPPF node, that is a 1:1
   int hMapNonterminalOffset = 0;
   int hMapSPPFNodeOffset = 1;

  int hMap;

  // An SPPF node is slot/nonterminal/terminal/epsilon x leftExtent x rightExtent
  // : (small) set of packedNodes, that is a 3:1
   int sppfNodeLabelOffset = 0; // An element of the enumeration
   int sppfNodeLeftExtentOffset = 1; // An integer offset
   int sppfNodeRightExtentOffset = 2; // An integer offset
   int sppfFamilyOffset = 3; // A table map with the packed nodes in it

  // A packed node is a pair of SPPF nodes, that is a 2:0
   int packedNodeLeftChildOffset = 0;
   int packedNodeRightChildOffset = 1;
  int sppf;

  // Hash table sizes
   int acceptingSlotsBucketCount = 20;
   int sppfNodePerLevelBucketCount = 300;
   int sppfNodeFullBucketCount = 500000;
   int sppfNodeFamilyBucketCount = 5;
   int earleyItemPerLevelBucketCount = 40;
   int qPrimeBucketCount = 40;

  // For C...

   bool isNonterminal(int symbol) {
   return symbol > epsilon && symbol < firstSlotNumber;
  }

   bool isNonterminalOrEpsilon(int symbol) {
   return symbol == 0 || (symbol >= epsilon && symbol < firstSlotNumber);
  }

   bool isTerminal(int symbol) {
   return symbol > eoS && symbol < epsilon;
  }

  // End of language customisation

  bool inSigmaN(int p) {
    return isNonterminalOrEpsilon(slotRightSymbols[p]);
  }

  // This is a quick and dirty lexicaliser which does not support ART's special
  // lexical features or character level tokens - startIndex specifies the first
  // live
  // elemeng of ret[]h
  // Used for quick test of simple parsers

  #if (0)
   int strlen(const char* str) {
    int ret = 0;
    if (str == NULL) return 0;
    while (str[ret] != 0)
      ret++;
    return ret;
  }
  #endif

  // MAKE_NODE(B ::= αx · β, j, i, w, v, V) {
  int makeNode(int betaSlot, int j, int i, int w, int v, int vSet) {// vSet2 is reallt SPPF?

    // if β = epsilon { let s = B } else { let s = (B ::= αx · β) }
    int s;
    if (slotRightSymbols[betaSlot] == 0)
      s = slotLHSSymbols[betaSlot];
    else
      s = betaSlot;

    // if α = epsilon and β != epsilon { let y = v }
    int y; // SPPFNode
    int postAlphaSlot = betaSlot - 2;
    if (slotRightSymbols[postAlphaSlot] == 0 && slotRightSymbols[betaSlot] != 0) {
      y = v;
    }
    // else {
    else {
      // if there is no node y in V labelled (s, j, i) create one and add it to V
      y = mapFind_3_1(sppf, s, j, i);

      // if w = NULL and y does not have a family of children (v) add one
      // First, ensure y has a set...
      if (poolGet(y + sppfFamilyOffset) == 0) // Is there a set?
        poolPut(y + sppfFamilyOffset, mapMake(sppfNodeFamilyBucketCount));

      if (w == 0)
        mapFind_2_0(poolGet(y + sppfFamilyOffset), 0, v);
      // if w != NULL and y does not have a family of children (w, v) add one }
      else
        mapFind_2_0(poolGet(y + sppfFamilyOffset), w, v);
    }

    // return y
    return y;
  }

  void artParse(const char* stringInput, const char* inputFilename) {
    loadSetupTime();
    int* input = dynamicLexicaliseLongestMatch(stringInput, 1);

    if (input == NULL) {
      printf("ARTEarleyIndexedPool: reject lexical");

      return;
    }

    inputTokenLength = inputLengthFromLexer - 2; // input[0] is not used and input[n+1] is $


    loadLexTime();

    poolInit(20, 1024); // 1024 x 1Mlocation blocks: at 32-buit integers that 4G of memory when fully
                                  // allocated
    epsilonSPPFNode = poolAllocate(4);
    poolPut(epsilonSPPFNode, epsilon);

    int p;
    acceptingSlotsSet = mapMake(acceptingSlotsBucketCount); // One per production of the start rule, so
                                                                             // just a small set
    for (int productionNumber = 0; (p = slotIndex[startSymbol][productionNumber]) != 0; productionNumber++) {
      // Kick past production
      p++;
      // !! update p to be the accepting slot!
      while (slotRightSymbols[p] != 0)
        p++;

      mapFind_1_0(acceptingSlotsSet, p);
    }

    eSets = new int[inputTokenLength + 1];
    for (int i = 0; i < inputTokenLength + 1; i++)
      eSets[i] = mapMake(earleyItemPerLevelBucketCount);
    rSet = mapMake(earleyItemPerLevelBucketCount);
    qSet = mapMake(earleyItemPerLevelBucketCount);
    qPrimeSet = mapMake(qPrimeBucketCount);
    vSet = mapMake(sppfNodePerLevelBucketCount);
    hMap = mapMake(sppfNodePerLevelBucketCount);
    sppf = mapMake(sppfNodeFullBucketCount);

    // for all (S ::= α) ∈ P { if α ∈ ΣN add (S ::= ·α, 0, NULL) to E0
    // if α = a1 α′ add (S ::= ·α, 0, NULL) to Q′ } !! Q' is now Q[0] for this
    // initialisation phase
    for (int productionNumber = 0; (p = slotIndex[startSymbol][productionNumber]) != 0; productionNumber++) {
    if (!mergedSets[slotGuardSetAddresses[p + 1]][input[1]]) continue;
/** lookahead refactoring here ***/
      if (inSigmaN(p))
        mapFind_3_0(eSets[0], p + 1, 0, 0);
      else
        mapFind_3_0(qPrimeSet, p + 1, 0, 0);
    }
    // for 0 ≤ i ≤ n {
    for (int i = 0; i <= inputTokenLength; i++) {
      // printSets();
      // H = ∅, R = Ei , Q = Q′
      mapClear(hMap);
      mapAssign(rSet, eSets[i]);
      mapAssign(qSet, qPrimeSet);

      // Q′ = ∅
      mapClear(qPrimeSet);

      // while R ! = ∅ {
      while (mapCardinality(rSet) != 0) {

        // remove an element, Λ say, from R
        int lambda = mapRemove(rSet);

        int c = slotRightSymbols[poolGet(lambda + earleyItemSlotOffset)];
        int h = poolGet(lambda + earleyItemIndexOffset);
        int w = poolGet(lambda + earleyItemSPPFNodeOffset);

        // if Λ = (B ::= α · Cβ, h, w) {
        if (isNonterminal(c)) {
          // for all (C ::= δ) ∈ P {
          int deltaSlot;
          for (int productionNumber = 0; (deltaSlot = slotIndex[c][productionNumber]) != 0; productionNumber++) {
            // if δ ∈ ΣN and (C ::= ·δ, i, NULL) ! ∈ Ei {
            deltaSlot++; // Move to first child
            if (!mergedSets[slotGuardSetAddresses[deltaSlot]][input[i+1]]) continue;
/** lookahead refactoring here ***/
            if (inSigmaN(deltaSlot)) {
              if (mapLookup_3(eSets[i], deltaSlot, i, 0) == 0) {
                // add (C ::= ·δ, i, NULL) to Ei and R }
                mapFind_3_0(eSets[i], deltaSlot, i, 0);
                mapFind_3_0(rSet, deltaSlot, i, 0);
              }
            } else
                mapFind_3_0(qSet, deltaSlot, i, 0);
          }

          // if ((C, v) ∈ H) {
          int v;
          int hMapElement;
          int betaPreSlot = poolGet(lambda + earleyItemSlotOffset) + 1;
          if ((hMapElement = mapLookup_1(hMap, c)) != 0 && mergedSets[slotGuardSetAddresses[betaPreSlot]][input[i+1]]) {
            v = poolGet(hMapElement + hMapSPPFNodeOffset);
            // let y = MAKE_NODE(B ::= αC · β, h, i, w, v, V)
            int y = makeNode(betaPreSlot, h, i, w, v, vSet);
            // if β ∈ ΣN and (B ::= αC · β, h, y) ! ∈ Ei {
/** lookahead refactoring here ***/
            if (inSigmaN(betaPreSlot)) {
              if (mapLookup_3(eSets[i], betaPreSlot, h, y) == 0) {
                // add (C ::= ·δ, i, NULL) to Ei and R }
                mapFind_3_0(eSets[i], betaPreSlot, h, y);
                mapFind_3_0(rSet, betaPreSlot, h, y);
              }
            } else
                mapFind_3_0(qSet, betaPreSlot, h, y);
          }
        }

        // if Λ = (D ::= α·, h, w) {
        int D = slotLHSSymbols[poolGet(lambda + earleyItemSlotOffset)];
        if (slotRightSymbols[poolGet(lambda + earleyItemSlotOffset)] == 0
            || slotRightSymbols[poolGet(lambda + earleyItemSlotOffset)] == epsilon) {
          // if w = NULL {
          if (w == 0) {
            // if there is no node v in V labelled (D, i, i) create one
            int v = mapFind_3_1(sppf, D, i, i);

            // set w = v
            w = v;
            // if w does not have family (epsilon) add one }
            if (poolGet(w + sppfFamilyOffset) == 0) // Is there a set?
              poolPut(w + sppfFamilyOffset, mapMake(sppfNodeFamilyBucketCount));
            mapFind_2_0(poolGet(w + sppfFamilyOffset), epsilonSPPFNode, 0);
          }
          // if h = i { add (D, w) to H }
          if (h == i) mapFind_1_1(hMap, D, w);

          // for all (A ::= τ · Dδ, k, z) in Eh {
          for (int e = mapIteratorFirst1(eSets[h]); e != 0; e = mapIteratorNext1()) {
            int deltaPreSlot = poolGet(e + earleyItemSlotOffset) + 1;
            if (!mergedSets[slotGuardSetAddresses[deltaPreSlot]][input[i+1]]) continue;
            // major inefficiency here: rework as a set of hashmaps from D to items
            if (slotRightSymbols[poolGet(e + earleyItemSlotOffset)] == D) {
              // let y = MAKE_NODE(A ::= τ D · δ, k, i, z, w, V)
              int k = poolGet(e + earleyItemIndexOffset);
              int z = poolGet(e + earleyItemSPPFNodeOffset);
              int y = makeNode(deltaPreSlot, k, i, z, w, vSet);
              // if δ ∈ ΣN and (A ::= τ D · δ, k, y) ! ∈ Ei {
/** lookahead refactoring here ***/
              if (inSigmaN(deltaPreSlot)) {
                if (mapLookup_3(eSets[i], deltaPreSlot, k, y) == 0) {
                  // add (C ::= ·δ, i, NULL) to Ei and R }
                  mapFind_3_0(eSets[i], deltaPreSlot, k, y);
                  mapFind_3_0(rSet, deltaPreSlot, k, y);
                }
              } else
                  mapFind_3_0(qSet, deltaPreSlot, k, y);
            }
          }
        }
      }
      // V=∅
      mapClear(vSet);
      // create an SPPF node v labelled (ai+1 , i, i + 1)
      if (i != inputTokenLength) {
        int v = mapFind_3_1(sppf, input[i + 1], i, i + 1);
        // while Q ! = ∅ {
        while (mapCardinality(qSet) != 0) {
          // remove an element, Λ = (B ::= α · ai+1 β, h, w) say, from Q
          int lambda = mapRemove(qSet);

          int postAlphaSlot = poolGet(lambda + earleyItemSlotOffset);
          int h = poolGet(lambda + earleyItemIndexOffset);
          int w = poolGet(lambda + earleyItemSPPFNodeOffset);
          // let y = MAKE_NODE(B ::= α ai+1 · β, h, i + 1, w, v, V)
          int preBetaSlot = postAlphaSlot + 1;
          if (!mergedSets[slotGuardSetAddresses[preBetaSlot]][input[i+2]]) continue;

          int y = makeNode(preBetaSlot, h, i + 1, w, v, vSet);
          // if β ∈ ΣN { add (B ::= α ai+1 · β, h, y) to Ei+1 }
/** lookahead refactoring here ***/
          if (inSigmaN(preBetaSlot))
            mapFind_3_0(eSets[i + 1], preBetaSlot, h, y);
          else
            mapFind_3_0(qPrimeSet, preBetaSlot, h, y);
          

#if 0
          if (inSigmaN(preBetaSlot)) {
            mapFind_3_0(eSets[i + 1], preBetaSlot, h, y);
          }
          // if β = ai+2 β′ { add (B ::= α ai+1 · β, h, y) to Q′ }
          if (slotRightSymbols[preBetaSlot] != 0 && slotRightSymbols[preBetaSlot] == input[i + 2]) {
            mapFind_3_0(qPrimeSet, preBetaSlot, h, y);
          }
#endif
        }
      }
    }

    // if (S ::= τ ·, 0, w) ∈ En return w

    loadParseTime();
    // Scan eSets.get(inputTokenLength) to look for accepting slots and some w, then
    // return w
    for (int e = mapIteratorFirst1(eSets[inputTokenLength]); e != 0; e = mapIteratorNext1()) {
      int offset = poolGet(e + earleyItemIndexOffset);
      int slot = poolGet(e + earleyItemSlotOffset);

      if (offset == 0 && mapLookup_1(acceptingSlotsSet, slot) != 0) {
        artIsInLanguage = true;
        return;
      }
    }
  }

