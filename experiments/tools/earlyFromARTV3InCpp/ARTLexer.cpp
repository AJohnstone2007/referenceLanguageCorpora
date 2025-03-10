#include<stdlib.h>
#include<stdio.h>
#include<ctype.h>
#include<string.h>

  bool isSubstringAt(const char* full, int start, const char* sub) {
    int subStart = 0;

    while (full[start] != 0 && sub[subStart] != 0 && full[start] == sub[subStart]) {
      start++;
      subStart++;
    }

    return sub[subStart] == 0;
  }

  const char* stringToString(const char* c) {
    const char* ret = "";
    for (int i = 0; c[i] != 0; i++)
      ret += c[i];
    return ret;
  }

    int inputLengthFromLexer;
    int* dynamicLexicaliseLongestMatch(const char* input, int startIndex) {
    // End of language customisation

    inputStringLength = strlen(input);
    int* ret = NULL;
    int stringStart, retIndex;

    for (int pass = 0; pass < 2; pass++) {
      retIndex = stringStart = 0;
      for (int i = startIndex; i > 0; i--) {
        if (ret != NULL) ret[retIndex] = eoS; // Dummy EoS at element zero which is not used for Earley
        retIndex++;
      }

      int longestTerminal, longestTerminalLength;

      while (stringStart < inputStringLength && isspace(input[stringStart]))
        stringStart++;

      while (stringStart < inputStringLength) {
        longestTerminal = longestTerminalLength = 0;
        for (int t = eoS + 1; t < epsilon; t++) {

          if (isSubstringAt(input, stringStart, symbolStrings[t])) {
            if (strlen(symbolStrings[t]) > longestTerminalLength) {
              longestTerminal = t;
              longestTerminalLength = strlen(symbolStrings[t]);
            }
          }
        }
        if (ret != NULL) ret[retIndex] = longestTerminal;
        if (longestTerminal == 0) return NULL; // lexicalisation error
        stringStart += strlen(symbolStrings[longestTerminal]);
        // Just do whitespace for all terminals in this version... if (!(ret[retIndex]
        // instanceof ARTGrammarElementTerminalCharacter))
        while (stringStart < inputStringLength && isspace(input[stringStart]))
          stringStart++;
        retIndex++;
      }
      // set a_{n+1} = $
      if (ret != NULL) ret[retIndex] = eoS;
      retIndex++;

      if (ret == NULL) ret = new int[retIndex];
    }
    inputLengthFromLexer = retIndex;
    return ret;
  }

