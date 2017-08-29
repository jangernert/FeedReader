#ifndef text_h
#define text_h

#define DEF_STR_LEN 32768

#include "multibyte.h"

const int LEFT;
const int CENTER;
const int RIGHT;
const int tab;
const int hr_breite;

CHAR ch;

int breite;

void print_zeile(int nooutput);
int is_zeile_empty();
void clear_line();

void push_align(int a);

void wort_plus_string(CHAR *s);
void wort_plus_ch(int c);
void wort_ende(int nooutput, int spaces);

void line_break(int nooutput, int spaces);

void paragraphen_ende(int nooutput, int spaces, int paragraph);
void neuer_paragraph(int nooutput, int spaces, int paragraph);

void hr(int nooutput, int spaces, int paragraph);

#endif 
