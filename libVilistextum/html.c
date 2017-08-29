/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 *
 *  history
 *  19.04.2001: get_attr parses text of a alt attribute
 *  20.04.2001: added references ala lynx
 *  24.08.2001: Frisskommentar could'nt cope with <!--comment-->
 *  03.09.2001: check_for_center worked only correct if align was last attribute
 *  22.03.2002: process_meta crashed if Contenttype was provided, but no charset
 *  10.04.2002: corrected check_for_center to prevent align_errors.
 *  28.01.2003: TAB and CR treated as white space.
 *  17.12.2004: fixed buffer overflow when attribute content longer than DEF_STR_LEN
 *
 */

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "vilistextum.h"
#include "html_tag.h"
#include "text.h"
#include "microsoft.h"
#include "latin1.h"
#include "fileio.h"
#include "charset.h"
#include "util.h"

int pre=0; /* for PRE-Tag */
int processed_meta=0; /* only parse meta tags once */

CHAR attr_name[DEF_STR_LEN], /* Attribut name of a HTML-Tag */
attr_ctnt[DEF_STR_LEN], /* Attribut content of a HTML-Tag */
link_inline[DEF_STR_LEN]; /* Link of a HTML-Tag */

/* ------------------------------------------------ */
#if !defined(__GNU_LIBRARY__)
#include <wchar.h>
static int wcscasecmp(const wchar_t *s1, const wchar_t *s2)
{
	size_t i;
	wint_t c1, c2;

	for (i = 0; s1[i] != L'\0' && s2[i] != L'\0'; i ++)
	{
		c1 = towlower(s1[i]);
		c2 = towlower(s2[i]);

		if (c1 != c2)
			return c1 - c2;
	}

	if (s1[i] != L'\0' && s2[i] == L'\0')
		return s1[i];

	if (s1[i] == L'\0' && s2[i] != L'\0')
		return -s2[i];

	return 0;
}
#endif

/* ------------------------------------------------ */


/* get the next attribute and writes it to attr_name and attr_ctnt. */
/* attr_name is converted to uppercase.  */
int get_attr()
{
	int i;
	CHAR temp[DEF_STR_LEN];
	attr_name[0] = '\0';
	attr_ctnt[0] = '\0';

	/* skip whitespace */
	while ((isspace(ch)) && (ch!='>')) { ch=read_char(); }
	if (ch=='>') { return '>'; };

	/* read attribute's name */
	i=1;
	attr_name[0] = ch;

	while ((ch!='=') && (ch!='>') && (ch!=EOF)) {
		ch=read_char();
		if (i<DEF_STR_LEN) { attr_name[i++] = ch; }
	} /* post cond: i<=DEF_STR_LEN */
	attr_name[i-1] = '\0';

	if (ch=='>') { attr_ctnt[0]='\0'; return '>'; }

	/* content of attribute */
	ch=read_char();
	/* skip white_space */
	while ((isspace(ch)) && (ch!='>')) { ch=read_char(); }
	temp[0] = '\0';

	/* if quoted */
	if ((ch=='"') || (ch=='\''))
	{
		/* attribute looks like alt="bla" or alt='bla'. */
		/* we'll have to remember what the quote was. */
		int quote=ch;
		i=0;
		ch=read_char();
		while(quote!=ch) {
			if(ch == EOF) { temp[i++] = quote; ch=quote; break; }
			if (i<DEF_STR_LEN-1) { temp[i++] = ch; }
			ch=read_char();
		} /* post cond: i<=DEF_STR_LEN-1 */
		temp[i] = '\0';
		ch=read_char();
	}
	else
	{
		/* attribute looks like alt=bla */
		i=1;
		temp[0] = ch;
		while ((ch!='>') && (!isspace(ch)) && (ch!=EOF)){
			ch=read_char();
			if (i<DEF_STR_LEN) { temp[i++] = ch; }
		} /* post cond: i<=DEF_STR_LEN */
		temp[i-1] = '\0';
	}

	uppercase_str(attr_name);
	if CMP("ALT", attr_name) { parse_entities(temp); }
	CPYSS(attr_ctnt, temp);

	return ch;
}

/* ------------------------------------------------  */

