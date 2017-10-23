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

/* ------------------------------------------------ */

// Need this lock because libvilistextum uses a bunch of globals and isn't
// threadsafe
pthread_mutex_t lock;
int needs_init = 1;

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
	if(text == NULL)
		return NULL;

	if(needs_init && pthread_mutex_init(&lock, NULL) != 0)
    {
        printf("\n mutex init failed\n");
        return NULL;
	}
	needs_init = 0;

	pthread_mutex_lock(&lock);

	error = 0;
	set_options();

	if(init_multibyte())
	{
		open_files(text);
		html(extractText);
		quit();
	}

	char* output = getOutput(strlen(text));

	pthread_mutex_unlock(&lock);
	return output;
}
