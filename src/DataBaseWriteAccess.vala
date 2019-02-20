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

public class FeedReader.DataBase : DataBaseReadOnly {

public static new DataBase writeAccess()
{
	var database = new DataBase();
	if(database.uninitialized())
	{
		database.init();
	}

	return database;
}

public static new DataBaseReadOnly readOnly()
{
	return writeAccess() as DataBaseReadOnly;
}

public DataBase(string dbFile = "feedreader-%01i.db".printf(Constants.DB_SCHEMA_VERSION))
{
	base(dbFile);
}

public void checkpoint()
{
	m_db.checkpoint();
}

public bool resetDB()
{
	Logger.warning("resetDB");
	m_db.simple_query("DROP TABLE main.fts_table");
	m_db.simple_query("DROP TABLE main.taggings");
	m_db.simple_query("DROP TABLE main.Enclosures");
	m_db.simple_query("DROP TABLE main.CachedActions");
	m_db.simple_query("DROP TABLE main.tags");
	m_db.simple_query("DROP TABLE main.articles");
	m_db.simple_query("DROP TABLE main.categories");
	m_db.simple_query("DROP TABLE main.feeds");
	m_db.simple_query("VACUUM");

	string query = "PRAGMA INTEGRITY_CHECK";
	Sqlite.Statement stmt = m_db.prepare(query);

	int cols = stmt.column_count ();
	while (stmt.step () == Sqlite.ROW) {
		for (int i = 0; i < cols; i++) {
			if(stmt.column_text(i) != "ok")
			{
				Logger.error("resetting the database failed");
				return false;
			}
		}
	}
	stmt.reset();
	return true;
}

public void updateFTS()
{
	m_db.simple_query("INSERT INTO fts_table(fts_table) VALUES('rebuild')");
}

public void springCleaning()
{
	m_db.simple_query("VACUUM");
	var now = new DateTime.now_local();
	Settings.state().set_int("last-spring-cleaning", (int)now.to_unix());
}

public void dropOldArticles(int weeks)
{
	var query = new QueryBuilder(QueryType.SELECT, "main.articles");
	query.select_field("articleID");
	query.select_field("feedID");
	query.where("datetime(date, 'unixepoch', 'localtime') <= datetime('now', '-%i days')".printf(weeks*7));
	query.where_equal_int("marked", ArticleStatus.UNMARKED.to_int());
	if(FeedServer.get_default().useMaxArticles())
	{
		int syncCount = Settings.general().get_int("max-articles");
		query.where(@"rowid BETWEEN 1 AND (SELECT rowid FROM articles ORDER BY rowid DESC LIMIT 1 OFFSET $syncCount)");
	}

	Sqlite.Statement stmt = m_db.prepare(query.to_string());
	while (stmt.step () == Sqlite.ROW) {
		delete_article(stmt.column_text(0), stmt.column_text(1));
	}
}

private void delete_article(string articleID, string feedID)
{
	Logger.info(@"Deleting article \"$articleID\"");
	m_db.execute("DELETE FROM main.articles WHERE articleID = ?", { articleID });
	m_db.execute("DELETE FROM main.Enclosures WHERE articleID = ?", { articleID });
	string folder_path = GLib.Environment.get_user_data_dir() + @"/feedreader/data/images/$feedID/$articleID/";
	Utils.remove_directory(folder_path);
}

public void dropTag(Tag tag)
{
	m_db.execute("DELETE FROM main.tags WHERE tagID = ?", { tag.getTagID() });
	m_db.execute("DELETE FROM main.taggings WHERE tagID = ?",  { tag.getTagID() });
}

public void write_feeds(Gee.Collection<Feed> feeds)
{
	m_db.simple_query("BEGIN TRANSACTION");

	var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "main.feeds");
	query.insert_param("feed_id", "$FEEDID");
	query.insert_param("name", "$FEEDNAME");
	query.insert_param("url", "$FEEDURL");
	query.insert_param("category_id", "$CATID");
	query.insert_int("subscribed", 1);
	query.insert_param("xmlURL", "$XMLURL");
	query.insert_param("iconURL", "$ICONURL");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int feedID_pos   = stmt.bind_parameter_index("$FEEDID");
	int feedName_pos = stmt.bind_parameter_index("$FEEDNAME");
	int feedURL_pos  = stmt.bind_parameter_index("$FEEDURL");
	int catID_pos    = stmt.bind_parameter_index("$CATID");
	int xmlURL_pos   = stmt.bind_parameter_index("$XMLURL");
	int iconURL_pos  = stmt.bind_parameter_index("$ICONURL");
	assert (feedID_pos > 0);
	assert (feedName_pos > 0);
	assert (feedURL_pos > 0);
	assert (catID_pos > 0);
	assert (xmlURL_pos > 0);
	assert (iconURL_pos > 0);

