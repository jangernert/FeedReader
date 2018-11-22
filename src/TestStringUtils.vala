using FeedReader;

void main(string[] args)
{
	Test.init(ref args);

	Test.add_data_func("/stringutils/join", () => {
		var inputs = new Gee.ArrayList<string>();
		inputs.add("one");
		inputs.add("two");

		var output = StringUtils.join(inputs, ",");
		assert(output == "one,two");

		output = StringUtils.join(inputs, "  ");
		assert(output == "one  two");
	});

	Test.add_data_func("/stringutils/split", () => {
		var output = StringUtils.split("", ",");
		assert(output.is_empty);

		output = StringUtils.split(" ", ",");
		assert(output.size == 1);
		assert(output[0] == " ");

		output = StringUtils.split(" ", " ");
		assert(output.size == 2);
		assert(output[0] == "");
		assert(output[1] == "");

		output = StringUtils.split(" ", " ", true);
		assert(output.size == 0);

		output = StringUtils.split("$one#$t#wo#$", "#$");
		assert(output.size == 3);
		assert(output[0] == "$one");
		assert(output[1] == "t#wo");
		assert(output[2] == "");

		output = StringUtils.split("$one#$t#wo#$", "#$", true);
		assert(output.size == 2);
		assert(output[0] == "$one");
		assert(output[1] == "t#wo");
	});

	Test.add_data_func("/stringutils/sqlquote", () => {
		var inputs = new Gee.ArrayList<string>();
		assert(StringUtils.sql_quote(inputs).size == 0);

		inputs.add("one");
		inputs.add("t'wo");
		inputs.add("''");

		var output = StringUtils.sql_quote(inputs);
		assert(output.size == inputs.size);
		assert(output[0] == "'one'");
		assert(output[1] == "'t''wo'");
		assert(output[2] == "''''''");
	});

    Test.run();
}
