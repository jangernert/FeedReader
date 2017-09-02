#ifndef text_h
#define text_h

#define DEF_STR_LEN 32768

#include "multibyte.h"

int LEFT;
int CENTER;
int RIGHT;

CHAR ch;

int paragraph;
int div_test;
int nooutput;

int breite;
int hr_breite;

void status();

int tab;
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
