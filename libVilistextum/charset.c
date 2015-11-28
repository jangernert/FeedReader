/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 *  history
 *  14.10.2001: creation of this file
 *
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <locale.h>
#include <stdlib.h>
#include <iconv.h>

#include "vilistextum.h"
#include "text.h"
#include "multibyte.h"

char *default_charset = "iso-8859-1";
char iconv_charset[DEF_STR_LEN];
int usr=0;
iconv_t conv;

/* ------------------------------------------------ */

int init_multibyte()
{
	char *ret;
	ret = setlocale(LC_CTYPE, "");
	if (ret==NULL)
	{
		fprintf(stderr, "setlocale failed with: \"\"\n\n");
		error = 1;
		return 0;
	}
	return 1;
}

/* ------------------------------------------------ */

int convert_character(int num, CHAR *outstring)
{
	outstring[0] = num;
	outstring[1] = L'\0';
	return 1;
}

/* ------------------------------------------------ */

char* get_iconv_charset()
{
	return(iconv_charset);
}

/* ------------------------------------------------ */

void set_iconv_charset(char *charset)
{
	/* set charset for iconv conversion */
	strcpy(iconv_charset, charset);
	if (transliteration) { strcat(iconv_charset, "//TRANSLIT");}
}

/* ------------------------------------------------ */

void use_default_charset() { set_iconv_charset(default_charset); }

/* ------------------------------------------------ */

void strip_wchar(CHAR *locale, char *stripped_locale)
{
	CHAR *in  = locale;
	char *out = stripped_locale;
	int len;
	int i;

	len = STRLEN(locale);
	/* copy stripped string to out */
	for (i=0; i<len; i++) { out[i] = wctob(in[i]); }
	out[i] = 0x00;
}
/* ------------------------------------------------ */
