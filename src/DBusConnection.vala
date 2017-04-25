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

	[DBus (name = "org.gnome.FeedReader.Daemon")]
	public interface FeedDaemon : Object {

		public abstract void scheduleSync(int time) throws IOError;
		public abstract void startSync(bool initSync = false) throws IOError;
		public abstract void cancelSync() throws IOError;
		public abstract void changeArticle(string articleID, ArticleStatus status) throws IOError;
		public abstract void markFeedAsRead(string feedID, bool isCat) throws IOError;
		public abstract void markAllItemsRead() throws IOError;
		public abstract void updateBadge() throws IOError;


		// OFFLINE / ONLINE
		public abstract LoginResponse login(string plugin) throws IOError;
		public abstract LoginResponse isLoggedIn() throws IOError;
		public abstract bool isOnline() throws IOError;
		public abstract bool checkOnlineAsync() throws IOError;

		// GENERAL
		public abstract void resetAccount() throws IOError;
		public abstract void resetDB() throws IOError;
		public abstract int getVersion() throws IOError;
		public abstract void quit() throws IOError;

		// BACKEND INFOS
		public abstract bool hideCagetoryWhenEmtpy(string catID) throws IOError;
		public abstract bool supportCategories() throws IOError;
		public abstract bool supportFeedManipulation() throws IOError;
		public abstract bool supportMultiLevelCategories() throws IOError;
		public abstract bool supportTags() throws IOError;
		public abstract bool useMaxArticles() throws IOError;
		public abstract string symbolicIcon() throws IOError;
		public abstract string accountName() throws IOError;
		public abstract string getServerURL() throws IOError;
		public abstract string uncategorizedID() throws IOError;

		// MANIPULATE TAGS
		public abstract string createTag(string caption) throws IOError;
		public abstract void tagArticle(string articleID, string tagID, bool add) throws IOError;
		public abstract void deleteTag(string tagID) throws IOError;
		public abstract void renameTag(string tagID, string newName) throws IOError;
		public abstract void updateTagColor(string tagID, int color) throws IOError;

		// MANIPULATE CATEGORIES
		public abstract string addCategory(string title, string parentID, bool createLocally) throws IOError;
		public abstract void removeCategory(string catID) throws IOError;
		public abstract void removeCategoryWithChildren(string catID) throws IOError;
		public abstract void moveCategory(string catID, string newParentID) throws IOError;
		public abstract void renameCategory(string catID, string newName) throws IOError;

		// MANIPULATE FEEDS
		public abstract void addFeed(string feedURL, string cat, bool isID, bool asynchron = true) throws IOError;
		public abstract void removeFeed(string feedID) throws IOError;
		public abstract void removeFeedOnlyFromCat(string m_feedID, string m_catID) throws IOError;
		public abstract void moveFeed(string feedID, string currentCatID, string? newCatID = null) throws IOError;
		public abstract void renameFeed(string feedID, string newName) throws IOError;
		public abstract void importOPML(string opml) throws IOError;

		// SIGNALS
		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void updateArticleList();
		public signal void writeInterfaceState();
		public signal void showArticleListOverlay();
		public signal void setOffline();
		public signal void setOnline();
		public signal void feedAdded();
		public signal void opmlImported();
		public signal void updateSyncProgress(string progress);
	}


	public class DBusConnection : GLib.Object {

		private static FeedDaemon? m_connection = null;

		public static FeedDaemon get_default()
		{
			if(m_connection == null)
				setup();

			return m_connection;
		}

		private DBusConnection()
		{

		}

		private static void setup()
		{
			try
			{
				m_connection = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.FeedReader.Daemon", "/org/gnome/FeedReader/Daemon");
			}
			catch(IOError e)
			{
				Logger.error("Failed to connect to daemon! " + e.message);
			}

			checkDaemonVersion();
		}

		public static void connectSignals()
		{
			if(m_connection == null)
				setup();

			m_connection.newFeedList.connect(() => {
				Logger.debug("DBusConnection: newFeedList");
				ColumnView.get_default().newFeedList();
			});

			m_connection.updateFeedList.connect(() => {
				Logger.debug("DBusConnection: updateFeedList");
				ColumnView.get_default().updateFeedList();
			});

			m_connection.updateArticleList.connect(() => {
				Logger.debug("DBusConnection: updateArticleList");
				ColumnView.get_default().updateArticleList();
			});

			m_connection.syncStarted.connect(() => {
				Logger.debug("DBusConnection: syncStarted");
				MainWindow.get_default().writeInterfaceState();
				ColumnView.get_default().getHeader().setRefreshButton(true);
			});

			m_connection.syncFinished.connect(() => {
				Logger.debug("DBusConnection: syncFinished");
				ColumnView.get_default().syncFinished();
				MainWindow.get_default().showContent(Gtk.StackTransitionType.SLIDE_LEFT, true);
				ColumnView.get_default().getHeader().setRefreshButton(false);
			});

			m_connection.springCleanStarted.connect(() => {
				Logger.debug("DBusConnection: springCleanStarted");
				MainWindow.get_default().showSpringClean();
			});

			m_connection.springCleanFinished.connect(() => {
				Logger.debug("DBusConnection: springCleanFinished");
				MainWindow.get_default().showContent();
			});

			m_connection.writeInterfaceState.connect(() => {
				Logger.debug("DBusConnection: writeInterfaceState");
				MainWindow.get_default().writeInterfaceState();
			});

			m_connection.showArticleListOverlay.connect(() => {
				Logger.debug("DBusConnection: showArticleListOverlay");
				ColumnView.get_default().showArticleListOverlay();
			});

			m_connection.setOffline.connect(() => {
				Logger.debug("DBusConnection: setOffline");
				if(FeedReaderApp.get_default().isOnline())
				{
					FeedReaderApp.get_default().setOnline(false);
					ColumnView.get_default().setOffline();
				}
			});

			m_connection.setOnline.connect(() => {
				Logger.debug("DBusConnection: setOnline");
				if(!FeedReaderApp.get_default().isOnline())
				{
					FeedReaderApp.get_default().setOnline(true);
					ColumnView.get_default().setOnline();
				}
			});

			m_connection.feedAdded.connect(() => {
				Logger.debug("DBusConnection: feedAdded");
				ColumnView.get_default().footerSetReady();
			});

			m_connection.opmlImported.connect(() => {
				Logger.debug("DBusConnection: opmlImported");
				ColumnView.get_default().footerSetReady();
				ColumnView.get_default().newFeedList();
			});

			m_connection.updateSyncProgress.connect((progress) => {
				Logger.debug("DBusConnection: updateSyncProgress");
				ColumnView.get_default().getHeader().updateSyncProgress(progress);
			});
		}

		private static void checkDaemonVersion()
		{
			try
			{
				if(m_connection.getVersion() < Constants.DBusAPIVersion)
				{
					m_connection.quit();

					// call random method on dbus-server of daemon to spawn the process again
					m_connection.isOnline();
				}
			}
			catch(GLib.Error e)
			{
				Logger.error("checkDaemonVersion: %s".printf(e.message));
			}

		}

	}
}
