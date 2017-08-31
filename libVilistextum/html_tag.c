/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 * 23.04.01 : Ignoring SPAN, /SPAN and /LI
 *            IMG, APPLET, AREA and INPUT are searched for ALT attribute
 * 13.08.01 : Ignoring DFN and /DFN
 * 24.08.01 : Fixed Frisskommentar
 * 02.09.01 : Ignoring BLINK, /BLINK, CITE and /CITE
 * 10.04.02 : Ignoring NOBR, /NOBR, SELECT, /SELECT, OPTION
 * 17.12.04 : html tags longer than DEF_STR_LEN are truncated
 *
 */

#include "multibyte.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "html.h"
#include "text.h"
#include "vilistextum.h"
#include "lists.h"
#include "fileio.h"
#include "charset.h"
#include "util.h"
#include "html_tag.h"

void html_tag(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	CHAR str[DEF_STR_LEN];
	int i=0;

	ch = uppercase(read_char(error));

	/* letter -> normal tag */
	/* '!' -> CDATA section or comment */
	/* '/' -> end tag */
	/* '?' -> XML processing instruction */
	if ((!isalpha(ch)) && (ch!='/') && (ch!='!') && (ch!='?'))
	{
		wort_plus_ch('<');
		putback_char(ch);
		/* fprintf(stderr, "no html tag: %c\n",ch); */
		return;
	}

	/* read html tag */
	while ((ch!='>') && (ch!=' ') && (ch!=13) && (ch!=10))
	{
		if (i<DEF_STR_LEN-1) { str[i++] = ch; }
		ch = uppercase(read_char(error));
	}
	str[i] = '\0';

	/* first all tags, that affect if there is any output at all */
	if CMP("SCRIPT", str)       { start_nooutput(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
	else if CMP("/SCRIPT", str) { end_nooutput(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
	else if CMP("STYLE", str)   { start_nooutput(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
	else if CMP("/STYLE", str)  { end_nooutput(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
	else if CMP("TITLE", str)
	{
		wort_ende(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
		print_zeile(nooutput, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
		nooutput = 1;
	}
	else if CMP("/TITLE", str)
	{
			wort_ende(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
			clear_line(zeilen_len, zeilen_pos);
			print_zeile(nooutput, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
			nooutput = 0;
	}

	if (nooutput==0) {
		if CMP("/HTML", str) {/* fprintf(stderr, "File ended!\n"); */ }
		else if CMP("!DOCTYPE", str)  { while ((ch=read_char(error))!='>'); }
		else if CMP("META", str)      { find_encoding(error); }
		else if CMP("?XML", str)      { find_xml_encoding(error); }

		/* Linebreak */
		else if CMP("BR", str)  { line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("BR/", str) { line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); } /* xhtml */

		else if CMP("P", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/P", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("BLOCKQUOTE", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/BLOCKQUOTE", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("Q", str)  { wort_plus_ch('"'); }
		else if CMP("/Q", str) { wort_plus_ch('"'); }


		/* headings */
		else if CMP("H1", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);          }
		else if CMP("/H1", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("H2", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);          }
		else if CMP("/H2", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("H3", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);          }
		else if CMP("/H3", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("H4", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);          }
		else if CMP("/H4", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("H5", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);          }
		else if CMP("/H5", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("H6", str)  { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);          }
		else if CMP("/H6", str) { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }

		else if CMP("HR", str)  { hr(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("HR/", str) { hr(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); } /* xhtml */

		else if CMP("LI", str)    { start_lis(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/LI", str)   { end_lis(); }
		else if CMP("UL", str)    { start_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/UL", str)   { end_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); return; }
		else if CMP("DIR", str)   { start_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }       /* deprecated */
		else if CMP("/DIR", str)  { end_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); return; } /* deprecated */
		else if CMP("MENU", str)  { start_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }       /* deprecated */
		else if CMP("/MENU", str) { end_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); return; } /* deprecated */
		else if CMP("OL", str)    { start_ols(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/OL", str)   { end_ols(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }

		else if CMP("DIV", str)      { start_div(0, nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/DIV", str)     { end_div(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("CENTER", str)   { start_div(CENTER, nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); } /* deprecated */
		else if CMP("/CENTER", str)  { end_div(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }         /* deprecated */
		else if CMP("RIGHT", str)    { start_div(RIGHT, nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/RIGHT", str)   { end_div(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }

		/* table */
		else if CMP("TABLE", str)    { /*start_p();*/ push_align(LEFT); neuer_paragraph(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("/TABLE", str)   { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("TD", str)       { wort_plus_ch(' '); }
		else if CMP("/TD", str)      {}
		else if CMP("TH", str)       { wort_plus_ch(' '); }
		else if CMP("/TH", str)      {}
		else if CMP("TR", str)       { line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); } /* start_p();  */
		else if CMP("/TR", str)      { /*paragraphen_ende();*/ }
		else if CMP("CAPTION", str)  {}
		else if CMP("/CAPTION", str) {}

		else if CMP("PRE", str)   { start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);  pre=1; }
		else if CMP("/PRE", str)  { paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); pre=0; }

		else if CMP("DL", str)  { start_dl(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);} /* Definition List */
		else if CMP("/DL", str) { end_dl(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }
		else if CMP("DT", str)  { start_dt(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); } /* Definition Title */
		else if CMP("/DT", str) { end_dt(); }
		else if CMP("DD", str)  { start_dd(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); } /* Definition Description */
		else if CMP("/DD", str) { end_dd(spaces); }

		/* tags for forms */
		else if CMP("FORM", str)      {}
		else if CMP("/FORM", str)     {}
		else if CMP("BUTTON", str)    {} /* TODO: extract name? */
		else if CMP("/BUTTON", str)   {}
		else if CMP("FIELDSET", str)  {}
		else if CMP("/FIELDSET", str) {}
		else if CMP("TEXTAREA", str)  {}
		else if CMP("/TEXTAREA", str) {}
		else if CMP("LEGEND", str)    {}
		else if CMP("/LEGEND", str)   {}
		else if CMP("LABEL", str)     {}
		else if CMP("/LABEL", str)    {}

		/* tags that have no visible effect */
		else if CMP("SAMP", str)      {}
		else if CMP("/SAMP", str)     {}
		else if CMP("CODE", str)      {}
		else if CMP("/CODE", str)     {}
		else if CMP("ABBR", str)      {}
		else if CMP("/ABBR", str)     {}
		else if CMP("ACRONYM", str)      {}
		else if CMP("/ACRONYM", str)     {}
		else if CMP("BIG", str)      {}
		else if CMP("/BIG", str)     {}
		else if CMP("VAR", str)      {}
		else if CMP("/VAR", str)     {}
		else if CMP("KBD", str)      {}
		else if CMP("/KBD", str)     {}

		/* tags that should have some visible effect */
		else if CMP("BDO", str)      {}
		else if CMP("/BDO", str)     {}
		else if CMP("INS", str)      {}
		else if CMP("/INS", str)     {}
		else if CMP("DEL", str)      {}
		else if CMP("/DEL", str)     {}
		else if CMP("S", str)         {} /* deprecated */
		else if CMP("/S", str)        {} /* deprecated */
		else if CMP("STRIKE", str)    {} /* deprecated */
		else if CMP("/STRIKE", str)   {} /* deprecated */

		/* those tags are ignored */
		else if CMP("HTML", str)      {}
		else if CMP("BASE", str)      {}
		else if CMP("LINK", str)      {}
		else if CMP("BASEFONT", str)  {} /* deprecated */

		else if CMP("HEAD", str)      {}
		else if CMP("/HEAD", str)     {}
		else if CMP("BODY", str)      {}
		else if CMP("/BODY", str)     {}
		else if CMP("FONT", str)      {} /* deprecated */
		else if CMP("/FONT", str)     {} /* deprecated */
		else if CMP("MAP", str)       {}
		else if CMP("/MAP", str)      {}
		else if CMP("SUP", str)       {}
		else if CMP("/SUP", str)      {}
		else if CMP("ADDRESS", str)   {}
		else if CMP("/ADDRESS", str)  {}
		else if CMP("TT", str)        {}
		else if CMP("/TT", str)       {}
		else if CMP("SUB", str)       {}
		else if CMP("/SUB", str)      {}
		else if CMP("NOSCRIPT", str)  {}
		else if CMP("/NOSCRIPT", str) {}
		else if CMP("SMALL", str)     {}
		else if CMP("/SMALL", str)    {}
		else if CMP("SPAN", str)      {}
		else if CMP("/SPAN", str)     {}
		else if CMP("DFN", str)       {}
		else if CMP("/DFN", str)      {}
		else if CMP("BLINK", str)     {}
		else if CMP("/BLINK", str)    {}
		else if CMP("CITE", str)      {}
		else if CMP("/CITE", str)     {}

		else if CMP("NOBR", str)      {}
		else if CMP("/NOBR", str)     {}
		else if CMP("SELECT", str)    {}
		else if CMP("/SELECT", str)   {}
		else if CMP("OPTION", str)    {}

		else if CMP("FRAME", str)  {}
		else if CMP("/FRAME", str) {}
		else if CMP("FRAMESET", str)  {}
		else if CMP("/FRAMESET", str) {}
		else if CMP("NOFRAMES", str)  {}
		else if CMP("/NOFRAMES", str) {}
		else if CMP("IFRAME", str)    {}
		else if CMP("/IFRAME", str)   {}
		else if CMP("LAYER", str)     {}
		else if CMP("/LAYER", str)    {}
		else if CMP("ILAYER", str)    {}
		else if CMP("/ILAYER", str)   {}
		else if CMP("NOLAYER", str)   {}
		else if CMP("/NOLAYER", str)  {}

		else if CMP("COL", str)       {}
		else if CMP("COLGROUP", str)  {}
		else if CMP("/COLGROUP", str) {}
		else if CMP("ISINDEX", str)   {} /* deprecated */
		else if CMP("THEAD", str)     {}
		else if CMP("/THEAD", str)    {}
		else if CMP("TFOOT", str)     {}
		else if CMP("/TFOOT", str)    {}
		else if CMP("TBODY", str)     {}
		else if CMP("/TBODY", str)    {}
		else if CMP("PARAM", str)     {}
		else if CMP("/PARAM", str)    {}
		else if CMP("OBJECT", str)    {}
		else if CMP("/OBJECT", str)   {}
		else if CMP("OPTGROUP", str)  {}
		else if CMP("/OPTGROUP", str) {}

		else if CMP("/AREA", str)     {}

		else if (STRNCMP("!--", str, 3)==0)  {
			putback_char(ch);
			putback_char(str[STRLEN(str)-1]);
			putback_char(str[STRLEN(str)-2]);
			ch = friss_kommentar(error);
		}

		/* these have to be ignored, to avoid the following error to show up */
		else if CMP("SCRIPT", str)    {}
		else if CMP("/SCRIPT", str)   {}
		else if CMP("STYLE", str)     {}
		else if CMP("/STYLE", str)    {}
		else if CMP("TITLE", str)     {}
		else if CMP("/TITLE", str)    {}
	}

	/* Skip attributes */
	while (ch!='>' && ch!=EOF)
	{
		ch = get_attr(error);
	}
}
