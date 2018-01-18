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

public class FeedReader.DataBaseReadOnly : GLib.Object {

	protected SQLite m_db;

	public DataBaseReadOnly(string db_file = "feedreader-%01i.db".printf(Constants.DB_SCHEMA_VERSION))
	{
		Sqlite.config(Sqlite.Config.LOG, errorLogCallback);
		string db_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/" + db_file;

		Logger.debug(@"Opening Database: $db_path");
		m_db = new SQLite(db_path);
	}

	private void errorLogCallback(int code, string msg)
	{
		Logger.error(@"dbErrorLog: $code: $msg");
	}

	public void init()
	{
		Logger.debug("init database");
		m_db.simple_query("PRAGMA journal_mode = WAL");
		m_db.simple_query("PRAGMA page_size = 4096");

		m_db.simple_query("""
			CREATE  TABLE  IF NOT EXISTS "main"."feeds"
			(
				"feed_id" TEXT PRIMARY KEY NOT NULL UNIQUE,
				"name" TEXT NOT NULL,
				"url" TEXT NOT NULL,
				"category_id" TEXT,
				"subscribed" INTEGER DEFAULT 1,
				"xmlURL" TEXT,
				"iconURL" TEXT
			)
		""");

		m_db.simple_query("""
			CREATE  TABLE  IF NOT EXISTS "main"."categories"
			(
				"categorieID" TEXT PRIMARY KEY NOT NULL UNIQUE,
				"title" TEXT NOT NULL,
				"orderID" INTEGER,
				"exists" INTEGER,
				"Parent" TEXT,
				"Level" INTEGER
			)
		""");

		m_db.simple_query("""
			CREATE  TABLE  IF NOT EXISTS "main"."articles"
			(
				"articleID" TEXT PRIMARY KEY NOT NULL UNIQUE,
				"feedID" TEXT NOT NULL,
				"title" TEXT NOT NULL,
				"author" TEXT,
				"url" TEXT NOT NULL,
				"html" TEXT NOT NULL,
				"preview" TEXT NOT NULL,
				"unread" INTEGER NOT NULL,
				"marked" INTEGER NOT NULL,
				"tags" TEXT,
				"date" INTEGER NOT NULL,
				"guidHash" TEXT,
				"lastModified" INTEGER,
				"media" TEXT,
				"contentFetched" INTEGER NOT NULL
			)
		""");

		m_db.simple_query("""
			CREATE  TABLE  IF NOT EXISTS "main"."tags"
			(
				"tagID" TEXT PRIMARY KEY NOT NULL UNIQUE,
				"title" TEXT NOT NULL,
				"exists" INTEGER,
				"color" INTEGER
			)
		""");

		m_db.simple_query("""
			CREATE  TABLE  IF NOT EXISTS "main"."CachedActions"
			(
				"action" INTEGER NOT NULL,
				"id" TEXT NOT NULL,
				"argument" INTEGER
			)
		""");

		m_db.simple_query("""
			CREATE INDEX IF NOT EXISTS "index_articles"
			ON "articles" ("feedID" DESC, "unread" ASC, "marked" ASC)
		""");
		m_db.simple_query("""
			CREATE VIRTUAL TABLE IF NOT EXISTS fts_table
			USING fts4 (content='articles', articleID, preview, title, author)
		""");
	}

	public bool uninitialized()
	{
		string query = "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='articles'";
		var rows = m_db.execute(query);
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int() == 0;
	}

	public bool isEmpty()
	{
		return isTableEmpty("articles")
			&& isTableEmpty("categories")
			&& isTableEmpty("feeds")
			&& isTableEmpty("tags");
	}

	public bool isTableEmpty(string table)
	{
		var query = @"SELECT COUNT(*) FROM $table";
		var rows = m_db.execute(query);
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int() == 0;
	}

	private uint count_article_status(ArticleStatus status)
	{
		var query = "SELECT COUNT(*) FROM articles";
		string status_column = status.column();
		if(status_column != null)
			query += @" WHERE $status_column = ?";
		var rows = m_db.execute(query, { status });
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int();
	}

