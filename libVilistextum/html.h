#ifndef html_h
#define html_h 1

#include "text.h"
#include "multibyte.h"

int pre;

int get_attr();
int get_new_attr(CHAR *name, CHAR *content);

CHAR attr_name[DEF_STR_LEN];
CHAR attr_ctnt[DEF_STR_LEN];

void html(int extractText, int nooutput);
void check_for_center();
void start_p(int nooutput);
void start_div(int a, int nooutput);
void end_div(int nooutput);
void image(CHAR *, int);
CHAR friss_kommentar();

void find_encoding();
void find_xml_encoding();

void href_link_inline_output();

void start_nooutput(int nooutput);
void end_nooutput(int nooutput);
#endif