	foreach(var feed_item in feeds)
	{
		stmt.bind_text(feedID_pos, feed_item.getFeedID());
		stmt.bind_text(feedName_pos, feed_item.getTitle());
		stmt.bind_text(feedURL_pos, feed_item.getURL());
		stmt.bind_text(catID_pos, StringUtils.join(feed_item.getCatIDs(), ","));
		stmt.bind_text(xmlURL_pos, feed_item.getXmlUrl());
		stmt.bind_text(iconURL_pos, feed_item.getIconURL());

		while(stmt.step() == Sqlite.ROW) {}
		stmt.reset();
	}

	m_db.simple_query("COMMIT TRANSACTION");
}

public void write_tag(Tag tag)
{
	var list = new Gee.ArrayList<Tag>();
	list.add(tag);
	write_tags(list);
}

public void write_tags(Gee.Collection<Tag> tags)
{
	m_db.simple_query("BEGIN TRANSACTION");

	var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "main.tags");
	query.insert_param("tagID", "$TAGID");
	query.insert_param("title", "$LABEL");
	query.insert_int("\"exists\"", 1);
	query.insert_param("color", "$COLOR");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int tagID_position = stmt.bind_parameter_index("$TAGID");
	int label_position = stmt.bind_parameter_index("$LABEL");
	int color_position = stmt.bind_parameter_index("$COLOR");
	assert (tagID_position > 0);
	assert (label_position > 0);
	assert (color_position > 0);

	foreach(var tag_item in tags)
	{
		stmt.bind_text(tagID_position, tag_item.getTagID());
		stmt.bind_text(label_position, tag_item.getTitle());
		stmt.bind_int (color_position, tag_item.getColor());

		while(stmt.step() == Sqlite.ROW) {}
		stmt.reset ();
	}

	m_db.simple_query("COMMIT TRANSACTION");
}

public void update_tag(Tag tag)
{
	update_tags(ListUtils.single(tag));

	if(FeedServer.get_default().tagIDaffectedByNameChange())
	{
		string newID = tag.getTagID().replace(tag.getTitle(), tag.getTitle());
		m_db.execute("UPDATE tags SET tagID = ? WHERE tagID = ?", { newID, tag.getTagID() });
	}
}

public void update_tags(Gee.List<Tag> tags)
{
	m_db.simple_query("BEGIN TRANSACTION");

	var query = new QueryBuilder(QueryType.UPDATE, "main.tags");
	query.update_param("title", "$TITLE");
	query.update_int("\"exists\"", 1);
	query.where_equal_param("tagID", "$TAGID");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int title_position = stmt.bind_parameter_index("$TITLE");
	int tagID_position = stmt.bind_parameter_index("$TAGID");
	assert (title_position > 0);
	assert (tagID_position > 0);

	foreach(var tag_item in tags)
	{
		stmt.bind_text(title_position, tag_item.getTitle());
		stmt.bind_text(tagID_position, tag_item.getTagID());
		while (stmt.step () == Sqlite.ROW) {}
		stmt.reset ();
	}

	m_db.simple_query("COMMIT TRANSACTION");
}


