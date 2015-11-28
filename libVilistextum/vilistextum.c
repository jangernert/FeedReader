/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 */

#include <unistd.h>
#include <string.h>
#include <getopt.h>

#include <stdio.h>
#include <stdlib.h>

#include "vilistextum.h"
#include "html.h"
#include "fileio.h"
#include "charset.h"

char* buffer;
size_t length;

/* ------------------------------------------------ */

void set_options()
{
	convert_characters = 1;
	shrink_lines = 1;
	remove_empty_alt = 1;
	option_no_image = 1;
	option_no_alt = 1;
	convert_tags = 0;
	option_links = 0;
	option_links_inline = 0;
	option_title = 0;
	set_iconv_charset("utf-8");
	errorlevel = 0;
}

char* vilistextum(char* text, int extractText)
{
	length = strlen(text);
	error = 0;
	set_options();
	mallocOutput(strlen(text));

	if(init_multibyte())
	{
		open_files(text);
		html(extractText);
		quit();
	}

	if(!error)
	{
		CHAR* output = getOutput();
		size_t buffersize = sizeof(char)*length;
		if(buffer!=NULL)
			free(buffer);
		buffer = malloc(buffersize);
		int ret = wcstombs ( buffer, output, buffersize );
		//memset(output,0,sizeof(DEF_STR_LEN));
		//output[0]='\0';
		if (ret==buffersize) buffer[buffersize-1]='\0';
		if (ret)
			return buffer;
		else
			return NULL;
	}
	else
		return NULL;
}
