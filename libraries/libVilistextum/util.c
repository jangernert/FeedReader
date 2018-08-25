/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 * 08.03.02: align[0] hasn't been set by push_align
 * 18.02.02: some multibyte code not enclosed by define's
 *           uppercase now available in onebyte and multibyte version
 *           include ctype.h for toupper
 * 10.04.02: changed the align stack code to let it work on the amiga
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <wctype.h>

#include "vilistextum.h"
#include "multibyte.h"

/* Dynamic align added by autophile@starband.net 29 Mar 2002 */
int *align = NULL;
int align_nr=0,
align_size=0;

/* ------------------------------------------------ */

int get_align()
{
	/* Dynamic align added by autophile@starband.net 29 Mar 2002 */
	if (align==NULL)
	{
		align = (int *)malloc(256*sizeof(int));
		align[0] = 1; /* default LEFT alignment. */
	}
	return(align[align_nr]);
}

/* ------------------------------------------------ */

void push_align(int a)
{
	align_nr++;

	/* Dynamic align added by autophile@starband.net 29 Mar 2002 */
	if (align_nr >= align_size)
	{
		align_size += 256;
		align = realloc(align, align_size*sizeof(int));
	}

	/*	if (div_test!=0) { align[align_nr]=div_test; } else {  */
	align[align_nr]=a; /*} */
}

void pop_align()
{
	if (align_nr==0) { if (errorlevel>=5) { fprintf(stdout, "Error: align_nr=0\n");} }
	else { align_nr--; }
}

/* ------------------------------------------------ */

wint_t uppercase(wint_t c)
{
	if ((c>='a') && (c<='z')) { c=towupper(c); }
	return c;
}

/* ------------------------------------------------ */

void uppercase_str(CHAR *s)
{
	int i=0;
	while(s[i]!='\0') { s[i]=uppercase(s[i]); i++; }
}

/* ------------------------------------------------ */

/* copy the character to the string */
void set_char(CHAR *s, CHAR c)
{
	s[0] = c;
	s[1] = '\0';
}

/* ------------------------------------------------ */

int x2dec(CHAR *str, int base)
{
	int i=0,
	current_nr=0,
	nr=0;
	int len=STRLEN(str);

	for (i=0;i<len;i++)
	{
		current_nr=str[i];
		nr*=base;
		if ((current_nr>='0') && (current_nr<='9')) { nr += current_nr-'0'; }
		else
		{
			current_nr = towupper(current_nr)-'A'+10;
			if ((current_nr>=10) && (current_nr<base)) { nr += current_nr; }
			else { return(nr/base); }
		}
	}
	return nr;
}

/* ------------------------------------------------ */

void print_error(char *error, CHAR *text)
{
	fprintf(stderr, "%s%ls\n", error, text);
}

/* ------------------------------------------------ */

/* return the value of an numeric character entity
	 e.g: 169 for "&#169;" or "&#xA9" */
int extract_entity_number(CHAR *s)
{
	int number;
	CHAR *tmp = s;

	/* Numeric entity */
	if ((s[0]=='&') && (s[1]=='#')) {
		/* Hex entity */
		if (uppercase(s[2])=='X')
		{
			tmp += 3;
			number = x2dec(tmp, 16);
		}
		/* Decimal entity */
		else {
			tmp += 2;
			number = ATOI(tmp);
		}
		return(number);
	} else {
		return(-1);
	}
}

/* ------------------------------------------------ */
