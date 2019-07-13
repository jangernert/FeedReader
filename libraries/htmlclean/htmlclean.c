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

// After parsing, we need to re-escape HTML so we don't remove literal <> and &
// For example if the original text was "The &lt;pre&gt; element is an HTML element", we want
// our final output to be "The &lt;pre&gt; element is an HTML element", not "The <pre> element
// is an HTML element" (which would get stripped if we ran it through this again)
// Returns a new string!
static char* reescape_xml_entities(const char* text)
{
	size_t len = strlen(text);
	GString* result = g_string_sized_new(len);
	for (size_t i = 0; i < len; ++i)
	{
		char c = text[i];
		switch (c)
		{
			case '<':
				g_string_append(result, "&lt;");
				break;
			case '>':
				g_string_append(result, "&gt;");
				break;
			case '&':
				g_string_append(result, "&amp;");
				break;
			default:
				g_string_append_c(result, c);
				break;
		}
	}
	return g_string_free(result, FALSE);
}

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

char *htmlclean_strip_html(const char *input)
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

	char* cleaned_escaped = reescape_xml_entities(cleaned);
	free(cleaned);
	return cleaned_escaped;
}
