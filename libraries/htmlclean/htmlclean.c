// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Author: jdtang@google.com (Jonathan Tang)
// Minimal changes to turn this into a C library by Brendan Long <self@brendanlong.com>
//
// Gets the cleantext of a page.
// See https://github.com/google/gumbo-parser/blob/master/examples/clean_text.cc
#include <unistd.h>
#include <string.h>

#include <stdio.h>
#include <stdlib.h>

#include "glib.h"
#include "gumbo.h"

char *cleantext(GumboNode *node)
{
	if (node->type == GUMBO_NODE_TEXT)
	{
		char *text = g_strdup(node->v.text.text);
		if (text == NULL)
		{
			return NULL;
		}
		text = g_strstrip(text);
		if (strlen(text) == 0)
		{
			g_free(text);
			return NULL;
		}
		return text;
	}
	else if (node->type == GUMBO_NODE_ELEMENT &&
			 node->v.element.tag != GUMBO_TAG_SCRIPT &&
			 node->v.element.tag != GUMBO_TAG_STYLE)
	{
		GumboVector *children = &node->v.element.children;
		char **strs = malloc((children->length + 1) * sizeof(char **));
		size_t num_nonempty = 0;
		for (unsigned int i = 0; i < children->length; ++i)
		{
			char *text = cleantext((GumboNode *)children->data[i]);
			if (text != NULL)
			{
				strs[num_nonempty] = text;
				++num_nonempty;
			}
		}
		strs[num_nonempty] = NULL;

		char *output = NULL;
		if (num_nonempty > 0)
		{
			output = num_nonempty == 0 ? NULL : g_strjoinv(" ", strs);
			for (size_t i = 0; i < num_nonempty; ++i)
			{
				g_free(strs[i]);
			}
		}
		free(strs);
		return output;
	}
	else
	{
		return NULL;
	}
}

char *htmlclean_strip_html(char *input)
{
	char *cleaned = NULL;
	if (input != NULL)
	{
		GumboOutput *output = gumbo_parse(input);
		cleaned = cleantext(output->root);
		gumbo_destroy_output(&kGumboDefaultOptions, output);
	}
	if (cleaned == NULL)
	{
		return g_strdup("");
	}
	return cleaned;
}
