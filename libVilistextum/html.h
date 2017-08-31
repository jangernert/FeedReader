#ifndef html_h
#define html_h 1

#include "text.h"
#include "multibyte.h"

int pre;

int get_attr(int error);
int get_new_attr(CHAR *name, CHAR *content);

CHAR attr_name[DEF_STR_LEN];
CHAR attr_ctnt[DEF_STR_LEN];

void html(int extractText, int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
void check_for_center(int error);
void start_p(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
void start_div(int a, int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
void end_div(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
CHAR friss_kommentar(int error);

void find_encoding(int error);
void find_xml_encoding(int error);

void href_link_inline_output();

int start_nooutput(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
int end_nooutput(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos);
#endif
