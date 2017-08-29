/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 */

#include "multibyte.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "text.h"
#include "vilistextum.h"
#include "html.h"
#include "fileio.h"
#include "util.h"

const int LEFT = 1;
const int CENTER = 2;
const int RIGHT = 3;

const int tab = 4; /* tabulator */
const int hr_breite = 76;

CHAR wort[DEF_STR_LEN];

CHAR zeile[DEF_STR_LEN];
int  zeilen_len=0,       /* apparent length of the line  */
zeilen_len_old=0,
zeilen_pos=0,       /* true length of line */
wort_len=0,         /* apparent length of the word */
wort_pos=0,         /* true length of word */
anz_leere_zeilen=0, /* how many line were blank */
noleadingblanks=0;  /* remove blanks lines at the start of the output */

/* ------------------------------------------------ */

void center_zeile(int breite)
{
	int i,j;

	/* ensure that the string is not the empty string */
	if (zeilen_len!=0)
	{
		/* ensure that centering is possible */
		if (zeilen_pos<breite)
		{
			j=(breite-zeilen_len)/2;

			for (i=zeilen_pos+j; i>=0; i--)
			{
				zeile[i+j]=zeile[i];
			}
			for (i=0; i<j; i++) { zeile[i]=' '; }
		}
	}
}

/* ------------------------------------------------ */

void right_zeile(int breite)
{
	int i,j;

	if (zeilen_len!=0)
	{
		j=breite-zeilen_len;
		for (i=zeilen_pos+j+2; i>=0; i--)
		{
			zeile[i+j]=zeile[i];
		}
		for (i=0; i<j; i++) { zeile[i]=' '; }
	}
}

/* ------------------------------------------------ */

/* return true, if z is all spaces or nonbreakable space */
int only_spaces(CHAR *z)
{
	int len=STRLEN(z);
	int i, ret=1;
	CHAR j;

	for (i=0; i<len; i++) { j=z[i]; ret = (ret && ((j==' ')||(j==160))); }
	return(ret);
}

/* ------------------------------------------------ */

void clear_line() {
	zeile[0]='\0';
	zeilen_len=0; zeilen_pos=0;
}

/* ------------------------------------------------ */

/* print line */
void print_zeile(int nooutput, int breite, int error)
{
	int printzeile;

	if (only_spaces(zeile))
	{
		clear_line();
		anz_leere_zeilen++;
	} else {
		anz_leere_zeilen=0;
	}

	/* Don't allow leading blank lines.
	That means the first line of the output is never an empty line */
	if (noleadingblanks==0) { noleadingblanks = !only_spaces(zeile); }

	printzeile = (!(noleadingblanks==0));

	if (printzeile)
	{
		if (get_align()==LEFT)   {}
		if (get_align()==CENTER) { center_zeile(breite); }
		if (get_align()==RIGHT)  { right_zeile(breite); }

		if (!nooutput)
		{
			output_string(zeile, error);
		}

		zeilen_len_old=zeilen_len;
		clear_line();
	}
}

/* ------------------------------------------------ */

int is_zeile_empty()
{
	return(zeile[0]=='\0');
}

/* ------------------------------------------------ */

void zeile_plus_wort(CHAR *s, int wl, int wp)
{
	int i=zeilen_pos,
	j=0;

	if (zeilen_pos+wp<DEF_STR_LEN-1) {
		while (i<zeilen_pos+wp) { zeile[i] = s[j]; j++; i++; }
		zeile[i] = '\0';
		zeilen_len += wl; zeilen_pos += wp;
	}
}

/* ------------------------------------------------ */

void wort_plus_string_nocount(CHAR *s)
{
	int len=STRLEN(s),
	i=wort_pos,
	j=0;

	if (wort_pos+len<DEF_STR_LEN-1) {
		while (i<wort_pos+len) { wort[i] = s[j]; j++; i++; }
		wort[i] = '\0';
		wort_pos += len;
	}
}

/* ------------------------------------------------ */