	public uint get_unread_total()
	{
		return count_article_status(ArticleStatus.UNREAD);
	}

	public uint get_marked_total()
	{
		return count_article_status(ArticleStatus.MARKED);
	}

	private uint count_status_uncategorized(ArticleStatus status)
	{
		var query = new QueryBuilder(QueryType.SELECT, "articles");
		query.selectField("count(*)");
		var status_column = status.column();
		if(status_column != null)
			query.addEqualsCondition(status_column, status.to_string());
		query.addCustomCondition(getUncategorizedFeedsQuery());
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		int unread = 0;
		while (stmt.step() == Sqlite.ROW) {
			unread = stmt.column_int(0);
		}
		stmt.reset();
		return unread;
	}

	public uint get_unread_uncategorized()
	{
		return count_status_uncategorized(ArticleStatus.UNREAD);
	}

	public uint get_marked_uncategorized()
	{
		return count_status_uncategorized(ArticleStatus.MARKED);
	}

	public int get_new_unread_count(int row_id)
	{
		if(row_id == 0)
			return 0;

		string query = "SELECT count(*) FROM articles WHERE unread = ? AND rowid > ?";
		var rows = m_db.execute(query, { ArticleStatus.UNREAD, row_id });
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int();
	}

	public int getTagColor()
	{
		var rows = m_db.execute("SELECT COUNT(*) FROM tags WHERE instr(tagID, \"global.\") = 0");
		assert(rows.size == 1 && rows[0].size == 1);
		int tagCount = rows[0][0].to_int();
		return tagCount % Constants.COLORS.length;
	}

	public bool tag_still_used(Tag tag)
	{
		var query = "SELECT 1 FROM main.articles WHERE instr(tagID, ?) > 0 LIMIT 1";
		var rows = m_db.execute(query, { tag.getTagID() });
		return rows.size > 0;
	}

	public string? getTagName(string tag_id)
	{
		var query = "SELECT title FROM tags WHERE tagID = ?";
		var rows = m_db.execute(query, { tag_id });
		assert(rows.size == 0 || (rows.size == 1 && rows[0].size == 1));
		if(rows.size == 1)
			return rows[0][0].to_string();
		return _("Unknown tag");
	}

	public int getLastModified()
	{
		var query = "SELECT MAX(lastModified) FROM articles";
		var rows = m_db.execute(query);
		assert(rows.size == 0 || (rows.size == 1 && rows[0].size == 1));
		if(rows.size == 1 && rows[0][0] != null)
			return rows[0][0].to_int();
		else
			return 0;
	}


	public string getCategoryName(string catID)
	{
		if(catID == CategoryID.TAGS.to_string())
			return "Tags";

		var query = "SELECT title FROM categories WHERE categorieID = ?";
		var rows = m_db.execute(query, { catID });

		string result = "";
		if(rows.size != 0)
			result = rows[0][0].to_string();

		if(result == "")
			result = _("Uncategorized");

		return result;
	}

	public string? getCategoryID(string catname)
	{
		var query = "SELECT categorieID FROM categories WHERE title = ?";
		var rows = m_db.execute(query, { catname });
		if(rows.size == 0)
			return null;
		else
			return rows[0][0].to_string();
	}

	public bool preview_empty(string articleID)
	{
		var query = "SELECT COUNT(*) FROM articles WHERE articleID = ? AND preview != ''";
		var rows = m_db.execute(query, { articleID });
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int() != 0;
	}

