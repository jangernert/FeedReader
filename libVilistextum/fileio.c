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

CHAR* OUTPUT = NULL;
const CHAR LINEBREAK[1] = L"\n";
size_t currentsize = 0;
size_t outputsize = 0;

/* ------------------------------------------------ */

void init_buffer(char *input, int error)
{
	in = fmemopen(input, strlen(input), "r");
	if(in == NULL)
	{
		fprintf(stderr, "Couldn't open input file %s!\n",input);
		error = 1;
	}

	outputsize = strlen(input);
	OUTPUT = malloc(sizeof(CHAR)*(outputsize+1));
	OUTPUT[0]='\0';
}

/* ------------------------------------------------ */

void output_string(CHAR *str)
{
	currentsize += wcslen(str) + wcslen(LINEBREAK);

	if(currentsize > outputsize)
	{
		if(2*outputsize > currentsize)
			outputsize *= 2;
		else
			outputsize += currentsize;

		OUTPUT = realloc(OUTPUT, sizeof(CHAR)*(outputsize+1));
	}

	wcscat(OUTPUT, str);
	wcscat(OUTPUT, LINEBREAK);
}

/* ------------------------------------------------ */

void cleanup()
{
	currentsize = 0;
	free(OUTPUT);
	OUTPUT = NULL;
	fclose(in);
}

/* ------------------------------------------------ */

char* getOutput(size_t input_length, int error)
{
	if(!error)
	{
		size_t buffersize = 2*sizeof(char)*input_length;
		char* buffer = malloc(buffersize);
		int ret = wcstombs ( buffer, OUTPUT, buffersize );
		if (ret==buffersize) buffer[buffersize-1]='\0';
		cleanup();
		if (ret)
			return buffer;
		
		return NULL;
	}

	
	cleanup();
	return NULL;
}

/* ------------------------------------------------ */

void finalize(int nooutput, int spaces, int breite, int error, int zeilen_len, int zeilen_len_old)
{
	if (!is_zeile_empty())
	{
		wort_ende(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old);
		print_zeile(nooutput, breite, error, zeilen_len, zeilen_len_old);
	}
}

/* ------------------------------------------------ */

int read_char(int error)
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
		printf("read_char: iconv_open failed, wrong character set?\n");
		printf("iconv_open(\"utf-8\", \"%s\");\n", get_iconv_charset());
		perror(get_iconv_charset());
		error = 1;
		return EOF;
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
		return EOF;
	} else {
		return c;
	}
}

/* ------------------------------------------------ */

/* put c back onto stream */
void putback_char(CHAR c)
{
	char buffer[1];
	wcstombs(buffer, &c, 1);
	ungetc(buffer[0], in);
}

/* ------------------------------------------------ */
