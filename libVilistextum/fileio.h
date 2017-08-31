#ifndef fileio_h
#define fileio_h 1

#include "multibyte.h"

void init_buffer(char *input, int error);
void output_string(CHAR *str);

int get_current_char();
int read_char(int error);
void putback_char(CHAR c);
void finalize(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
char* getOutput();

struct TextBuffer
{
	FILE* input;
	CHAR* output;
};

#endif
