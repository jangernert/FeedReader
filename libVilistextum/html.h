#ifndef html_h
#define html_h 1

#include "text.h"
#include "multibyte.h"

int pre;

int get_attr(int error);
int get_new_attr(CHAR *name, CHAR *content);

CHAR attr_name[DEF_STR_LEN];
CHAR attr_ctnt[DEF_STR_LEN];

void html(int extractText, int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len);
void check_for_center(int error);
void start_p(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len);
void start_div(int a, int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_div(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len);
CHAR friss_kommentar(int error);

void find_encoding(int error);
void find_xml_encoding(int error);

void href_link_inline_output();

void start_nooutput(int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_nooutput(int nooutput, int spaces, int breite, int error, int zeilen_len);
#endif