public void write_categories(Gee.List<Category> categories)
{
	m_db.simple_query("BEGIN TRANSACTION");

	var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "main.categories");
	query.insert_param("categorieID", "$CATID");
	query.insert_param("title", "$FEEDNAME");
	query.insert_param("orderID", "$ORDERID");
	query.insert_int("\"exists\"", 1);
	query.insert_param("Parent", "$PARENT");
	query.insert_param("Level", "$LEVEL");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int catID_position       = stmt.bind_parameter_index("$CATID");
	int feedName_position    = stmt.bind_parameter_index("$FEEDNAME");
	int orderID_position     = stmt.bind_parameter_index("$ORDERID");
	int parent_position      = stmt.bind_parameter_index("$PARENT");
	int level_position       = stmt.bind_parameter_index("$LEVEL");
	assert (catID_position > 0);
	assert (feedName_position > 0);
	assert (orderID_position > 0);
	assert (parent_position > 0);
	assert (level_position > 0);

	foreach(var cat_item in categories)
	{
		stmt.bind_text(catID_position, cat_item.getCatID());
		stmt.bind_text(feedName_position, cat_item.getTitle());
		stmt.bind_int (orderID_position, cat_item.getOrderID());
		stmt.bind_text(parent_position, cat_item.getParent());
		stmt.bind_int (level_position, cat_item.getLevel());

		while (stmt.step () == Sqlite.ROW) {}
		stmt.reset ();
	}

	m_db.simple_query("COMMIT TRANSACTION");
}

public void updateArticlesByID(Gee.List<string> ids, string field)
{
	// first reset all articles
	var reset_query = new QueryBuilder(QueryType.UPDATE, "main.articles");
	if(field == "unread")
	{
		reset_query.update_int(field, ArticleStatus.READ.to_int());
	}
	else if(field == "marked")
	{
		reset_query.update_int(field, ArticleStatus.UNMARKED.to_int());
	}
	m_db.simple_query(reset_query.to_string());


	m_db.simple_query("BEGIN TRANSACTION");

	// then reapply states of the synced articles
	var update_query = new QueryBuilder(QueryType.UPDATE, "main.articles");

	if(field == "unread")
	{
		update_query.update_int(field, ArticleStatus.UNREAD.to_int());
	}
	else if(field == "marked")
	{
		update_query.update_int(field, ArticleStatus.MARKED.to_int());
	}

	update_query.where_equal_param("articleID", "$ARTICLEID");

	Sqlite.Statement stmt = m_db.prepare(update_query.to_string());

	int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
	assert (articleID_position > 0);


	foreach(string id in ids)
	{
		stmt.bind_text(articleID_position, id);
		while(stmt.step() != Sqlite.DONE) {}
		stmt.reset();
	}

	m_db.simple_query("COMMIT TRANSACTION");
}

public void writeContent(Article article)
{
	var update_query = new QueryBuilder(QueryType.UPDATE, "main.articles");
	update_query.update_param("html", "$HTML");
	update_query.update_param("preview", "$PREVIEW");
	update_query.update_int("contentFetched", 1);
	update_query.where_equal_string("articleID", article.getArticleID());

	Sqlite.Statement stmt = m_db.prepare(update_query.to_string());

	int html_position = stmt.bind_parameter_index("$HTML");
	int preview_position = stmt.bind_parameter_index("$PREVIEW");
	assert (html_position > 0);
	assert (preview_position > 0);


	stmt.bind_text(html_position, article.getHTML());
	stmt.bind_text(preview_position, article.getPreview());

	while(stmt.step() != Sqlite.DONE) {}
	stmt.reset();
}

public void update_article(Article article)
{
	update_articles(ListUtils.single(article));
}

public void update_articles(Gee.List<Article> articles)
{
	m_db.simple_query("BEGIN TRANSACTION");

	var update_query = new QueryBuilder(QueryType.UPDATE, "main.articles");
	update_query.update_param("unread", "$UNREAD");
	update_query.update_param("marked", "$MARKED");
	update_query.update_param("lastModified", "$LASTMODIFIED");
	update_query.where_equal_param("articleID", "$ARTICLEID");

	Sqlite.Statement stmt = m_db.prepare(update_query.to_string());

	int unread_position = stmt.bind_parameter_index("$UNREAD");
	int marked_position = stmt.bind_parameter_index("$MARKED");
	int modified_position = stmt.bind_parameter_index("$LASTMODIFIED");
	int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
	assert (unread_position > 0);
	assert (marked_position > 0);
	assert (modified_position > 0);
	assert (articleID_position > 0);


	foreach(Article a in articles)
	{
		var unread = ActionCache.get_default().checkRead(a);
		var marked = ActionCache.get_default().checkStarred(a.getArticleID(), a.getMarked());

		if(unread != ArticleStatus.READ && unread != ArticleStatus.UNREAD)
		{
			Logger.warning(@"DataBase.update_articles: writing invalid unread status $unread for article " + a.getArticleID());
		}

		if(marked != ArticleStatus.MARKED && marked != ArticleStatus.UNMARKED)
		{
			Logger.warning(@"DataBase.update_articles: writing invalid marked status $marked for article " + a.getArticleID());
		}

		stmt.bind_int (unread_position, unread);
		stmt.bind_int (marked_position, marked);
		stmt.bind_int (modified_position, a.getLastModified());
		stmt.bind_text(articleID_position, a.getArticleID());

		while(stmt.step() != Sqlite.DONE) {}
		stmt.reset();

		write_taggings(a);
	}

	m_db.simple_query("COMMIT TRANSACTION");
}


