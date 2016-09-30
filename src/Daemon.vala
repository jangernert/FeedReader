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

extern void exit(int exit_code);

namespace FeedReader {

	[DBus (name = "org.gnome.feedreader")]
	public class FeedDaemonServer : Object {

#if WITH_LIBUNITY
		private Unity.LauncherEntry m_launcher;
#endif
		private LoginResponse m_loggedin;
		private bool m_offline = true;
		private OfflineActionManager m_offlineActions;
		private uint m_timeout_source_id = 0;
		private delegate void asyncPayload();

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

		public FeedDaemonServer()
		{
			logger.print(LogMessage.DEBUG, "daemon: constructor");
			m_offlineActions = new OfflineActionManager();
			login(settings_general.get_string("plugin"));

#if WITH_LIBUNITY
			m_launcher = Unity.LauncherEntry.get_for_desktop_id("feedreader.desktop");
			updateBadge();
#endif
			scheduleSync(settings_general.get_int("sync"));
		}

		public void startSync()
		{
			callAsync.begin(sync, (obj, res) => {
				callAsync.begin.end(res);
			});
		}

		public void startInitSync()
		{
			callAsync.begin(initSync, (obj, res) => {
				callAsync.begin.end(res);
			});
		}

		public int getVersion()
		{
			return DBusAPIVersion;
		}


		public bool supportTags()
		{
			return server.supportTags();
		}

		public bool supportCategories()
		{
			return server.supportCategories();
		}

		public bool supportFeedManipulation()
		{
			return server.supportFeedManipulation();
		}

		public bool supportMultiLevelCategories()
		{
			return server.supportMultiLevelCategories();
		}

		public string? symbolicIcon()
		{
			logger.print(LogMessage.DEBUG, "daemon: symbolicIcon");
			return server.symbolicIcon();
		}

		public string? accountName()
		{
			return server.accountName();
		}

		public string? getServerURL()
		{
			return server.getServerURL();
		}

		public string uncategorizedID()
		{
			return server.uncategorizedID();
		}

		public bool hideCagetoryWhenEmtpy(string catID)
		{
			return server.hideCagetoryWhenEmtpy(catID);
		}

		public bool useMaxArticles()
		{
			return server.useMaxArticles();
		}

		public void scheduleSync(int time)
		{
			if (m_timeout_source_id > 0)
			{
				GLib.Source.remove(m_timeout_source_id);
				m_timeout_source_id = 0;
			}

			m_timeout_source_id = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, time*60, () => {
				if(!settings_state.get_boolean("currently-updating")
				&& server.pluginLoaded())
				{
			   		logger.print(LogMessage.DEBUG, "daemon: Timeout!");
					startSync();
				}
				return true;
			});
		}

		private void sync()
		{
			if(Utils.springCleaningNecessary())
			{
				logger.print(LogMessage.INFO, "daemon: spring cleaning");
				settings_state.set_boolean("spring-cleaning", true);
				springCleanStarted();
				dataBase.springCleaning();
				settings_state.set_boolean("spring-cleaning", false);
				springCleanFinished();
			}

			syncStarted();


			if(!checkOnline())
			{
				syncFinished();
				return;
			}

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				login(settings_general.get_string("plugin"));
				if(m_loggedin != LoginResponse.SUCCESS)
				{
					setOffline();
					syncFinished();
					return;
				}
			}