void html(int extractText, int nooutput, int spaces, int paragraph, int breite)
{
	int i;
	CHAR str[DEF_STR_LEN];

	for (i=0; i<DEF_STR_LEN; i++) { str[i]=0x00; }

	if(extractText)
	{
		for (;;)
		{
			ch = read_char();
			//printf("'%ls'\n", &ch);
			if(ch == EOF)
			{
				wort_ende(nooutput, spaces, breite);
				return;
			}
			switch (ch)
			{
				case '<':
					html_tag(nooutput, spaces, paragraph, breite);
					break;

				/* Entities  */
				case '&':
					i=1;
					str[0] = ch;
					do {
						ch = read_char();
						str[i++] = ch;
					}
					while ((isalnum(ch)) || (ch=='#'));

					/* if last char is no ';', then the string is no valid entity. */
					/* maybe it is something like &nbsp or even '& ' */
					if (ch!=';') {
						/* save last char  */
						putback_char(ch);
						/* no ';' at end */
						str[i-1] = '\0'; }
					else {
						/* valid entity */
						str[i] = '\0';
						/* strcpy(tmpstr, str); */
					}
					parse_entity(&str[0]);
					/* str contains the converted entity or the original string */
					wort_plus_string(str);
					break;

				case 173: /* soft hyphen, just swallow it */
					break;

				case   9: /* TAB */
					if (pre) {
						wort_plus_ch(0x09);
					} else {
						wort_ende(nooutput, spaces, breite);
					}
					break;

				case  13: /* CR */
				case '\n':
					wort_ende(nooutput, spaces, breite);
					if (pre) { line_break(nooutput, spaces, breite); }
					break;

				/* Microsoft ... */
				case 0x80: case 0x81: case 0x82: case 0x83: case 0x84: case 0x85: case 0x86: case 0x87:
				case 0x88: case 0x89: case 0x8a: case 0x8b: case 0x8c: case 0x8d:	case 0x8e: case 0x8f:
				case 0x90: case 0x91: case 0x92: case 0x93: case 0x94: case 0x95: case 0x96: case 0x97:
				case 0x98: case 0x99: case 0x9a: case 0x9b: case 0x9c: case 0x9d: case 0x9e: case 0x9f:
					if (convert_characters) { microsoft_character(ch); }
					else wort_plus_ch(ch);
					break;

				default:
					if (pre==0) {
						if (ch==' ') { wort_ende(nooutput, spaces, breite); }
						else { wort_plus_ch(ch); }
					}
					else { wort_plus_ch(ch); }
					break;
			}
		}
	}
	else
	{
		for (;;)
		{
			ch = read_char();
			if(ch == EOF)
			{
				wort_ende(nooutput, spaces, breite);
				return;
			}
			switch (ch)
			{
				/* Entities  */
				case '&':
					i=1;
					str[0] = ch;
					do {
						ch = read_char();
						str[i++] = ch;
					}
					while ((isalnum(ch)) || (ch=='#'));

					/* if last char is no ';', then the string is no valid entity. */
					/* maybe it is something like &nbsp or even '& ' */
					if (ch!=';') {
						/* save last char  */
						putback_char(ch);
						/* no ';' at end */
						str[i-1] = '\0'; }
					else {
						/* valid entity */
						str[i] = '\0';
						/* strcpy(tmpstr, str); */
					}
					parse_entity(&str[0]);
					/* str contains the converted entity or the original string */
					wort_plus_string(str);
					break;

				case 173: /* soft hyphen, just swallow it */
					break;

				case   9: /* TAB */
					if (pre) {
						wort_plus_ch(0x09);
					} else {
						wort_ende(nooutput, spaces, breite);
					}
					break;

				case  13: /* CR */
				case '\n':
					wort_ende(nooutput, spaces, breite);
					if (pre) { line_break(nooutput, spaces, breite); }
					break;

				/* Microsoft ... */
				case 0x80: case 0x81: case 0x82: case 0x83: case 0x84: case 0x85: case 0x86: case 0x87:
				case 0x88: case 0x89: case 0x8a: case 0x8b: case 0x8c: case 0x8d:	case 0x8e: case 0x8f:
				case 0x90: case 0x91: case 0x92: case 0x93: case 0x94: case 0x95: case 0x96: case 0x97:
				case 0x98: case 0x99: case 0x9a: case 0x9b: case 0x9c: case 0x9d: case 0x9e: case 0x9f:
					if (convert_characters) { microsoft_character(ch); }
					else wort_plus_ch(ch);
					break;

				default:
					if (pre==0) {
						if (ch==' ') { wort_ende(nooutput, spaces, breite); }
						else { wort_plus_ch(ch); }
					}
					else { wort_plus_ch(ch); }
					break;
			}
		}
	}
}

/* ------------------------------------------------ */

/* used when there's only the align-attribut to be checked  */
void check_for_center()
{
	int found=0;
	while (ch!='>' && ch!=EOF)
	{
		ch=get_attr();
		if CMP("ALIGN", attr_name)
		{
			found=1;
			uppercase_str(attr_ctnt);
			if CMP("LEFT",   attr_ctnt) { push_align(LEFT);  }
			else if CMP("CENTER", attr_ctnt) { push_align(CENTER); }
			else if CMP("RIGHT",  attr_ctnt) { push_align(RIGHT); }
			else if CMP("JUSTIFY", attr_ctnt) { push_align(LEFT); }
			else { if (errorlevel>=2) { fprintf(stderr, "No LEFT|CENTER|RIGHT found!\n"); push_align(LEFT); } }
		}
	}
	/* found no ALIGN  */
	if (found==0) { push_align(LEFT); }
}

/* ------------------------------------------------ */

void start_p(int nooutput, int spaces, int paragraph, int breite)
{
	push_align(LEFT);
	neuer_paragraph(nooutput, spaces, paragraph, breite);
	check_for_center();
}

