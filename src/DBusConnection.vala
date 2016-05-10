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

namespace FeedReader {

	[DBus (name = "org.gnome.feedreader")]
	interface FeedDaemon : Object {
		public abstract void scheduleSync(int time) throws IOError;
		public abstract void startSync() throws IOError;
		public abstract void startInitSync() throws IOError;
		public abstract LoginResponse login(Backend type) throws IOError;
		public abstract LoginResponse isLoggedIn() throws IOError;
		public abstract bool isOnline() throws IOError;
		public abstract bool supportMultiLevelCategories() throws IOError;
		public abstract void changeArticle(string articleID, ArticleStatus status) throws IOError;
		public abstract void markFeedAsRead(string feedID, bool isCat) throws IOError;
		public abstract void markAllItemsRead() throws IOError;
		public abstract void tagArticle(string articleID, string tagID, bool add) throws IOError;
		public abstract void deleteTag(string tagID) throws IOError;
		public abstract void renameTag(string tagID, string newName) throws IOError;
		public abstract void updateTagColor(string tagID, int color) throws IOError;
		public abstract void resetDB() throws IOError;
		public abstract string createTag(string caption) throws IOError;
		public abstract void updateBadge() throws IOError;
		public abstract bool supportTags() throws IOError;
		public abstract bool checkOnlineAsync() throws IOError;
		public abstract string addCategory(string title, string parentID, bool createLocally) throws IOError;
		public abstract void removeCategory(string catID) throws IOError;
		public abstract void removeCategoryWithChildren(string catID) throws IOError;
		public abstract void moveCategory(string catID, string newParentID) throws IOError;
		public abstract void renameCategory(string catID, string newName) throws IOError;
		public abstract void addFeed(string feedURL, string cat, bool isID) throws IOError;
		public abstract void removeFeed(string feedID) throws IOError;
		public abstract void removeFeedOnlyFromCat(string m_feedID, string m_catID) throws IOError;
		public abstract void moveFeed(string feedID, string currentCatID, string? newCatID = null) throws IOError;
		public abstract void renameFeed(string feedID, string newName) throws IOError;
		public abstract void importOPML(string opml) throws IOError;
		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void newArticleList();
		public signal void updateArticleList();
		public signal void writeInterfaceState();
		public signal void showArticleListOverlay();
		public signal void setOffline();
		public signal void setOnline();
		public signal void feedAdded();
		public signal void opmlImported();
	}


	public class DBusConnection : GLib.Object {

		public DBusConnection()
		{

		}

		public static void setup()
		{
			try{
				feedDaemon_interface = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.feedreader", "/org/gnome/feedreader");
			}catch (IOError e) {
				logger.print(LogMessage.ERROR, e.message);
			}
		}

		public static void connectSignals(readerUI window)
		{
			feedDaemon_interface.newFeedList.connect(() => {
				window.getContent().newFeedList();
			});

			feedDaemon_interface.updateFeedList.connect(() => {
				window.getContent().updateFeedList();
			});

			feedDaemon_interface.newArticleList.connect(() => {
				window.getContent().newHeadlineList();
			});

			feedDaemon_interface.updateArticleList.connect(() => {
				window.getContent().updateArticleList();
			});

			feedDaemon_interface.syncStarted.connect(() => {
				window.writeInterfaceState();
				window.setRefreshButton(true);
			});

			feedDaemon_interface.syncFinished.connect(() => {
				logger.print(LogMessage.DEBUG, "sync finished -> update ui");
				window.getContent().syncFinished();
				window.showContent(Gtk.StackTransitionType.SLIDE_LEFT, true);
				window.setRefreshButton(false);
			});

			feedDaemon_interface.springCleanStarted.connect(() => {
				window.showSpringClean();
			});

			feedDaemon_interface.springCleanFinished.connect(() => {
				window.showContent();
			});

			feedDaemon_interface.writeInterfaceState.connect(() => {
				window.writeInterfaceState();
			});

			feedDaemon_interface.showArticleListOverlay.connect(() => {
				window.getContent().showArticleListOverlay();
			});

			feedDaemon_interface.setOffline.connect(() => {
				window.setOffline();
			});

			feedDaemon_interface.setOnline.connect(() => {
				window.setOnline();
			});

			feedDaemon_interface.feedAdded.connect(() => {
				window.getContent().footerSetReady();
			});

			feedDaemon_interface.opmlImported.connect(() => {
				window.getContent().footerSetReady();
			});
		}

	}
}
