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

CHAR bullet_style=' ';

/* ------------------------------------------------ */

int check_style()
{
	while (ch!='>')
	{
		ch=get_attr();
		if CMP("TYPE", attr_name)
		{
			if CMP("disc", attr_ctnt)   { return '*'; }
			if CMP("square", attr_ctnt) { return '+'; }
			if CMP("circle", attr_ctnt) { return 'o'; }
		}
	}
	return 0;
}

/* ------------------------------------------------ */

void start_uls(int nooutput)
{
	line_break(nooutput);

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

void end_uls(int nooutput)
{
	spaces -= tab;
	line_break(nooutput);

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

void start_ols(int nooutput)
{
	start_uls(nooutput);
}

/* ------------------------------------------------ */

void end_ols(int nooutput)
{
	end_uls(nooutput);
}

/* ------------------------------------------------ */

void start_lis(int nooutput)
{
  spaces-=2;

	/* don't output line break, if this list item is immediately
	after a start or end list tag. start_uls and end_uls have
	already take care of the line break */
	if (!is_zeile_empty()) { line_break(nooutput); }

	wort_plus_ch(bullet_style);

	wort_ende(nooutput);
	spaces+=2;
}

/* ------------------------------------------------ */

void end_lis() { }

/* ------------------------------------------------ */

int definition_list=0;
void end_dd();

/* Definition List */
void start_dl(int nooutput)
{
	end_dd();
	start_p(nooutput);
}

void end_dl(int nooutput)
{
	paragraphen_ende(nooutput);

	end_dd();
}

/* Definition Title */
void start_dt(int nooutput)
{
	end_dd();

	line_break(nooutput);
}

void end_dt()
{
}

/* Definition Description */
void start_dd(int nooutput)
{
	end_dd();

	line_break(nooutput);
	spaces+=tab;

	definition_list=1;
}

void end_dd()
{
	if (definition_list==1)
	{
		spaces-=tab;
		definition_list=0;
	}
}

