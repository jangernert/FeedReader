using FeedReader;

void main(string[] args)
{
	Test.init(ref args);

	Test.add_data_func("/querybuilder/simple-select", () => {
		var query = new QueryBuilder(QueryType.SELECT, "example");
		query.selectField("column1");
		query.selectField("column2");

		assert(query.to_string() == "SELECT column1, column2 FROM example");
	});

	Test.add_data_func("/querybuilder/simple-insert", () => {
		var query = new QueryBuilder(QueryType.INSERT, "example");
		query.insertValuePair("asdf", "$VALUE");
		query.insertValuePair("othercol", "5");

		assert(query.to_string() == "INSERT INTO example (asdf, othercol) VALUES ($VALUE, 5)");
	});

	Test.add_data_func("/querybuilder/simple-insert-or-ignore", () => {
		var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "example");
		query.insertValuePair("asdf", "$VALUE");
		query.insertValuePair("othercol", "5");

		assert(query.to_string() == "INSERT OR IGNORE INTO example (asdf, othercol) VALUES ($VALUE, 5)");
	});

	Test.add_data_func("/querybuilder/simple-insert-or-replace", () => {
		var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "example");
		query.insertValuePair("asdf", "$VALUE");
		query.insertValuePair("othercol", "5");

		assert(query.to_string() == "INSERT OR REPLACE INTO example (asdf, othercol) VALUES ($VALUE, 5)");
	});

	Test.add_data_func("/querybuilder/simple-update", () => {
		var query = new QueryBuilder(QueryType.UPDATE, "example");
		query.updateValuePair("asdf", "5");
		query.updateValuePair("othercol", "asd'", true);

		assert(query.to_string() == "UPDATE example SET asdf = 5, othercol = 'asd'''");
	});

	Test.add_data_func("/querybuilder/simple-delete", () => {
		var query = new QueryBuilder(QueryType.DELETE, "example");

		assert(query.to_string() == "DELETE FROM example");
	});

	Test.add_data_func("/querybuilder/complex-select", () => {
		var query = new QueryBuilder(QueryType.SELECT, "test");
		query.selectField("column1");
		query.selectField("column2");
		query.selectField("column3");
		query.orderBy("column2", true);
		query.addEqualsCondition("column3", "\"something'", false, true);
		query.addEqualsCondition("column2", "5", true, false);
		query.addCustomCondition("this is custom");
		query.addRangeConditionString(
			"column5",
			new Gee.ArrayList<string>.wrap(new string[]{
				"asdf",
				"something with a ' in it"
			}));
		query.addRangeConditionInt(
			"column6",
			new Gee.ArrayList<int>.wrap(new int[]{
				-5,
				1
			}));
		query.limit(100);
		query.offset(5);

		print("%s\n", query.to_string());
		assert(query.to_string() == "SELECT column1, column2, column3 " +
									"FROM test " +
									"WHERE NOT column3 = '\"something''' " +
									"AND column2 = 5 " +
									"AND this is custom " +
									"AND column5 IN ('asdf', 'something with a '' in it') " +
									"AND column6 IN (-5, 1) " +
									"ORDER BY column2 " +
									"COLLATE NOCASE DESC " +
									"LIMIT 100 " +
									"OFFSET 5");
	});

    Test.run();
}
