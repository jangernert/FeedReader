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

void print_zeile(int nooutput, int breite, int error, int zeilen_len, int zeilen_len_old);
int is_zeile_empty();
void clear_line(int zeilen_len);

void push_align(int a);

void wort_plus_string(CHAR *s);
void wort_plus_ch(int c);
void wort_ende(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old);

void line_break(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old);

void paragraphen_ende(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old);
void neuer_paragraph(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old);

void hr(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old);

#endif 