			if(m_loggedin == LoginResponse.SUCCESS && settings_state.get_boolean("currently-updating") == false)
			{
				logger.print(LogMessage.INFO, "daemon: sync started");
				settings_state.set_boolean("currently-updating", true);
				server.syncContent();
				updateBadge();
				settings_state.set_boolean("currently-updating", false);
				syncFinished();
				logger.print(LogMessage.INFO, "daemon: sync finished");
			}
			else
			{
				logger.print(LogMessage.DEBUG, "Cant sync because login failed or sync already ongoing");
			}
		}

		public bool checkOnline()
		{
			logger.print(LogMessage.DEBUG, "Daemon: checkOnline");
			if(!server.serverAvailable())
			{
				m_loggedin = LoginResponse.UNKNOWN_ERROR;
				setOffline();
				return false;
			}

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				server.logout();
				login(settings_general.get_string("plugin"));
			}

			setOnline();
			return true;
		}


		public async bool checkOnlineAsync()
		{
			logger.print(LogMessage.DEBUG, "Daemon: checkOnlineAsync");
			bool online = false;
			SourceFunc callback = checkOnlineAsync.callback;
			ThreadFunc<void*> run = () => {
				Idle.add((owned) callback);
				online = checkOnline();
				return null;
			};

			new GLib.Thread<void*>("checkOnlineAsync", run);
			yield;
			return online;
		}


		private void initSync()
		{
			if(!server.doInitSync())
				return;

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				login(settings_general.get_string("plugin"));
			}

			if(m_loggedin == LoginResponse.SUCCESS && settings_state.get_boolean("currently-updating") == false)
			{
				syncStarted();
				logger.print(LogMessage.INFO, "daemon: initSync started");
				settings_state.set_boolean("currently-updating", true);
				server.InitSyncContent();
				updateBadge();
				settings_state.set_boolean("currently-updating", false);
				syncFinished();
				logger.print(LogMessage.INFO, "daemon: initSync finished");
			}
			else
				logger.print(LogMessage.DEBUG, "Cant sync because login failed or sync already ongoing");
		}

		public LoginResponse login(string plugName)
		{
			logger.print(LogMessage.DEBUG, "daemon: new FeedServer and login");

			if(server == null)
				server = new FeedServer(plugName);
			else
			{
				server.unloadPlugin();
				server.loadPlugin(plugName);
			}

			if(!server.pluginLoaded())
			{
				logger.print(LogMessage.ERROR, "daemon: plugin '%s' couldn't be loaded by feedserver".printf(plugName));
				m_loggedin = LoginResponse.NO_BACKEND;
				return m_loggedin;
			}

			this.setOffline.connect(() => {
				m_offline = true;
			});
			this.setOnline.connect(() => {
				m_offline = false;
				if(dataBase.isTableEmpty("OfflineActions"))
				{
					m_offlineActions.goOnline();
					dataBase.resetOfflineActions();
				}
			});

			server.newFeedList.connect(() => {
				newFeedList();
			});

			server.updateFeedList.connect(() => {
				updateFeedList();
			});

			server.updateArticleList.connect(() => {
				updateArticleList();
			});

			server.writeInterfaceState.connect(() => {
				writeInterfaceState();
			});

			server.showArticleListOverlay.connect(() => {
				showArticleListOverlay();
			});

			m_loggedin = server.login();

			if(m_loggedin == LoginResponse.SUCCESS)
			{
				settings_general.set_string("plugin", plugName);
				setOnline();
			}
			else if(m_loggedin == LoginResponse.NO_BACKEND)
			{
				// do nothing
			}
			else
			{
				setOffline();
			}


			logger.print(LogMessage.DEBUG, "daemon: login status = " + m_loggedin.to_string());
			return m_loggedin;
		}

		public LoginResponse isLoggedIn()
		{
			return m_loggedin;
		}

		public bool isOnline()
		{
			if(m_loggedin != LoginResponse.SUCCESS)
			{
				return false;
			}

			return true;
		}

		public void changeArticle(string articleID, ArticleStatus status)
		{
			logger.print(LogMessage.DEBUG, "Daemon: changeArticle %s %s".printf(articleID, status.to_string()));
			if(status == ArticleStatus.READ || status == ArticleStatus.UNREAD)
			{
				bool increase = true;
				if(status == ArticleStatus.READ)
					increase = false;

				if(m_offline)
				{
					var idArray = articleID.split(",");
					foreach(string id in idArray)
					{
						m_offlineActions.markArticleRead(id, status);
					}
				}
				else
				{

					asyncPayload pl = () => { server.setArticleIsRead(articleID, status); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { dataBase.update_article(articleID, "unread", status); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					updateFeedList();
					updateBadge();
				});
			}
			else if(status == ArticleStatus.MARKED || status == ArticleStatus.UNMARKED)
			{
				if(m_offline)
					m_offlineActions.markArticleStarred(articleID, status);
				else
				{
					asyncPayload pl = () => { server.setArticleIsMarked(articleID, status); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}


				asyncPayload pl = () => { dataBase.update_article(articleID, "marked", status); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
			}
		}


		public string createTag(string caption)
		{
			if(m_offline)
				return ":(";

			string tagID = server.createTag(caption);
			var Tag = new tag(tagID, caption, 0);
			var taglist = new Gee.LinkedList<tag>();
			taglist.add(Tag);
			dataBase.write_tags(taglist);
			newFeedList();

			return tagID;
		}

		public void tagArticle(string articleID, string tagID, bool add)
		{
			if(m_offline)
				return;

			string tags = dataBase.read_article_tags(articleID);

			if(add)
			{
				asyncPayload pl = () => { server.tagArticle(articleID, tagID); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

				if(!tags.contains(tagID))
				{
					tags = tags + tagID + ",";
				}
			}
			else
			{
				logger.print(LogMessage.DEBUG, "daemon: remove tag: " + tagID + " from article: " + articleID);

				asyncPayload pl = () => { server.removeArticleTag(articleID, tagID); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

				logger.print(LogMessage.DEBUG, "daemon: tagstring = " + tags);

				if(tags == tagID)
				{
					tags = "";
				}
				else if(tags.contains(tagID))
				{
					int start = tags.index_of(tagID);
					int end = start + tagID.length + 1;

					string part1 = tags.substring(0, start);
					string part2 = tags.substring(end);

					if(part2.has_prefix(","))
					{
						part2 = part2.substring(1);
						logger.print(LogMessage.ERROR, "daemon: tagArticle");
					}

					tags = part1 + part2;

					if(!dataBase.tag_still_used(tagID))
					{
						logger.print(LogMessage.DEBUG, "daemon: remove tag completely");
						asyncPayload pl2 = () => { server.deleteTag(tagID); };
						callAsync.begin((owned)pl2, (obj, res) => { callAsync.end(res); });

						asyncPayload pl3 = () => { dataBase.dropTag(tagID); };
						callAsync.begin((owned)pl3, (obj, res) => {
							callAsync.end(res);
							newFeedList();
						});
					}
				}
			}

			logger.print(LogMessage.DEBUG, "daemon: set tag string: " + tags);
			dataBase.set_article_tags(articleID, tags);
		}

		public void renameTag(string tagID, string newName)
		{
			if(m_offline)
				return;

			asyncPayload pl = () => { server.renameTag(tagID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.rename_tag(tagID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void deleteTag(string tagID)
		{
			if(m_offline)
				return;

			asyncPayload pl = () => { server.deleteTag(tagID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.dropTag(tagID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void updateTagColor(string tagID, int color)
		{
			dataBase.update_tag_color(tagID, color);
		}

		public void resetDB()
		{
			dataBase.resetDB();
			dataBase.init();
		}

		public void resetAccount()
		{
			server.resetAccount();
		}

		public void markFeedAsRead(string feedID, bool isCat)
		{
			if(isCat)
			{
				if(m_offline)
				{
					m_offlineActions.markCategoryRead(feedID);
				}
				else
				{
					asyncPayload pl = () => { server.setCategorieRead(feedID); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { dataBase.markCategorieRead(feedID); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					updateBadge();
					newFeedList();
					updateArticleList();
				});
			}
			else
			{
				if(m_offline)
				{
					m_offlineActions.markFeedRead(feedID);
				}
				else
				{
					asyncPayload pl = () => { server.setFeedRead(feedID); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { dataBase.markFeedRead(feedID); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					updateBadge();
					newFeedList();
					updateArticleList();
				});
			}
		}

		public void markAllItemsRead()
		{
			if(m_offline)
			{
				m_offlineActions.markAllRead();
			}
			else
			{
				asyncPayload pl = () => { server.markAllItemsRead(); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
			}

			asyncPayload pl = () => { dataBase.markAllRead(); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				updateBadge();
				newFeedList();
				updateArticleList();
			});
		}

		public void removeCategory(string catID)
		{
			asyncPayload pl = () => { server.deleteCategory(catID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.delete_category(catID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void moveCategory(string catID, string newParentID)
		{
			asyncPayload pl = () => { server.moveCategory(catID, newParentID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.move_category(catID, newParentID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public string addCategory(string title, string? parentID = null, bool createLocally = false)
		{
			logger.print(LogMessage.DEBUG, "daemon: addCategory " + title);
			string catID = server.createCategory(title, parentID);

			if(createLocally)
			{
				string? parent = parentID;
				int level = 1;
				if(parentID == null || parentID == "")
				{
					parent = CategoryID.MASTER.to_string();
				}
				else
				{
					var parentCat = dataBase.read_category(parentID);
					level = parentCat.getLevel()+1;
				}

				var cat = new category(catID, title, 0, 99, parent, level);
				var list = new Gee.LinkedList<category>();
				list.add(cat);
				dataBase.write_categories(list);
			}

			return catID;
		}

		public void removeCategoryWithChildren(string catID)
		{
			var feeds = dataBase.read_feeds();
			deleteFeedsofCat(catID, feeds);

			var cats = dataBase.read_categories(feeds);
			foreach(var cat in cats)
			{
				if(cat.getParent() == catID)
				{
					removeCategoryWithChildren(catID);
				}
			}
		}

		private void deleteFeedsofCat(string catID, Gee.ArrayList<feed> feeds)
		{
			foreach(feed Feed in feeds)
			{
				if(Feed.hasCat(catID))
				{
					removeFeed(Feed.getFeedID());
				}
			}
		}

		public void renameCategory(string catID, string newName)
		{
			asyncPayload pl = () => { server.renameCategory(catID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.rename_category(catID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void renameFeed(string feedID, string newName)
		{
			asyncPayload pl = () => { server.renameFeed(feedID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.rename_feed(feedID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void moveFeed(string feedID, string currentCatID, string? newCatID = null)
		{
			asyncPayload pl = () => { server.moveFeed(feedID, newCatID, currentCatID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.move_feed(feedID, currentCatID, newCatID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void addFeed(string feedURL, string cat, bool isID, bool asynchron = true)
		{
			string catID = null;
			string newCatName = null;

			if(isID)
				catID = cat;
			else
				newCatName = cat;

			if(asynchron)
			{
				asyncPayload pl = () => { server.addFeed(feedURL, catID, newCatName); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					feedAdded();
					startSync();
				});
			}
			else
			{
				server.addFeed(feedURL, catID, newCatName);
			}
		}

		public void removeFeed(string feedID)
		{
			asyncPayload pl = () => { server.removeFeed(feedID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.delete_feed(feedID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
				updateArticleList();
			});
		}

		public void removeFeedOnlyFromCat(string feedID, string catID)
		{
			asyncPayload pl = () => { server.removeCatFromFeed(feedID, catID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dataBase.removeCatFromFeed(feedID, catID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void importOPML(string opml)
		{
			asyncPayload pl = () => { server.importOPML(opml); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				opmlImported();
			});
		}

		public void updateBadge()
		{
#if WITH_LIBUNITY
			if(!settings_state.get_boolean("spring-cleaning")
			&& settings_tweaks.get_boolean("show-badge"))
			{
				var count = dataBase.get_unread_total();
				logger.print(LogMessage.DEBUG, "daemon: update badge count %u".printf(count));
				m_launcher.count = count;
				if(count > 0)
					m_launcher.count_visible = true;
				else
					m_launcher.count_visible = false;
			}
#endif
		}

		public void quit()
		{
			logger.print(LogMessage.DEBUG, "Quit!");
			GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 1, () => {
				exit(-1);
				return false;
			});
		}

		private async void callAsync(owned asyncPayload func)
		{
			SourceFunc callback = callAsync.callback;
			new GLib.Thread<void*>(null, () => {
				func();
				Idle.add((owned) callback);
				return null;
			});
			yield;
		}

	}

	[DBus (name = "org.gnome.feedreaderError")]
	public errordomain FeedError
	{
		SOME_ERROR
	}

	void on_bus_aquired(DBusConnection conn)
	{
		daemon = new FeedDaemonServer();
		try
		{
		    conn.register_object("/org/gnome/feedreader", daemon);
		}
		catch (IOError e)
		{
		    logger.print(LogMessage.WARNING, "daemon: Could not register service. Will shut down!");
		    logger.print(LogMessage.WARNING, e.message);
		    exit(-1);
		}
		logger.print(LogMessage.DEBUG, "daemon: bus aquired");
	}


	dbDaemon dataBase;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_tweaks;
	FeedServer server;
	Logger logger;
	FeedDaemonServer daemon;
	Notify.Notification notification;
	bool m_notifyActionSupport = false;

	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "FeedReader version number", null },
		{ "grabArticle", 0, 0, OptionArg.STRING, ref grabArticle, "use the ContentGrabber to grab the given URL", "URL" },
		{ "grabImages", 0, 0, OptionArg.STRING, ref grabImages, "download all images of the html-document", "PATH" },
		{ "url", 0, 0, OptionArg.STRING, ref articleUrl, "url of the article needed to do grabImages", "URL" },
		{ "unreadCount", 0, 0, OptionArg.NONE, ref unreadCount, "current count of unread articles in the database", null },
		{ null }
	};
	private static bool version = false;
	private static bool unreadCount = false;
	private static string? grabArticle = null;
	private static string? grabImages = null;
	private static string? articleUrl = null;


	int main (string[] args)
	{
		settings_general = new GLib.Settings("org.gnome.feedreader");
		settings_state = new GLib.Settings("org.gnome.feedreader.saved-state");
		settings_tweaks = new GLib.Settings("org.gnome.feedreader.tweaks");

		try {
			var opt_context = new GLib.OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		} catch (OptionError e) {
			print(e.message + "\n");
			return 0;
		}

		if(version)
		{
			stdout.printf("Version: %s\n", AboutInfo.version);
			return 0;
		}

		if(unreadCount)
		{
			var old_stdout =(owned)stdout;
			stdout = FileStream.open("/dev/null", "w");
			logger = new Logger("daemon");
			dataBase = new dbDaemon();
			dataBase.init();
			stdout =(owned)old_stdout;
			stdout.printf("%u\n", dataBase.get_unread_total());
			return 0;
		}

		if(grabImages != null && articleUrl != null)
		{
			logger = new Logger("daemon");
			FeedServer.grabImages(grabImages, articleUrl);
			return 0;
		}

		if(grabArticle != null)
		{
			logger = new Logger("daemon");
			FeedServer.grabArticle(grabArticle);
			return 0;
		}

		logger = new Logger("daemon");
		dataBase = new dbDaemon();
		dataBase.init();
		Notify.init(AboutInfo.programmName);
		GLib.List<string> notify_server_caps = Notify.get_server_caps();
		foreach(string str in notify_server_caps)
		{
			if(str == "actions")
			{
				m_notifyActionSupport = true;
				logger.print(LogMessage.INFO, "daemon: Notification actions supported");
				break;
			}
		}
		Utils.copyAutostart();

		logger.print(LogMessage.INFO, "FeedReader Daemon " + AboutInfo.version);

		Bus.own_name (BusType.SESSION, "org.gnome.feedreader", BusNameOwnerFlags.NONE,
				      on_bus_aquired,
				      () => {
				      			settings_state.set_boolean("currently-updating", false);
								settings_state.set_boolean("spring-cleaning", false);
				      },
				      () => {
				      			logger.print(LogMessage.WARNING, "daemon: Could not aquire name (already running). Will shut down!");
				          		exit(-1);
				          	}
				      );
		var mainloop = new GLib.MainLoop();
		mainloop.run();
		return 0;
	}
}
