#ifndef util_h
#define util_h 1

#include "multibyte.h"

int get_align();
void push_align(int a);
void pop_align();

int uppercase(int c);
void uppercase_str(CHAR *s);

void set_char(CHAR *s, CHAR c);

int x2dec(CHAR *s, int base);

void print_error(char *error, CHAR *text);

int extract_entity_number(CHAR *s);

#endif
