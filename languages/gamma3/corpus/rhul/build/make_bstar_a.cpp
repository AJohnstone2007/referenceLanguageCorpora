#include <stdio.h>

int main(void) {

  for (int i = 1; i <=300; i++) {
    char *filename = "ba.000";

    sprintf(filename + 3, "%03i", i);

    printf("%s\n", filename);

    FILE *f = fopen(filename, "w");

    for (int j = 0; j < i; j++)
      fprintf(f, "b\n");

    fprintf(f,"a\n");

    fclose(f);
  }
    
}
