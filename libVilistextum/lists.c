/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 * 04.09.01: added some more bullet_styles.
 * 15.03.04: lists generate less newlines
 *
 */

#include <stdio.h>
#include <string.h>

#include "html.h"
#include "text.h"
#include "util.h"
#include "lists.h"

CHAR bullet_style=' ';
int definition_list=0;

/* ------------------------------------------------ */

void start_uls(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);

	push_align(LEFT);

	/* * o + # @ - = ~ $ % */
	if (bullet_style==' ') { bullet_style='*'; }
	else if (bullet_style=='*') { bullet_style='o'; }
	else if (bullet_style=='o') { bullet_style='+'; }
	else if (bullet_style=='+') { bullet_style='#'; }
	else if (bullet_style=='#') { bullet_style='@'; }
	else if (bullet_style=='@') { bullet_style='-'; }
	else if (bullet_style=='-') { bullet_style='='; }
	else if (bullet_style=='=') { bullet_style='~'; }
	else if (bullet_style=='~') { bullet_style='$'; }
	else if (bullet_style=='$') { bullet_style='%'; }

	spaces += tab;
}

void end_uls(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	spaces -= tab;
	line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);

	if (bullet_style=='%') { bullet_style='$'; }
	else if (bullet_style=='$') { bullet_style='~'; }
 	else if (bullet_style=='~') { bullet_style='='; }
 	else if (bullet_style=='=') { bullet_style='-'; }
	else if (bullet_style=='-') { bullet_style='@'; }

	else if (bullet_style=='@') { bullet_style='#'; }
	else if (bullet_style=='#') { bullet_style='+'; }
	else if (bullet_style=='+') { bullet_style='o'; }
	else if (bullet_style=='o') { bullet_style='*'; }
	else if (bullet_style=='*') { bullet_style=' '; }

	pop_align();
}

/* ------------------------------------------------ */

void start_ols(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	start_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
}

/* ------------------------------------------------ */

void end_ols(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	end_uls(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
}

/* ------------------------------------------------ */

void start_lis(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	spaces-=2;

	/* don't output line break, if this list item is immediately
	after a start or end list tag. start_uls and end_uls have
	already take care of the line break */
	if (!is_zeile_empty()) { line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos); }

	wort_plus_ch(bullet_style);

	wort_ende(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
	spaces+=2;
}

/* ------------------------------------------------ */

void end_lis() { }

/* ------------------------------------------------ */

void end_dd();

/* Definition List */
void start_dl(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	end_dd(spaces);
	start_p(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
}

void end_dl(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	paragraphen_ende(nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);

	end_dd(spaces);
}

/* Definition Title */
void start_dt(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	end_dd(spaces);

	line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
}

void end_dt()
{
}

/* Definition Description */
void start_dd(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old, int zeilen_pos)
{
	end_dd(spaces);

	line_break(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old, zeilen_pos);
	spaces+=tab;

	definition_list=1;
}

void end_dd(int spaces)
{
	if (definition_list==1)
	{
		spaces-=tab;
		definition_list=0;
	}
}

