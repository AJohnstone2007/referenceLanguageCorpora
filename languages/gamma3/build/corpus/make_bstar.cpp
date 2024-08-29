#include <stdio.h>

int main(void) {

  for (int i = 1; i <=300; i++) {
    char *filename = "b.000";

    sprintf(filename + 2, "%03i", i);

    printf("%s\n", filename);

    FILE *f = fopen(filename, "w");

    for (int j = 0; j < i; j++)
      fprintf(f, "b\n");

    fclose(f);
  }
    
}
