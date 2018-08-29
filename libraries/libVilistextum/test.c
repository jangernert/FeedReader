#include <glib.h>

#include "vilistextum.h"

static void test_changed_inputs_with_html(void)
{
	char *inputs[][2] = {
		{"  \n \t ", ""},
		{"  \n <br>\t<hr> ", "<br> <hr>"},
		{"<h ", "<h"},
		{"a\nb", "a b"},
		{"a<br>b", "a<br>b"},
		// Note: Non-breaking space is two bytes in UTF-8
		{"test&nbsp;two", "test\302\240two"},
		{"test&#160;two", "test\302\240two"},
		//{"test&#160two", "test\302\240two"}
	};
	for (size_t i = 0; i < sizeof(inputs) / sizeof(char*[2]); ++i)
	{
		char* input = inputs[i][0];
		char* output = vilistextum(input, 0);
		char* expect = inputs[i][1];
		g_assert_cmpstr(output, ==, expect);
	}
}

static void test_unchanged_inputs_with_html(void)
{
	char* inputs[] = {
		"",
		"&",
		"<",
		"<h",
		"<r \xfd\xbd\xbd\xbd\xbd\xbd",
		"test&nbsptwo"
	};
	for (size_t i = 0; i < sizeof(inputs) / sizeof(char*); ++i)
	{
		char* input = inputs[i];
		char* output = vilistextum(input, 0);
		g_assert_cmpstr(output, ==, input);
	}
}

static void test_changed_inputs_without_html(void)
{
	char *inputs[][2] = {
		{"  \n <br>\t", ""},
		//{"<h ", "<h"},
		{"a\nb", "a b"},
		{"a<br/>b", "a\nb"},
		{"test&nbsp;two", "test\302\240two"},
		{"test&#160;two", "test\302\240two"},
		//{"test&#160two", "test\xa0two"}
	};
	for (size_t i = 0; i < sizeof(inputs) / sizeof(char*[2]); ++i)
	{
		char* input = inputs[i][0];
		char* output = vilistextum(input, 1);
		char* expect = inputs[i][1];
		g_assert_cmpstr(output, ==, expect);
	}
}

static void test_unchanged_inputs_without_html(void)
{
	char* inputs[] = {
		"",
		"&",
		"<",
		//"<h",
		//"<r \xfd\xbd\xbd\xbd\xbd\xbd",
		"test&nbsptwo"
	};
	for (size_t i = 0; i < sizeof(inputs) / sizeof(char*); ++i)
	{
		char* input = inputs[i];
		char* output = vilistextum(input, 1);
		g_assert_cmpstr(output, ==, input);
	}
}

int main(int argc, char **argv)
{
	g_test_init(&argc, &argv, NULL);
	g_test_add_func("/vilistextum/unchanged-inputs/with-html", test_unchanged_inputs_with_html);
	g_test_add_func("/vilistextum/changed-inputs/with-html", test_changed_inputs_with_html);
	g_test_add_func("/vilistextum/unchanged-inputs/text-only", test_unchanged_inputs_without_html);
	g_test_add_func("/vilistextum/changed-inputs/text-only", test_changed_inputs_without_html);
	return g_test_run();
}
