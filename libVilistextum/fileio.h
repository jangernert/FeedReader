#ifndef fileio_h
#define fileio_h 1

#include "multibyte.h"

void open_files(char *input);
void output_string(CHAR *str);
void convert_string(char *str, CHAR *converted_string);

int get_current_char();
int read_char();
void putback_char(CHAR c);
void quit();
CHAR* getOutput();

#endif