public void write_articles(Gee.List<Article> articles)
{
	Utils.generatePreviews(articles);
	Utils.checkHTML(articles);

	m_db.simple_query("BEGIN TRANSACTION");

	var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "main.articles");
	query.insert_param("articleID", "$ARTICLEID");
	query.insert_param("feedID", "$FEEDID");
	query.insert_param("title", "$TITLE");
	query.insert_param("author", "$AUTHOR");
	query.insert_param("url", "$URL");
	query.insert_param("html", "$HTML");
	query.insert_param("preview", "$PREVIEW");
	query.insert_param("unread", "$UNREAD");
	query.insert_param("marked", "$MARKED");
	query.insert_param("date", "$DATE");
	query.insert_param("guidHash", "$GUIDHASH");
	query.insert_param("lastModified", "$LASTMODIFIED");
	query.insert_int("contentFetched", 0);

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
	int feedID_position = stmt.bind_parameter_index("$FEEDID");
	int url_position = stmt.bind_parameter_index("$URL");
	int unread_position = stmt.bind_parameter_index("$UNREAD");
	int marked_position = stmt.bind_parameter_index("$MARKED");
	int title_position = stmt.bind_parameter_index("$TITLE");
	int html_position = stmt.bind_parameter_index("$HTML");
	int preview_position = stmt.bind_parameter_index("$PREVIEW");
	int author_position = stmt.bind_parameter_index("$AUTHOR");
	int date_position = stmt.bind_parameter_index("$DATE");
	int guidHash_position = stmt.bind_parameter_index("$GUIDHASH");
	int modified_position = stmt.bind_parameter_index("$LASTMODIFIED");

	assert (articleID_position > 0);
	assert (feedID_position > 0);
	assert (url_position > 0);
	assert (unread_position > 0);
	assert (marked_position > 0);
	assert (title_position > 0);
	assert (html_position > 0);
	assert (preview_position > 0);
	assert (author_position > 0);
	assert (date_position > 0);
	assert (guidHash_position > 0);
	assert (modified_position > 0);

	foreach(var article in articles)
	{
		// if article time is in the future
		var now = new GLib.DateTime.now_local();
		if(article.getDate().compare(now) == 1)
		{
			article.SetDate(now);
		}

		int? weeks = ((DropArticles)Settings.general().get_enum("drop-articles-after")).to_weeks();
		if(weeks != null && article.getDate().compare(now.add_weeks(-(int)weeks)) == -1)
		{
			Logger.info("Ignoring old article: %s".printf(article.getTitle()));
			continue;
		}

		stmt.bind_text(articleID_position, article.getArticleID());
		stmt.bind_text(feedID_position, article.getFeedID());
		stmt.bind_text(url_position, article.getURL());
		stmt.bind_int (unread_position, article.getUnread());
		stmt.bind_int (marked_position, article.getMarked());
		stmt.bind_text(title_position, Utils.UTF8fix(article.getTitle()));
		stmt.bind_text(html_position, article.getHTML());
		stmt.bind_text(preview_position, Utils.UTF8fix(article.getPreview(), true));
		stmt.bind_text(author_position, article.getAuthor());
		stmt.bind_int64(date_position, article.getDate().to_unix());
		stmt.bind_text(guidHash_position, article.getHash());
		stmt.bind_int (modified_position, article.getLastModified());

		while(stmt.step() != Sqlite.DONE) {}
		stmt.reset();

		write_enclosures(article);
		write_taggings(article);
	}

	m_db.simple_query("COMMIT TRANSACTION");
}

