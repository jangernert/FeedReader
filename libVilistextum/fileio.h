#ifndef fileio_h
#define fileio_h 1

#include "multibyte.h"

void init_buffer(char *input, int error);
void output_string(CHAR *str, int error);

int get_current_char();
int read_char(int error);
void putback_char(CHAR c);
void finalize(int nooutput, int spaces, int breite, int error);
char* getOutput();

struct TextBuffer
{
	FILE* input;
	CHAR* output;
};

#endif
