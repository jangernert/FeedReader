#ifndef vilistextum_h
#define vilistextum_h

#include "multibyte.h"

int error;
int palm;
int convert_tags;
int errorlevel;
int convert_characters;
int shrink_lines;
int remove_empty_alt;
int option_links;
int option_links_inline;
int option_title;
int sevenbit;
int transliteration;

int option_no_image;
int option_no_alt;
int option_output_utf8;

CHAR* default_image;

CHAR* vilistextum(char* text, int extractText);

#endif