private void write_taggings(Article article)
{
	var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "main.taggings");
	query.insert_param("articleID", "$ARTICLEID");
	query.insert_param("tagID", "$TAGID");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
	int tagID_position = stmt.bind_parameter_index("$TAGID");

	assert (articleID_position > 0);
	assert (tagID_position > 0);

	foreach(string tagID in article.getTagIDs())
	{
		stmt.bind_text(articleID_position, article.getArticleID());
		stmt.bind_text(tagID_position, tagID);

		while(stmt.step() != Sqlite.DONE) {}
		stmt.reset();
	}
}

private void write_enclosures(Article article)
{
	var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "main.Enclosures");
	query.insert_param("articleID", "$ARTICLEID");
	query.insert_param("url", "$URL");
	query.insert_param("type", "$TYPE");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
	int url_position = stmt.bind_parameter_index("$URL");
	int type_position = stmt.bind_parameter_index("$TYPE");

	assert (articleID_position > 0);
	assert (url_position > 0);
	assert (type_position > 0);

	foreach(Enclosure enc in article.getEnclosures())
	{
		stmt.bind_text(articleID_position, article.getArticleID());
		stmt.bind_text(url_position, enc.get_url());
		stmt.bind_int (type_position, enc.get_enclosure_type());

		while(stmt.step() != Sqlite.DONE) {}
		stmt.reset();
	}
}

public void markCategorieRead(string catID)
{
	var query = new QueryBuilder(QueryType.UPDATE, "main.articles");
	query.update_int("unread", ArticleStatus.READ.to_int());
	query.where_in_strings("feedID", getFeedIDofCategorie(catID));
	m_db.simple_query(query.to_string());
}

public void markFeedRead(string feedID)
{
	m_db.execute("UPDATE main.articles SET unread = ? WHERE feedID = ?", { ArticleStatus.READ, feedID });
}

public void markAllRead()
{
	m_db.execute("UPDATE main.articles SET unread = ?", { ArticleStatus.READ });
}

public void reset_subscribed_flag()
{
	m_db.simple_query("UPDATE main.feeds SET \"subscribed\" = 0");
}

public void reset_exists_tag()
{
	m_db.simple_query("UPDATE main.tags SET \"exists\" = 0");
}

public void reset_exists_flag()
{
	m_db.simple_query("UPDATE main.categories SET \"exists\" = 0");
}

public void delete_unsubscribed_feeds()
{
	Logger.warning("DataBase: Deleting unsubscribed feeds");
	m_db.simple_query("DELETE FROM main.feeds WHERE \"subscribed\" = 0");
}

public void delete_nonexisting_categories()
{
	Logger.warning("DataBase: Deleting nonexisting categories");
	m_db.simple_query("DELETE FROM main.categories WHERE \"exists\" = 0");
}

public void delete_nonexisting_tags()
{
	Logger.warning("DataBase: Deleting nonexisting tags");
	m_db.simple_query("DELETE FROM main.tags WHERE \"exists\" = 0");
}

public void delete_articles_without_feed()
{
	Logger.warning("DataBase: Deleting articles without feed");
	var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
	query.select_field("feed_id");
	query.where_equal_int("subscribed", 0);

	Sqlite.Statement stmt = m_db.prepare(query.to_string());
	while(stmt.step () == Sqlite.ROW)
	{
		delete_articles(stmt.column_text(0));
	}
}

public void delete_articles(string feedID)
{
	Logger.warning(@"DataBase: Deleting all articles of feed \"$feedID\"");
	m_db.execute("DELETE FROM main.articles WHERE feedID = ?", { feedID });
	m_db.execute("DELETE FROM main.Enclosures WHERE articleID IN(SELECT articleID FROM main.articles WHERE feedID = ?)", { feedID });
	string folder_path = GLib.Environment.get_user_data_dir() + @"/feedreader/data/images/$feedID/";
	Utils.remove_directory(folder_path);
}

public void delete_category(string catID)
{
	m_db.execute("DELETE FROM main.categories WHERE categorieID = ?", { catID });
}

