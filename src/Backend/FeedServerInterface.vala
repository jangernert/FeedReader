//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public interface FeedReader.FeedServerInterface : GLib.Object {

	public signal void newFeedList();
	public signal void refreshFeedListCounter();
	public signal void updateArticleList();
	public signal void showArticleListOverlay();
	public signal void writeArticles(Gee.List<Article> articles);

	public abstract void init(GLib.SettingsBackend settings_backend, Secret.Collection secrets, DataBaseReadOnly db, DataBase db_write, string? host = null);

	public abstract bool supportTags();

	public abstract bool doInitSync();

	public abstract string symbolicIcon();

	public abstract string accountName();

	public abstract string getServerURL();

	public abstract string uncategorizedID();

	public abstract bool hideCategoryWhenEmpty(string catID);

	public abstract bool supportCategories();

	public abstract bool supportFeedManipulation();

	public abstract bool supportMultiLevelCategories();

	public abstract bool supportMultiCategoriesPerFeed();

	public abstract bool syncFeedsAndCategories();

	// some backends (inoreader, feedly) have the tag-name as part of the ID
	// but for some of them the tagID changes when the name was changed (inoreader)
	public abstract bool tagIDaffectedByNameChange();

	public abstract void resetAccount();

	// whether or not to use the "max-articles"-setting
	public abstract bool useMaxArticles();

	public abstract LoginResponse login();

	public abstract bool logout();

	public abstract void setArticleIsRead(string articleIDs, ArticleStatus read);

	public abstract void setArticleIsMarked(string articleID, ArticleStatus marked);

	public abstract void setFeedRead(string feedID);

	public abstract void setCategoryRead(string catID);

	public abstract void markAllItemsRead();

	public abstract void tagArticle(string articleID, string tagID);

	public abstract void removeArticleTag(string articleID, string tagID);

	public abstract string createTag(string caption);

	public abstract void deleteTag(string tagID);

	public abstract void renameTag(string tagID, string title);

	public abstract bool serverAvailable();

	public abstract bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg);

	public abstract void addFeeds(Gee.List<Feed> feeds);

	public abstract void removeFeed(string feedID);

	public abstract void renameFeed(string feedID, string title);

	public abstract void moveFeed(string feedID, string newCatID, string? currentCatID = null);

	public abstract string createCategory(string title, string? parentID = null);

	public abstract void renameCategory(string catID, string title);

	public abstract void moveCategory(string catID, string newParentID);

	public abstract void deleteCategory(string catID);

	public abstract void removeCatFromFeed(string feedID, string catID);

	public abstract void importOPML(string opml);

	public abstract bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null);

	public abstract int getUnreadCount();

	public abstract void getArticles(int count, ArticleStatus whatToGet = ArticleStatus.ALL, DateTime? since = null, string? feedID = null, bool isTagID = false, GLib.Cancellable? cancellable = null);

	// UI stuff
	public signal void tryLogin();

	public abstract string getWebsite();

	public abstract BackendFlags getFlags();

	public abstract string getID();

	public abstract Gtk.Box? getWidget();

	public abstract string iconName();

	public abstract string serviceName();

	public abstract bool needWebLogin();

	public abstract void showHtAccess();

	public abstract void writeData();

	public abstract async void postLoginAction();

	public abstract bool extractCode(string redirectURL);

	public abstract string buildLoginURL();

}
