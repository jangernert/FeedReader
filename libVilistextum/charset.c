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
	char in[33], out[33];
	size_t result=(size_t)(-1);
	int i;
	int converted; /* has the entity been successfully converted */

	char *inp, *outp;
	size_t insize = 1, outsize = 32;

	/* no conversion needed */
	if (option_output_utf8) {
		outstring[0] = num;
		outstring[1] = L'\0';
		return 1;
	}

	for (i=0; i<33; i++) { in[i]=0x00; out[i]=0x00; }
	inp  = in;
	outp = out;
	insize = wctomb(inp, num);

	if ((conv = iconv_open(iconv_charset, "utf-8"))==(iconv_t)(-1))
	{
		printf("iconv_open failed in convert_character: wrong character set?\n");
		perror(iconv_charset);
		return -1;
	}

	result = iconv(conv, &inp, &insize, &outp, &outsize);
	iconv_close(conv);

	if (result==(size_t)(-1))
	{
		converted = 0;
		/* if the entity is 160 (nbsp), use ' ' instead */
		if (num==160) {
			converted = 1;
			outstring[0] = L' '; outstring[1] = L'\0';
		}
	} else {
		converted = 1;
		outstring[0] = num;
		outstring[1] = L'\0';
	}

	return(converted);
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
