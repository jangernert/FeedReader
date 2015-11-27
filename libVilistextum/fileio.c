/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 *  history
 *  18.04.2001 : incorporated stdin/stdout patch from Luke Ravitch
 */

#include "multibyte.h"
#include "charset.h"

#include <stdio.h>

#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include "text.h"
#include "html.h"
#include "charset.h"
#include "multibyte.h"
#include "vilistextum.h"

#include <iconv.h>
#include <locale.h>

FILE *in;

CHAR curr_ch;
CHAR OUTPUT[DEF_STR_LEN];
CHAR LINEBREAK[1] = L"\n";

/* ------------------------------------------------ */

void open_files(char *input)
{
	//if ((in = fopen(input, "r")) == 0)
	if((in = fmemopen(input, strlen(input), "r"))==0)
	{
		fprintf(stderr, "Couldn't open input file %s!\n",input);
		error = 1;
	}
}

/* ------------------------------------------------ */


void convert_string(char *str, CHAR *converted_string)
{
	iconv_t conv;
	char output[DEF_STR_LEN];
	char *inp, *outp;
	int fehlernr=0;
	size_t insize, outsize;
	char *ret;

	/* set locale based on environment variables */
	ret = setlocale(LC_CTYPE, "");
	if (ret==NULL) {
		fprintf(stderr, "setlocale failed with: %s\n\n", getenv("LC_CTYPE"));
		error = 1;
	}

	insize = strlen(str);
	if (insize > DEF_STR_LEN) { insize = DEF_STR_LEN; }
	outsize = DEF_STR_LEN;

	inp = str;
	outp = output;

	if ((conv = iconv_open("utf-8", "char"))==(iconv_t)(-1))
	{
		fprintf(stderr, "convert_string: iconv_open failed. Can't convert from %s to UTF-8.\n",
		getenv("LC_CTYPE"));
		error = 1;
	}

	iconv(conv, &inp, &insize, &outp, &outsize);
	fehlernr = errno;

	if (fehlernr==E2BIG) { fprintf(stderr, "errno==E2BIG\n"); }
	else if (fehlernr==EILSEQ) {
		fprintf(stderr, "convert_string: Can't interpret '%s' as character from charset %s\n", str, getenv("LC_CTYPE"));
		fprintf(stderr, "convert_string: Check your language settings with locale(1)\n");
	}
	else if (fehlernr==EINVAL) { fprintf(stderr, "convert_string: errno==EINVAL\n"); }

	output[strlen(output)] = '\0';

	ret = setlocale(LC_CTYPE, "utf-8");
	if (ret==NULL) {
		fprintf(stderr, "setlocale failed with: %s\n\n", "utf-8");
		error = 1;
	}
	mbstowcs(converted_string, output, strlen(output));

	iconv_close(conv);
}

/* ------------------------------------------------ */

void output_string(CHAR *str)
{
	if (option_output_utf8) {
		/* internal locale is utf-8, no conversion needed */
		wcscat(OUTPUT, str);
		wcscat(OUTPUT, LINEBREAK);
	}
}

/* ------------------------------------------------ */

CHAR* getOutput()
{
	return OUTPUT;
}

/* ------------------------------------------------ */

void quit()
{
	if (!is_zeile_empty()) { wort_ende(); print_zeile(); }
}

/* ------------------------------------------------ */

int read_char()
{
	int c = ' ';
	int fehlernr=0; /* tmp variable for errno */
	static int i=0;
	int j=0,k;
	wchar_t outstring[33];
	iconv_t conv;
	char input[33], output[33];
	CHAR tmpstr[33];
	char *inp, *outp;
	size_t insize = 1, outsize = 32;

	inp = input;
	outp = output;

	/* make source the strings are cleared */
	for (j=0; j<33; j++) {
		input[j] = '\0';
		output[j] = '\0';
	}

	/* check if the conversion from the character set from the HTML document
	   to utf-8 is possible */
	if ((conv = iconv_open("utf-8", get_iconv_charset()))==(iconv_t)(-1)) {
		fprintf(stderr, "read_char: iconv_open failed, wrong character set?\n");
		perror(get_iconv_charset());
		error = 1;
	}

	j=0;
	do {
		c=fgetc(in);
		input[j] = c;

		errno=0;
		insize = j+1;
		iconv(conv, &inp, &insize, &outp, &outsize);
		fehlernr = errno;

		if (fehlernr==E2BIG) { fprintf(stderr, "read_char: errno==E2BIG\n"); }
		/* character is invalid  */
		else if (fehlernr==EILSEQ) {
			if(c != EOF)
				fprintf(stderr, "read_char: errno==EILSEQ; invalid byte sequence for %s: %c\n", get_iconv_charset(), c);
			for (k=0; k<j;k++) {
				fprintf(stderr, "%d ",(unsigned char)input[k]);
			}
			fehlernr=0; j=0;
			c = '?';
		}
		/* incomplete but still valid byte sequence */
		else if (fehlernr==EINVAL) { /* printf("errno==EINVAL\n"); */ }
		/* valid character found */
		else if (fehlernr==0) {
			mbstowcs(outstring, output, strlen(output));
			if (convert_character(outstring[0], tmpstr))
			{
				c = outstring[0];
			}
			else
			{
				error = 1;
			}
		}

		j++;
	} while ((fehlernr!=0) && (c!=EOF));
	iconv_close(conv);

	i++;

	errno = 0;

	if (feof(in)) {
		return 0;
	} else {
		curr_ch = c;
		return c;
	}
}

/* ------------------------------------------------ */

int get_current_char()
{
	return(curr_ch);
}

/* ------------------------------------------------ */

/* set back stream p characters */
void goback_char(int p)
{
	printf("\nACHTUNG\n");
	fseek(in, -p, SEEK_CUR);
	printf("\nACHTUNG\n");
}

/* ------------------------------------------------ */

/* put c back onto stream */
void putback_char(CHAR c)
{
	UNGETC (c, in);
}

/* ------------------------------------------------ */
