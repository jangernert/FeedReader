//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.dbUI : dbBase {

    public dbUI (string dbFile = "feedreader-04.db") {
        base(dbFile);
    }

    public Gee.ArrayList<category> read_categories_level(int level, Gee.ArrayList<feed>? feeds = null)
	{
		var categories = read_categories(feeds);
		var tmpCategories = new Gee.ArrayList<category>();

		foreach(category cat in categories)
		{
			if(cat.getLevel() == level)
			{
				tmpCategories.add(cat);
			}
		}

		return tmpCategories;
	}

    public Gee.ArrayList<category> read_categories(Gee.ArrayList<feed>? feeds = null)
	{
		Gee.ArrayList<category> tmp = new Gee.ArrayList<category>();
		category tmpcategory;

		var query = new QueryBuilder(QueryType.SELECT, "main.categories");
		query.selectField("*");

		if(settings_general.get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("title", true);
		}
		else
		{
			query.orderBy("orderID", true);
		}

		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while(stmt.step () == Sqlite.ROW)
		{
			string catID = stmt.column_text(0);

			if(feeds == null || showCategory(catID, feeds))
			{
				tmpcategory = new category(
					catID, stmt.column_text(1),
					(feeds == null) ? 0 : Utils.categoryGetUnread(catID, feeds),
					stmt.column_int(3),
					stmt.column_text(4),
					stmt.column_int(5)
				);

				tmp.add(tmpcategory);
			}
		}

		return tmp;
	}

    private bool showCategory(string catID, Gee.ArrayList<feed> feeds)
	{
        if(feedDaemon_interface.hideCagetoryWhenEmtpy(catID)
        && !Utils.categoryIsPopulated(catID, feeds))
        {
            return false;
        }
        return true;
	}

    protected string getUncategorizedQuery()
	{
		string catID = feedDaemon_interface.uncategorizedID();
		return "category_id = \"%s\"".printf(catID);
	}

    protected string getUncategorizedFeedsQuery()
	{
		string sql = "feedID IN (%s)";

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("feed_id");
		query.addCustomCondition(getUncategorizedQuery());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}

		string feedIDs = "";
		while (stmt.step () == Sqlite.ROW) {
			feedIDs += "\"" + stmt.column_text(0) + "\"" + ",";
		}

		return sql.printf(feedIDs.substring(0, feedIDs.length-1));
	}

    public Gee.ArrayList<feed> read_feeds_without_cat()
	{
		Gee.ArrayList<feed> tmp = new Gee.ArrayList<feed>();
		feed tmpfeed;

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("*");
		query.addCustomCondition(getUncategorizedQuery());
		if(settings_general.get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("name", true);
		}
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			string feedID = stmt.column_text(0);
			string catString = stmt.column_text(4);
			string[] catVec = { "" };
			if(catString != "")
				catVec = catString.split(",");
			tmpfeed = new feed(feedID, stmt.column_text(1), stmt.column_text(2), ((stmt.column_int(3) == 1) ? true : false), getFeedUnread(feedID), catVec);
			tmp.add(tmpfeed);
		}

		return tmp;
	}

    public bool haveFeedsWithoutCat()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("count(*)");
		query.addCustomCondition(getUncategorizedQuery());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}

		while (stmt.step () == Sqlite.ROW) {
			int count = stmt.column_int(0);

			if(count > 0)
				return true;
		}
		return false;
	}

    public uint get_unread_uncategorized()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		query.addCustomCondition(getUncategorizedFeedsQuery());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode(), sqlite_db.errmsg()));

		int unread = 0;
		while (stmt.step() == Sqlite.ROW) {
			unread = stmt.column_int(0);
		}
		stmt.reset();
		return unread;
	}

}