public void rename_category(string catID, string newName)
{
	if(FeedServer.get_default().tagIDaffectedByNameChange())
	{
		var cat = read_category(catID);
		string newID = catID.replace(cat.getTitle(), newName);
		var query = "UPDATE categories SET categorieID = ?, title = ? WHERE categorieID = ?";
		m_db.execute(query, {newID, newName, catID });

		query = "UPDATE feeds SET category_id = replace(category_id, ?,  ?) WHERE instr(category_id, ?)";
		m_db.execute(query, { catID, newID, catID });
	}
	else
	{
		var query = "UPDATE categories SET title = ? WHERE categorieID = ?";
		m_db.execute(query, { newName, catID });
	}
}

public void move_category(string catID, string newParentID)
{
	var parent = read_category(newParentID);
	var query = "UPDATE categories SET Parent = ?,  Level = ? WHERE categorieID = ?";
	m_db.execute(query, { newParentID, parent.getLevel() + 1, catID });
}

public void rename_feed(string feedID, string newName)
{
	var query = "UPDATE feeds SET name = ? WHERE feed_id = ?";
	m_db.execute(query, { newName, feedID });
}

public void move_feed(string feedID, string currentCatID, string? newCatID = null)
{
	var Feed = read_feed(feedID);
	var categories = Feed.getCatIDs();
	categories.remove(currentCatID);

	if(newCatID != null)
	{
		categories.add(newCatID);
	}

	string catString = StringUtils.join(categories, ",");

	var query = "UPDATE feeds SET category_id = ? WHERE feed_id = ?";
	m_db.execute(query, { catString, feedID });
}

public void removeCatFromFeed(string feedID, string catID)
{
	var feed = read_feed(feedID);
	m_db.execute("UPDATE feeds SET category_id = ? WHERE feed_id = ?",
	             { feed.getCatString().replace(catID + ",", ""), feedID });
}

public void delete_feed(string feedID)
{
	m_db.execute("DELETE FROM feeds WHERE feed_id = ?", { feedID });
	delete_articles(feedID);
}

public void addCachedAction(CachedActions action, string id, string? argument = "")
{
	m_db.simple_query("BEGIN TRANSACTION");

	var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "main.CachedActions");
	query.insert_param("action", "$ACTION");
	query.insert_param("id", "$ID");
	query.insert_param("argument", "$ARGUMENT");

	Sqlite.Statement stmt = m_db.prepare(query.to_string());

	int action_position = stmt.bind_parameter_index("$ACTION");
	int id_position = stmt.bind_parameter_index("$ID");
	int argument_position = stmt.bind_parameter_index("$ARGUMENT");
	assert (action_position > 0);
	assert (id_position > 0);
	assert (argument_position > 0);

	stmt.bind_int (action_position, action);
	stmt.bind_text(id_position, id);
	stmt.bind_text(argument_position, argument);

	while (stmt.step () == Sqlite.ROW) {}
	stmt.reset ();

	m_db.simple_query("COMMIT TRANSACTION");
}


public Gee.List<CachedAction> readCachedActions()
{
	var query = "SELECT * FROM CachedActions";
	var rows = m_db.execute(query);
	var actions = new Gee.ArrayList<CachedAction>();
	foreach(var row in rows)
	{
		var action = new CachedAction(
			(CachedActions)row[0].to_int(),
			row[1].to_string(),
			row[2].to_string());
		action.print();
		actions.add(action);
	}
	return actions;
}

public void resetCachedActions()
{
	Logger.warning("resetCachedActions");
	m_db.simple_query("DELETE FROM CachedActions");
}

public bool cachedActionNecessary(CachedAction action)
{
	var query = "SELECT COUNT(*) FROM CachedActions WHERE argument = ? AND id = ? AND action = ?";
	var rows = m_db.execute(query, { action.getArgument(), action.getID(), action.opposite() });
	assert(rows.size == 1 && rows[0].size == 1);
	return rows[0][0].to_int() == 0;
}

public void deleteOppositeCachedAction(CachedAction action)
{
	var query = "DELETE FROM CachedActions WHERE argument = ? AND id = ? AND action = ?";
	m_db.execute(query, { action.getArgument(), action.getID(), action.opposite() });
}

}
