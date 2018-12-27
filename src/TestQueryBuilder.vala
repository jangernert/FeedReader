using FeedReader;

void main(string[] args)
{
	Test.init(ref args);

	Test.add_data_func("/querybuilder/simple-select", () => {
		var query = new QueryBuilder(QueryType.SELECT, "example");
		query.select_field("column1");
		query.select_field("column2");

		assert(query.to_string() == "SELECT column1, column2 FROM example");
	});

	Test.add_data_func("/querybuilder/simple-insert", () => {
		var query = new QueryBuilder(QueryType.INSERT, "example");
		query.insert_param("asdf", "$VALUE");
		query.insert_int("othercol", 5);

		assert(query.to_string() == "INSERT INTO example (asdf, othercol) VALUES ($VALUE, 5)");
	});

	Test.add_data_func("/querybuilder/simple-insert-or-ignore", () => {
		var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "example");
		query.insert_param("asdf", "$VALUE");
		query.insert_int("othercol", 5);

		assert(query.to_string() == "INSERT OR IGNORE INTO example (asdf, othercol) VALUES ($VALUE, 5)");
	});

	Test.add_data_func("/querybuilder/simple-insert-or-replace", () => {
		var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "example");
		query.insert_param("asdf", "$VALUE");
		query.insert_int("othercol", 5);

		assert(query.to_string() == "INSERT OR REPLACE INTO example (asdf, othercol) VALUES ($VALUE, 5)");
	});

	Test.add_data_func("/querybuilder/simple-update", () => {
		var query = new QueryBuilder(QueryType.UPDATE, "example");
		query.update_int("asdf", 5);
		query.update_string("othercol", "asd'");
		query.update_param("test", "$TEST");

		assert(query.to_string() == "UPDATE example SET asdf = 5, othercol = 'asd''', test = $TEST");
	});

	Test.add_data_func("/querybuilder/simple-delete", () => {
		var query = new QueryBuilder(QueryType.DELETE, "example");

		assert(query.to_string() == "DELETE FROM example");
	});

	Test.add_data_func("/querybuilder/complex-select", () => {
		var query = new QueryBuilder(QueryType.SELECT, "test");
		query.select_field("column1");
		query.select_field("column2");
		query.select_field("column3");
		query.order_by("column2", true);
		query.where_equal_string("column3", "\"something'");
		query.where_equal_int("column2", 5);
		query.where("this is custom");
		query.where_in_strings(
			"column5",
			new Gee.ArrayList<string>.wrap(new string[] {
			"asdf",
			"something with a ' in it"
		}));
		query.limit(100);
		query.offset(5);

		assert(query.to_string() == "SELECT column1, column2, column3 " +
		       "FROM test " +
		       "WHERE column3 = '\"something''' " +
		       "AND column2 = 5 " +
		       "AND this is custom " +
		       "AND column5 IN ('asdf', 'something with a '' in it') " +
		       "ORDER BY column2 " +
		       "COLLATE NOCASE DESC " +
		       "LIMIT 100 " +
		       "OFFSET 5");
	});

	Test.run();
}
