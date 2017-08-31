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
 
#define _POSIX_C_SOURCE 2 /* for popen, pclose */
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <locale.h>
#include <stdlib.h>
#include <iconv.h>

#include "vilistextum.h"
#include "text.h"
#include "multibyte.h"
#include "charset.h"

char *default_charset = "iso-8859-1";
char iconv_charset[DEF_STR_LEN];
int usr=0;
iconv_t conv;
char internal_locale[256];

/* ------------------------------------------------ */

static int suffix(const char * str, const char * suffix)
{
	if ( strlen(str) < strlen(suffix) ) return 0;
	if ( ! strcmp(suffix, str + ( strlen(str) - strlen(suffix) ) ) ) return 1;
	return 0;
}

static int utf_8_locale(const char * locale)
{
	if (!locale) return 0;
	return suffix(locale,".utf8") || suffix(locale, ".UTF-8");
}

int init_multibyte(int error)
{
	char *locale_found;
	locale_found = setlocale(LC_CTYPE, "");
	
	if (locale_found == NULL)
	{
		FILE *fp = popen("locale -a", "r");
		if (fp)
		{
			while (!feof(fp) && !locale_found)
			{
				char buf[256];
				if (fgets(buf, sizeof(buf), fp) != NULL)
				{
					/* remove newline */
					buf[strlen(buf)-1] = '\0';
					/* check for a working UTF-8 locale */
					if (utf_8_locale(buf) &&
					(locale_found = setlocale(LC_CTYPE, buf)))
					{
						strcpy(internal_locale, buf);
					}
				}
			}
		}
	}
	
	
	if (locale_found == NULL)
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
	strcat(iconv_charset, "//TRANSLIT");
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
