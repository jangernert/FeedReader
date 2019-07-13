#include <glib.h>

#include "htmlclean.h"

typedef struct {
	const char* input;
	const char* output;
} inout_t;

static void test_change(const void* vinout)
{
	const inout_t* inout = vinout;
	g_assert_cmpstr (htmlclean_strip_html(inout->input), ==, inout->output);
}

static void test_no_change(const void* input)
{
	const inout_t inout = {
		.input = input,
		.output = input
	};
	test_change(&inout);
}

int main(int argc, char** argv)
{
	g_test_init (&argc, &argv, NULL);

	g_test_add_data_func (
		"/htmlclean/change/removehtml",
		&(inout_t){
			"this <pre>string</pre> contains html",
			"this string contains html"
		},
		test_change);

	g_test_add_data_func (
		"/htmlclean/change/stripinput",
		&(inout_t){
			"  this has spaces around it  ",
			"this has spaces around it"
		},
		test_change);

	g_test_add_data_func (
		"/htmlclean/nochange/basic",
		"this is a normal string",
		test_no_change
	);

	g_test_add_data_func (
		"/htmlclean/nochange/escapedhtml",
		"this string contains &amp; escaped HTML",
		test_no_change
	);

	g_test_add_data_func (
		"/htmlclean/nochange/escapedhtml2",
		"CSS, &amp;lt;pre&gt;, and trailing whitespace lead to browser layout weirdness",
		test_no_change
	);

	g_test_add_data_func (
		"/htmlclean/nochange/justlt",
		"&lt;",
		test_no_change
	);

	g_test_add_data_func (
		"/htmlclean/nochange/justgt",
		"&gt;",
		test_no_change
	);

	g_test_add_data_func (
		"/htmlclean/nochange/justamp",
		"&amp;",
		test_no_change
	);

	// Previous versions of the parser crashed or hung when given these inputs
	// These get escaped, even though they're not not ambiguous in this situation
	g_test_add_data_func (
		"/htmlclean/change/justamp",
		&(inout_t){
			"&",
			"&amp;"
		},
		test_change);

	g_test_add_data_func (
		"/htmlclean/change/justlt",
		&(inout_t){
			"<",
			"&lt;"
		},
		test_change);

	g_test_add_data_func (
		"/htmlclean/change/justgt",
		&(inout_t){
			">",
			"&gt;"
		},
		test_change);

	return g_test_run ();
}
