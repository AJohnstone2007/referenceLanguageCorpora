#include <stdio.h>

int main(void) {

  for (int i = 1; i <=300; i+=10) {
    char *filename = "bb_bbba.000";

    sprintf(filename + 8, "%03i", i*2+4);

    printf("%s\n", filename);

    FILE *f = fopen(filename, "w");

    for (int j = 0; j < i; j++)
      fprintf(f, "b b\n");

    fprintf(f,"b b b a\n");

    fclose(f);
  }
    
}