/* ------------------------------------------------ */

void start_div(int a, int nooutput, int spaces, int breite)
{
	line_break(nooutput, spaces, breite);
	if (a!=0) { push_align(a); }
	else { check_for_center(); }
}

/* ------------------------------------------------ */

void end_div(int nooutput, int spaces, int paragraph, int breite)
{
	wort_ende(nooutput, spaces, breite);

	if (paragraph!=0) { paragraphen_ende(nooutput, spaces, paragraph, breite); }
	else { print_zeile(nooutput, breite); }
	pop_align(); /* einer für start_div */
}

/* ------------------------------------------------ */

void print_footnote_number(CHAR *temp, int number)
{
	swprintf(temp, 1000, L"[%d]", number);
}
void construct_footnote(CHAR *temp, int number, CHAR *link)
{
	swprintf(temp, 1000, L" %3d. %ls\n", number, link);
}

/* ------------------------------------------------ */

char *schemes[] = {"ftp://","file://" ,"http://" ,"gopher://" ,"mailto:" ,"news:" ,"nntp://" ,"telnet://" ,"wais://" ,"prospero://" };

/* ------------------------------------------------ */

/* find alt attribute in current tag */
void image(CHAR *alt_text, int show_alt)
{
	int found_alt=0;
	while (ch!='>' && ch!=EOF)
	{
		ch=get_attr();
		if CMP("ALT", attr_name)
		{
			/*printf("+1+\n"); */
			if (!(remove_empty_alt && CMP("", attr_ctnt))) {
				/*printf("+2+\n"); */
				if (!option_no_alt)
				{ wort_plus_ch('['); wort_plus_string(attr_ctnt); wort_plus_ch(']');}
			}
			found_alt=1;
		}
	}

	if ((found_alt==0) && (show_alt)) {
		if (!option_no_image)
		{
			wort_plus_ch('['); wort_plus_string(alt_text); wort_plus_ch(']');
		}
	}
}

/* ------------------------------------------------ */

/* extract encoding information from META or ?xml tags */
void find_encoding()
{
	int found_ctnt=0;
	int found_chst=0;
	int found_ecdg=0;
	CHAR *locale=NULL;
	char stripped_locale[DEF_STR_LEN];
	CHAR temp_locale[DEF_STR_LEN];

	if (!processed_meta) {
		while (ch!='>' && ch!=EOF) {
			ch=get_attr();
			if ((CMP("HTTP-EQUIV", attr_name)) || (CMP("NAME", attr_name))) {
				if STRCASECMP("Content-Type", attr_ctnt) { found_ctnt=1; }
				else if STRCASECMP("charset", attr_ctnt) { found_chst=1; }
			} else if CMP("CONTENT", attr_name) {
				CPYSS(temp_locale, attr_ctnt);
			} else if CMP("ENCODING", attr_name) {
				CPYSS(temp_locale, attr_ctnt);
				found_ecdg=1;
			}
		}
		if (found_ctnt||found_chst||found_ecdg) {
			if (found_ctnt) {
				locale = wcsstr(temp_locale, L"charset=");
				if (locale!=NULL) { locale += 8; }
			} else if (found_chst||found_ecdg) {
				locale = temp_locale;
			}

			found_ctnt=0; found_chst=0; found_ecdg=0;
			/* search and set character set */
			if (locale!=NULL) {
				strip_wchar(locale, stripped_locale);
				/* Yahoo Search does strange things to cached pages */
				if (strcmp(stripped_locale, "Array")!=0) {
					if (strcmp(stripped_locale, "x-user-defined")==0) {
						use_default_charset();
					} else {
						set_iconv_charset(stripped_locale);
					}
				  processed_meta=1;
				}
			}
		}
	}
}

/* ------------------------------------------------ */

/* extract encoding information ?xml tags */
void find_xml_encoding()
{
	if (!processed_meta) {
		/* xml default charset is utf-8 */
		set_iconv_charset("utf-8");
		find_encoding();
	}
}

/* ------------------------------------------------ */

/* simple finite state machine to eat up complete comment '!--' */
CHAR friss_kommentar()
{
	int c, dontquit=1;
	while (dontquit)
	{
		c=read_char();
		if (c=='-')
		{
			c=read_char();
			while (c=='-')
			{
				c=read_char();
				if (c=='>') { dontquit=0; }
			}
		}
	}

	return c;
}

/* ------------------------------------------------ */

int start_nooutput(int nooutput, int spaces, int breite)
{
	wort_ende(nooutput, spaces, breite);
	print_zeile(nooutput, breite);
	nooutput = 1;

	while (ch!='>' && ch!=EOF)
	{
		ch=get_attr();
		if CMP("/", attr_name)
		{
			printf("Empty tag\n");
			nooutput = 0;
		}
	}
	return nooutput;
}

int end_nooutput(int nooutput, int spaces, int breite)
{
	wort_ende(nooutput, spaces, breite);
	print_zeile(nooutput, breite);
	nooutput = 0;
	return nooutput;
}

/* ------------------------------------------------ */
