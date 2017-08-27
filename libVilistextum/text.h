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

int paragraph;
int nooutput;

int breite;

int spaces;

void print_zeile();
int is_zeile_empty();
void clear_line();

void push_align(int a);
void pop_align();

void wort_plus_string(CHAR *s);
void wort_plus_ch(int c);
void wort_ende();

void line_break();

void paragraphen_ende();
void neuer_paragraph();

void hr();

#endif 
