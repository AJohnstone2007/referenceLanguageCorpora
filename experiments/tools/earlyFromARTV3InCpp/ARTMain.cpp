/********************************************************************************
 * ARTMain.cpp - mainline function ART generated parsers
 *
 *******************************************************************************/
#include<stdio.h>
#include <stdlib.h>
#include "stats.cpp"
#include "ARTPool.cpp"
#include "ARTLexer.cpp"

extern void artParse(const char*  stringInput, const char* inputFilename);

char * fileRead(char* filename) {
  FILE *f = fopen(filename, "r");
  if (f == NULL) {
    printf("Unable to open file '%s'", filename);
    exit(1);
  }

// Size the file
  int c = ' ';
  int size = 0;
  while (c != EOF) {
    size++;
    c = getc(f);
  }

  size--;

//  printf("\n!!ARTMain: input %s contains %i characters\n", filename, size);

  char* buffer = (char*) malloc(sizeof(char) * (size + 1));
  f = fopen(filename, "r");

  for (int i = 0; i < size; ++i) {
    buffer[i] = (char) getc(f);
  }
  buffer[size] = 0;

  return buffer;
}


int main (int argc, char *argv[]) {

  if (argc < 2){
    printf("No input filename supplied");
    exit(1);
  }

  char* input = fileRead(argv[1]);

  resetStats();
  artParse(input, argv[1]);
  artLog();
}