void wort_plus_string(CHAR *s)
{
	int len=STRLEN(s),
	i=wort_pos,
	j=0;

	if (wort_pos+len<DEF_STR_LEN-1) {
		while (i<wort_pos+len) { wort[i] = s[j]; j++; i++; }
		wort[i] = '\0';
		wort_pos += len; wort_len += len;
	}
}

/* ------------------------------------------------ */

void wort_plus_ch(int c)
{
	if (wort_pos<DEF_STR_LEN-1) {
		wort[wort_pos++] = c;
		wort_len++;
	}
}

/* ------------------------------------------------ */

void wort_ende(int nooutput, int spaces, int breite, int error)
{
	int i=0;

	if (wort_len > 0)
	{
		wort[wort_pos] = '\0';

		if (zeilen_len+wort_len+1 > breite)
		{
			print_zeile(nooutput, breite, error);
			i=0;
			while (i<spaces) { zeile_plus_wort(ONESPACE,1,1); i++; }
			zeile_plus_wort(ONESPACE,1,1);
			zeile_plus_wort(wort, wort_len, wort_pos);
		}
		else if (zeilen_len != 0)
		{
			/* add space + word */
			zeile_plus_wort(ONESPACE,1,1);
			zeile_plus_wort(wort,wort_len, wort_pos);
		}
		else /* zeilen_len==0 => new beginning of a paragraph */
		{
			i=0;
			while (i<spaces) { zeile_plus_wort(ONESPACE,1,1); i++; }
			zeile_plus_wort(ONESPACE,1,1);
			zeile_plus_wort(wort,wort_len, wort_pos);
		}
		wort_pos = 0;
		wort_len = 0;
	}
}

/* ------------------------------------------------ */

void line_break(int nooutput, int spaces, int breite, int error)
{
	wort_ende(nooutput, spaces, breite, error);
	print_zeile(nooutput, breite, error);
}

/* ------------------------------------------------ */

void paragraphen_ende(int nooutput, int spaces, int paragraph, int breite, int error)
{
	if (paragraph!=0)
	{
		line_break(nooutput, spaces, breite, error);
		print_zeile(nooutput, breite, error);
		paragraph--;
		pop_align();
	}
}

/* ------------------------------------------------ */

void neuer_paragraph(int nooutput, int spaces, int paragraph, int breite, int error)
{
	if (paragraph!=0) { paragraphen_ende(nooutput, spaces, paragraph, breite, error); }
	line_break(nooutput, spaces, breite, error);
	print_zeile(nooutput, breite, error);
	paragraph++;
}

/* ------------------------------------------------ */

void hr(int nooutput, int spaces, int paragraph, int breite, int error)
{
	int i, hr_width=hr_breite-4, hr_align=CENTER;
	while (ch!='>')
	{
		ch=get_attr(error);
		if CMP("ALIGN", attr_name)
		{
			uppercase_str(attr_ctnt);
			if CMP("LEFT", attr_ctnt) { hr_align=LEFT;   }
			else if CMP("CENTER",  attr_ctnt) { hr_align=CENTER; }
			else if CMP("RIGHT",   attr_ctnt) { hr_align=RIGHT;  }
			else if CMP("JUSTIFY", attr_ctnt) { hr_align=LEFT;  }
		}
		else if CMP("WIDTH", attr_name)
		{
			i=STRLEN(attr_ctnt);
			if (attr_ctnt[i-1]=='%') {
				attr_ctnt[i-1] = '\0';
				hr_width = ATOI(attr_ctnt);
				if (hr_width==100) { hr_width = hr_breite-4; }
				else { hr_width = hr_breite*hr_width/100; }
			} else {
				hr_width = ATOI(attr_ctnt)/8;
				if (hr_width>hr_breite-4) { hr_width = hr_breite-4; }
			}
		}
	}

	neuer_paragraph(nooutput, spaces, paragraph, breite, error);
	push_align(hr_align);
	for (i=0; i<hr_width; i++) { wort_plus_ch('-'); }
	paragraphen_ende(nooutput, spaces, paragraph, breite, error);
}