	public Gee.List<Article> read_article_between(
		string feedID,
		FeedListType selectedType,
		ArticleListState state,
		string searchTerm,
		string id1,
		GLib.DateTime date1,
		string id2,
		GLib.DateTime date2)
	{
		var query = articleQuery(feedID, selectedType, state, searchTerm);
		var sorting = (ArticleListSort)Settings.general().get_enum("articlelist-sort-by");

		if(sorting == ArticleListSort.RECEIVED)
			query.addCustomCondition(@"date BETWEEN (SELECT rowid FROM articles WHERE articleID = \"$id1\") AND (SELECT rowid FROM articles WHERE articleID = \"$id2\")");
		else
		{
			bool bigger = (date1.to_unix() > date2.to_unix());
			var biggerDate = (bigger) ? date1.to_unix() : date2.to_unix();
			var smallerDate = (bigger) ? date2.to_unix() : date1.to_unix();
			query.addCustomCondition(@"date BETWEEN $smallerDate AND $biggerDate");
		}
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		var articles = new Gee.ArrayList<Article>();
		while (stmt.step () == Sqlite.ROW)
		{
			if(stmt.column_text(2) == id1
			|| stmt.column_text(2) == id2)
				continue;

			articles.add(new Article(
								stmt.column_text(2),																		// articleID
								stmt.column_text(3),																		// title
								stmt.column_text(5),																		// url
								stmt.column_text(1),																		// feedID
								(ArticleStatus)stmt.column_int(7),											// unread
								(ArticleStatus)stmt.column_int(8),											// marked
								null,																											// html
								stmt.column_text(6),																		// preview
								stmt.column_text(4),																		// author
								new GLib.DateTime.from_unix_local(stmt.column_int(10)),	// date
								stmt.column_int(0),																			// sortID
								StringUtils.split(stmt.column_text(9), ",", true), 			// tags
								StringUtils.split(stmt.column_text(12), ",", true),			// media
								stmt.column_text(11)																		// guid
							));
		}
		stmt.reset();
		return articles;
	}

	public Gee.HashMap<string, Article> read_article_stats(Gee.List<string> ids)
	{
		var query = new QueryBuilder(QueryType.SELECT, "articles");
		query.selectField("articleID, unread, marked");
		query.addRangeConditionString("articleID", ids);
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		var articles = new Gee.HashMap<string, Article>();

		while(stmt.step() == Sqlite.ROW)
		{
			articles.set(stmt.column_text(0),
								new Article(stmt.column_text(0), null, null, null, (ArticleStatus)stmt.column_int(1),
								(ArticleStatus)stmt.column_int(2), null, null, null, new GLib.DateTime.now_local()));
		}
		stmt.reset();
		return articles;
	}

	public Article? read_article(string articleID)
	{
		Logger.debug(@"DataBaseReadOnly.read_article(): $articleID");
		var rows = m_db.execute("SELECT ROWID, * FROM articles WHERE articleID = ?", { articleID });
		if(rows.size == 0)
			return null;
		var row = rows[0];
		string? author = row[4].to_string();
		if(author == "")
			author = null;

		return new Article(
				articleID,
				row[3].to_string(),
				row[5].to_string(),
				row[2].to_string(),
				(ArticleStatus)row[8].to_int(),
				(ArticleStatus)row[9].to_int(),
				row[6].to_string(),
				row[7].to_string(),
				author,
				new GLib.DateTime.from_unix_local(row[11].to_int()),
				row[0].to_int(), // rowid (sortid)
				StringUtils.split(row[10].to_string(), ",", true), // tags
				StringUtils.split(row[14].to_string(), ",", true), // media
				row[12].to_string()  // guid
		);
	}

	public int getMaxCatLevel()
	{
		var rows = m_db.execute("SELECT MAX(Level) FROM categories");
		assert(rows.size == 1 && rows[0].size == 1);
		int maxCatLevel = rows[0][0].to_int();
		if(maxCatLevel == 0)
			maxCatLevel = 1;
		return maxCatLevel;
	}

	public bool haveFeedsWithoutCat()
	{
		var query = new QueryBuilder(QueryType.SELECT, "feeds");
		query.selectField("count(*)");
		query.addCustomCondition(getUncategorizedQuery());
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		while (stmt.step () == Sqlite.ROW) {
			int count = stmt.column_int(0);

			if(count > 0)
				return true;
		}
		return false;
	}

	public bool haveCategories()
	{
		var rows = m_db.execute("SELECT COUNT(*) FROM categories");
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int() > 0;
	}

	public bool article_exists(string articleID)
	{
		var rows = m_db.execute("SELECT 1 FROM articles WHERE articleID = ? LIMIT 1", { articleID });
		return rows.size != 0;
	}

	public bool category_exists(string catID)
	{
		var rows = m_db.execute("SELECT 1 FROM categories WHERE categorieID = ? LIMIT 1", { catID });
		return rows.size != 0;
	}

	public int getRowCountHeadlineByDate(string date)
	{
		var rows = m_db.execute("SELECT COUNT(*) FROM articles WHERE date > ?", { date });
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int();
	}

	public int getArticleCountNewerThanID(string articleID, string feedID, FeedListType selectedType, ArticleListState state, string searchTerm, int searchRows = 0)
	{
		int result = 0;
		string orderBy = ((ArticleListSort)Settings.general().get_enum("articlelist-sort-by") == ArticleListSort.RECEIVED) ? "rowid" : "date";

		var query = new QueryBuilder(QueryType.SELECT, "articles");
		query.addEqualsCondition("articleID", articleID, true, true);

		var query2 = new QueryBuilder(QueryType.SELECT, "articles");
		query2.selectField("count(*)");


		query.selectField(orderBy);
		query.build();

		if(Settings.general().get_boolean("articlelist-oldest-first") && state == ArticleListState.UNREAD)
			query2.addCustomCondition(@"$orderBy < (%s)".printf(query.get()));
		else
			query2.addCustomCondition(@"$orderBy > (%s)".printf(query.get()));


		if(selectedType == FeedListType.FEED && feedID != FeedID.ALL.to_string())
		{
			query2.addEqualsCondition("feedID", feedID, true, true);
		}
		else if(selectedType == FeedListType.CATEGORY && feedID != CategoryID.MASTER.to_string() && feedID != CategoryID.TAGS.to_string())
		{
			query2.addRangeConditionString("feedID", getFeedIDofCategorie(feedID));
		}
		else if(feedID == CategoryID.TAGS.to_string())
		{
			query2.addCustomCondition(getAllTagsCondition());
		}
		else if(selectedType == FeedListType.TAG)
		{
			query2.addCustomCondition("instr(tags, \"%s\") > 0".printf(feedID));
		}

		if(state == ArticleListState.UNREAD)
		{
			query2.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		}
		else if(state == ArticleListState.MARKED)
		{
			query2.addEqualsCondition("marked", ArticleStatus.MARKED.to_string());
		}

		if(searchTerm != ""){
			if(searchTerm.has_prefix("title: "))
			{
				query2.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE title MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else if(searchTerm.has_prefix("author: "))
			{
				query2.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE author MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else if(searchTerm.has_prefix("content: "))
			{
				query2.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE preview MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else
			{
				query2.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE fts_table MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
		}

		bool desc = true;
		string asc = "DESC";
		if(Settings.general().get_boolean("articlelist-oldest-first") && state == ArticleListState.UNREAD)
		{
			desc = false;
			asc = "ASC";
		}

		if(searchRows != 0)
			query.addCustomCondition(@"articleID in (SELECT articleID FROM articles ORDER BY $orderBy $asc LIMIT $searchRows)");

		query2.orderBy(orderBy, desc);
		query2.build();

		Sqlite.Statement stmt = m_db.prepare(query2.get());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}

		return result;
	}

	public Gee.List<string> getFeedIDofCategorie(string categorieID)
	{
		var feedIDs = new Gee.ArrayList<string>();

		var query = new QueryBuilder(QueryType.SELECT, "feeds");
		query.selectField("feed_id, category_id");
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		while (stmt.step() == Sqlite.ROW) {
			string catString = stmt.column_text(1);
			string[] categories = catString.split(",");

			if(categorieID == "")
			{
				if((categories.length == 0)
				||(categories.length == 1 && categories[0].contains("global.must")))
				{
					feedIDs.add(stmt.column_text(0));
				}
			}
			else
			{
				foreach(string cat in categories)
				{
					if(cat == categorieID)
					{
						feedIDs.add(stmt.column_text(0));
					}
				}
			}
		}
		return feedIDs;
	}

	protected string getUncategorizedQuery()
	{
		string catID = FeedServer.get_default().uncategorizedID();
		return "category_id = \"%s\"".printf(catID);
	}

	protected bool showCategory(string catID, Gee.List<Feed> feeds)
	{
		if(FeedServer.get_default().hideCategoryWhenEmpty(catID)
		&& !Utils.categoryIsPopulated(catID, feeds))
		{
			return false;
		}
		return true;
	}

	protected string getUncategorizedFeedsQuery()
	{
		var query = new QueryBuilder(QueryType.SELECT, "feeds");
		query.selectField("feed_id");
		query.addCustomCondition(getUncategorizedQuery());
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		string feedIDs = "";
		while (stmt.step () == Sqlite.ROW) {
			feedIDs += "\"" + stmt.column_text(0) + "\"" + ",";
		}

		return "feedID IN (%s)".printf(feedIDs.substring(0, feedIDs.length-1));
	}

	public string getFeedIDofArticle(string articleID)
	{
		var rows = m_db.execute("SELECT feedID FROM articles WHERE articleID = ?", { articleID });
		string id = null;
		if(rows.size != 0)
			id = rows[0][0].to_string();
		if(id == null)
			id = "";
		return id;
	}

	public string getNewestArticle()
	{
		var rows = m_db.execute("SELECT articleID FROM articles WHERE rowid = ?",  { getMaxID("articles", "rowid") });
		if(rows.size == 0)
			return "";
		return rows[0][0].to_string();
	}

	public string getMaxID(string table, string field)
	{
		var rows = m_db.execute(@"SELECT MAX($field) FROM $table");
		string? id = null;
		if(rows.size > 0)
			id = rows[0][0].to_string();
		if(id == null)
			id = "";
		return id;
	}

	public bool feed_exists(string feed_url)
	{
		var rows = m_db.execute("SELECT COUNT(*) FROM main.feeds WHERE url = ? LIMIT 1", { feed_url });
		assert(rows.size == 1 && rows[0].size == 1);
		// Why > 1 and not > 0?
		return rows[0][0].to_int() > 1;
	}

	public Feed? read_feed(string feedID)
	{
		var rows = m_db.execute("SELECT * FROM feeds WHERE feed_id = ?", { feedID });
		if(rows.size == 0)
			return null;

		var row = rows[0];
		return new Feed(
				feedID,
				row[1].to_string(),
				row[2].to_string(),
				getFeedUnread(feedID),
				StringUtils.split(row[3].to_string(), ",", true),
				row[6].to_string(),
				row[5].to_string());
	}

	public Gee.List<Feed> read_feeds(bool starredCount = false)
	{
		Gee.List<Feed> feeds = new Gee.ArrayList<Feed>();

		var query = new QueryBuilder(QueryType.SELECT, "feeds");
		query.selectField("*");
		if(Settings.general().get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("name", true);
		}
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		while (stmt.step () == Sqlite.ROW) {
			string feedID = stmt.column_text(0);
			string catString = stmt.column_text(3);
			string xmlURL = stmt.column_text(5);
			string iconURL = stmt.column_text(6);
			string url = stmt.column_text(2);
			string name = stmt.column_text(1);
			var categories = StringUtils.split(catString, ",", true);

			uint count = 0;
			if(starredCount)
				count = getFeedStarred(feedID);
			else
				count = getFeedUnread(feedID);

			var feed = new Feed(feedID, name, url, count, categories, iconURL, xmlURL);
			feeds.add(feed);
		}

		return feeds;
	}

	public uint getFeedUnread(string feedID)
	{
		var query = "SELECT COUNT(*) FROM articles WHERE unread = ? AND feedID = ?";
		var rows = m_db.execute(query, { ArticleStatus.UNREAD, feedID });
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int();
	}

	public uint getFeedStarred(string feedID)
	{
		var query = "SELECT COUNT(*) FROM articles WHERE marked = ? AND feedID = ?";
		var rows = m_db.execute(query, { ArticleStatus.MARKED, feedID });
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int();
	}

	public Gee.List<Feed> read_feeds_without_cat()
	{
		var feeds = new Gee.ArrayList<Feed>();

		var query = new QueryBuilder(QueryType.SELECT, "feeds");
		query.selectField("*");
		query.addCustomCondition(getUncategorizedQuery());
		if(Settings.general().get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("name", true);
		}
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		while (stmt.step () == Sqlite.ROW) {
			string feedID = stmt.column_text(0);
			string catString = stmt.column_text(3);
			string xmlURL = stmt.column_text(5);
			string iconURL = stmt.column_text(6);
			string url = stmt.column_text(2);
			string name = stmt.column_text(1);
			var categories = StringUtils.split(catString, ",", true);
			var feed = new Feed(feedID, name, url, getFeedUnread(feedID), categories, iconURL, xmlURL);
			feeds.add(feed);
		}

		return feeds;
	}

	public Category? read_category(string catID)
	{
		var query = "SELECT * FROM categories WHERE categorieID = ?";
		var rows = m_db.execute(query, { catID });
		if(rows.size == 0)
			return null;

		var row = rows[0];
		return new Category(
			catID,
			row[1].to_string(),
			0,
			row[3].to_int(),
			row[4].to_string(),
			row[5].to_int()
		);
	}

	public Gee.List<Tag> read_tags()
	{
		var rows = m_db.execute("SELECT * FROM tags WHERE instr(tagID, \"global.\") = 0");

		var tags = new Gee.ArrayList<Tag>();
		foreach(var row in rows)
		{
			var tag = new Tag(
					row[0].to_string(),
					row[1].to_string(),
					row[3].to_int());
			tags.add(tag);
		}

		return tags;
	}

	public Tag? read_tag(string tagID)
	{
		var query = "SELECT * FROM tags WHERE tagID = ?";
		var rows = m_db.execute(query, { tagID });
		if(rows.size == 0)
			return null;

		var row = rows[0];
		return new Tag(
			row[0].to_string(),
			row[1].to_string(),
			row[3].to_int());
	}

	protected string getAllTagsCondition()
	{
		var tags = read_tags();
		string query = "(";
		foreach(Tag tag in tags)
		{
			query += "instr(\"tags\", \"%s\") > 0 OR ".printf(tag.getTagID());
		}

		int or = query.char_count()-4;
		return query.substring(0, or) + ")";
	}

	public int getTagCount()
	{
		var rows = m_db.execute("SELECT COUNT(*) FROM tags WHERE instr(tagID, \"global.\") = 0");
		assert(rows.size == 1 && rows[0].size == 1);
		return rows[0][0].to_int();
	}

	public Gee.List<Category> read_categories_level(int level, Gee.List<Feed>? feeds = null)
	{
		var categories = read_categories(feeds);
		var tmpCategories = new Gee.ArrayList<Category>();

		foreach(Category cat in categories)
		{
			if(cat.getLevel() == level)
			{
				tmpCategories.add(cat);
			}
		}

		return tmpCategories;
	}

	public Gee.List<Category> read_categories(Gee.List<Feed>? feeds = null)
	{
		Gee.List<Category> tmp = new Gee.ArrayList<Category>();

		var query = new QueryBuilder(QueryType.SELECT, "categories");
		query.selectField("*");

		if(Settings.general().get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("title", true);
		}
		else
		{
			query.orderBy("orderID", true);
		}

		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		while(stmt.step () == Sqlite.ROW)
		{
			string catID = stmt.column_text(0);

			if(feeds == null || showCategory(catID, feeds))
			{
				var tmpcategory = new Category(
					catID,
					stmt.column_text(1),
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

	public Gee.List<Article> readUnfetchedArticles()
	{
		var rows = m_db.execute("SELECT articleID, url, preview, html, feedID FROM articles WHERE contentFetched = 0");

		var articles = new Gee.LinkedList<Article>();
		foreach(var row in rows)
		{
			articles.add(new Article(
					row[0].to_string(),																// articleID
					null,																									// title
					row[1].to_string(),																// url
					row[4].to_string(),																// feedID
					ArticleStatus.UNREAD,																// unread
					ArticleStatus.UNMARKED,															// marked
					row[3].to_string(),																// html
					row[2].to_string(),																// preview
					null,																									// author
					new GLib.DateTime.now_local()												// date
				));
		}
		return articles;
	}

	public QueryBuilder articleQuery(string id, FeedListType selectedType, ArticleListState state, string searchTerm)
	{
		string orderBy = ((ArticleListSort)Settings.general().get_enum("articlelist-sort-by") == ArticleListSort.RECEIVED) ? "rowid" : "date";

		var query = new QueryBuilder(QueryType.SELECT, "articles");
		query.selectField("ROWID");
		query.selectField("feedID");
		query.selectField("articleID");
		query.selectField("title");
		query.selectField("author");
		query.selectField("url");
		query.selectField("preview");
		query.selectField("unread");
		query.selectField("marked");
		query.selectField("tags");
		query.selectField("date");
		query.selectField("guidHash");
		query.selectField("media");

		if(selectedType == FeedListType.FEED && id != FeedID.ALL.to_string())
		{
			query.addEqualsCondition("feedID", id, true, true);
		}
		else if(selectedType == FeedListType.CATEGORY && id != CategoryID.MASTER.to_string() && id != CategoryID.TAGS.to_string())
		{
			query.addRangeConditionString("feedID", getFeedIDofCategorie(id));
		}
		else if(id == CategoryID.TAGS.to_string())
		{
			query.addCustomCondition(getAllTagsCondition());
		}
		else if(selectedType == FeedListType.TAG)
		{
			query.addCustomCondition("instr(tags, \"%s\") > 0".printf(id));
		}

		if(state == ArticleListState.UNREAD)
		{
			query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		}
		else if(state == ArticleListState.MARKED)
		{
			query.addEqualsCondition("marked", ArticleStatus.MARKED.to_string());
		}

		if(searchTerm != ""){
			if(searchTerm.has_prefix("title: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE title MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else if(searchTerm.has_prefix("author: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE author MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else if(searchTerm.has_prefix("content: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE preview MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE fts_table MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
		}

		bool desc = true;
		if(Settings.general().get_boolean("articlelist-oldest-first") && state == ArticleListState.UNREAD)
			desc = false;

		query.orderBy(orderBy, desc);

		return query;
	}

	public Gee.List<Article> read_articles(string id, FeedListType selectedType, ArticleListState state, string searchTerm, uint limit = 20, uint offset = 0, int searchRows = 0)
	{
		var query = articleQuery(id, selectedType, state, searchTerm);

		string desc = "DESC";
		if(Settings.general().get_boolean("articlelist-oldest-first") && state == ArticleListState.UNREAD)
			desc = "ASC";

		if(searchRows != 0)
		{
			string orderBy = ((ArticleListSort)Settings.general().get_enum("articlelist-sort-by") == ArticleListSort.RECEIVED) ? "rowid" : "date";
			query.addCustomCondition(@"articleID in (SELECT articleID FROM articles ORDER BY $orderBy $desc LIMIT $searchRows)");
		}

		query.limit(limit);
		query.offset(offset);
		query.build();

		Sqlite.Statement stmt = m_db.prepare(query.get());

		var tmp = new Gee.LinkedList<Article>();
		while (stmt.step () == Sqlite.ROW)
		{
			tmp.add(new Article(
								stmt.column_text(2),																		// articleID
								stmt.column_text(3),																		// title
								stmt.column_text(5),																		// url
								stmt.column_text(1),																		// feedID
								(ArticleStatus)stmt.column_int(7),											// unread
								(ArticleStatus)stmt.column_int(8),											// marked
								null,																											// html
								stmt.column_text(6),																		// preview
								stmt.column_text(4),																		// author
								new GLib.DateTime.from_unix_local(stmt.column_int(10)),	// date
								stmt.column_int(0),																			// sortID
								StringUtils.split(stmt.column_text(9), ",", true),  		// tags
								StringUtils.split(stmt.column_text(12), ",", true), 		// media
								stmt.column_text(11)																		// guid
							));
		}

		return tmp;
	}

}
