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
	public class FeedDaemonServer : GLib.Object {

#if WITH_LIBUNITY
		private Unity.LauncherEntry m_launcher;
#endif
		private LoginResponse m_loggedin;
		private bool m_offline = true;
		private CachedActionManager m_cachedActions;
		private uint m_timeout_source_id = 0;
		private delegate void asyncPayload();

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

		private static FeedDaemonServer? m_daemon;

		public static FeedDaemonServer get_default()
		{
			if(m_daemon == null)
				m_daemon = new FeedDaemonServer();

			return m_daemon;
		}

		private FeedDaemonServer()
		{
			Logger.debug("daemon: constructor");
			m_cachedActions = new CachedActionManager();
			login(Settings.general().get_string("plugin"));

#if WITH_LIBUNITY
			m_launcher = Unity.LauncherEntry.get_for_desktop_id("feedreader.desktop");
			updateBadge();
#endif
			scheduleSync(Settings.general().get_int("sync"));
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
			return Constants.DBusAPIVersion;
		}


		public bool supportTags()
		{
			return FeedServer.get_default().supportTags();
		}

		public bool supportCategories()
		{
			return FeedServer.get_default().supportCategories();
		}

		public bool supportFeedManipulation()
		{
			return FeedServer.get_default().supportFeedManipulation();
		}

		public bool supportMultiLevelCategories()
		{
			return FeedServer.get_default().supportMultiLevelCategories();
		}

		public string? symbolicIcon()
		{
			Logger.debug("daemon: symbolicIcon");
			return FeedServer.get_default().symbolicIcon();
		}

		public string? accountName()
		{
			return FeedServer.get_default().accountName();
		}

		public string? getServerURL()
		{
			return FeedServer.get_default().getServerURL();
		}

		public string uncategorizedID()
		{
			return FeedServer.get_default().uncategorizedID();
		}

		public bool hideCagetoryWhenEmtpy(string catID)
		{
			return FeedServer.get_default().hideCagetoryWhenEmtpy(catID);
		}

		public bool useMaxArticles()
		{
			return FeedServer.get_default().useMaxArticles();
		}

		public void scheduleSync(int time)
		{
			if (m_timeout_source_id > 0)
			{
				GLib.Source.remove(m_timeout_source_id);
				m_timeout_source_id = 0;
			}

			m_timeout_source_id = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, time*60, () => {
				if(!Settings.state().get_boolean("currently-updating")
				&& FeedServer.get_default().pluginLoaded())
				{
			   		Logger.debug("daemon: Timeout!");
					startSync();
				}
				return true;
			});
		}

		private void sync()
		{
			if(Utils.springCleaningNecessary())
			{
				Logger.info("daemon: spring cleaning");
				Settings.state().set_boolean("spring-cleaning", true);
				springCleanStarted();
				dbDaemon.get_default().springCleaning();
				Settings.state().set_boolean("spring-cleaning", false);
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
				login(Settings.general().get_string("plugin"));
				if(m_loggedin != LoginResponse.SUCCESS)
				{
					setOffline();
					syncFinished();
					return;
				}
			}

			if(m_loggedin == LoginResponse.SUCCESS && Settings.state().get_boolean("currently-updating") == false)
			{
				Logger.info("daemon: sync started");
				Settings.state().set_boolean("currently-updating", true);
				FeedServer.get_default().syncContent();
				updateBadge();
				FeedServer.get_default().grabContent();
				Settings.state().set_boolean("currently-updating", false);
				syncFinished();
				Logger.info("daemon: sync finished");
			}
			else
			{
				Logger.debug("Cant sync because login failed or sync already ongoing");
			}
		}

		public bool checkOnline()
		{
			Logger.debug("Daemon: checkOnline");
			if(!FeedServer.get_default().serverAvailable())
			{
				m_loggedin = LoginResponse.UNKNOWN_ERROR;
				setOffline();
				return false;
			}

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				FeedServer.get_default().logout();
				login(Settings.general().get_string("plugin"));
			}

			setOnline();
			return true;
		}


		public async bool checkOnlineAsync()
		{
			Logger.debug("Daemon: checkOnlineAsync");
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
			if(!FeedServer.get_default().doInitSync())
				return;

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				login(Settings.general().get_string("plugin"));
			}

			if(m_loggedin == LoginResponse.SUCCESS && Settings.state().get_boolean("currently-updating") == false)
			{
				syncStarted();
				Logger.info("daemon: initSync started");
				Settings.state().set_boolean("currently-updating", true);
				FeedServer.get_default().InitSyncContent();
				updateBadge();
				FeedServer.get_default().grabContent();
				Settings.state().set_boolean("currently-updating", false);
				syncFinished();
				Logger.info("daemon: initSync finished");
			}
			else
				Logger.debug("Cant sync because login failed or sync already ongoing");
		}

		public LoginResponse login(string plugName)
		{
			Logger.debug("daemon: new FeedServer and login");

			FeedServer.get_default().unloadPlugin();
			FeedServer.get_default().loadPlugin(plugName);

			if(!FeedServer.get_default().pluginLoaded())
			{
				Logger.error("daemon: plugin '%s' couldn't be loaded by feedserver".printf(plugName));
				m_loggedin = LoginResponse.NO_BACKEND;
				return m_loggedin;
			}

			this.setOffline.connect(() => {
				m_offline = true;
			});
			this.setOnline.connect(() => {
				m_offline = false;
				if(dbDaemon.get_default().isTableEmpty("OfflineActions"))
				{
					m_cachedActions.executeActions();
					dbDaemon.get_default().resetCachedActions();
				}
			});

			FeedServer.get_default().newFeedList.connect(() => {
				newFeedList();
			});

			FeedServer.get_default().updateFeedList.connect(() => {
				updateFeedList();
			});

			FeedServer.get_default().updateArticleList.connect(() => {
				updateArticleList();
			});

			FeedServer.get_default().writeInterfaceState.connect(() => {
				writeInterfaceState();
			});

			FeedServer.get_default().showArticleListOverlay.connect(() => {
				showArticleListOverlay();
			});

			FeedServer.get_default().updateSyncProgress.connect((progress) => {
				updateSyncProgress(progress);
			});

			m_loggedin = FeedServer.get_default().login();

			if(m_loggedin == LoginResponse.SUCCESS)
			{
				Settings.general().set_string("plugin", plugName);
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


			Logger.debug("daemon: login status = " + m_loggedin.to_string());
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
			Logger.debug("Daemon: changeArticle %s %s".printf(articleID, status.to_string()));
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
						m_cachedActions.markArticleRead(id, status);
					}
				}
				else
				{

					asyncPayload pl = () => { FeedServer.get_default().setArticleIsRead(articleID, status); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { dbDaemon.get_default().update_article(articleID, "unread", status); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					updateFeedList();
					updateBadge();
				});
			}
			else if(status == ArticleStatus.MARKED || status == ArticleStatus.UNMARKED)
			{
				if(m_offline)
					m_cachedActions.markArticleStarred(articleID, status);
				else
				{
					asyncPayload pl = () => { FeedServer.get_default().setArticleIsMarked(articleID, status); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}


				asyncPayload pl = () => { dbDaemon.get_default().update_article(articleID, "marked", status); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					updateFeedList();
				});
			}
		}


		public string createTag(string caption)
		{
			if(m_offline)
				return ":(";

			string tagID = FeedServer.get_default().createTag(caption);
			var Tag = new tag(tagID, caption, 0);
			var taglist = new Gee.LinkedList<tag>();
			taglist.add(Tag);
			dbDaemon.get_default().write_tags(taglist);
			newFeedList();

			return tagID;
		}

		public void tagArticle(string articleID, string tagID, bool add)
		{
			if(m_offline)
				return;

			string tags = dbDaemon.get_default().read_article_tags(articleID);

			if(add)
			{
				asyncPayload pl = () => { FeedServer.get_default().tagArticle(articleID, tagID); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

				if(!tags.contains(tagID))
				{
					tags = tags + tagID + ",";
				}
			}
			else
			{
				Logger.debug("daemon: remove tag: " + tagID + " from article: " + articleID);

				asyncPayload pl = () => { FeedServer.get_default().removeArticleTag(articleID, tagID); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

				Logger.debug("daemon: tagstring = " + tags);

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
						Logger.error("daemon: tagArticle");
					}

					tags = part1 + part2;

					if(!dbDaemon.get_default().tag_still_used(tagID))
					{
						Logger.debug("daemon: remove tag completely");
						asyncPayload pl2 = () => { FeedServer.get_default().deleteTag(tagID); };
						callAsync.begin((owned)pl2, (obj, res) => { callAsync.end(res); });

						asyncPayload pl3 = () => { dbDaemon.get_default().dropTag(tagID); };
						callAsync.begin((owned)pl3, (obj, res) => {
							callAsync.end(res);
							newFeedList();
						});
					}
				}
			}

			Logger.debug("daemon: set tag string: " + tags);
			dbDaemon.get_default().set_article_tags(articleID, tags);
		}

		public void renameTag(string tagID, string newName)
		{
			if(m_offline)
				return;

			asyncPayload pl = () => { FeedServer.get_default().renameTag(tagID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().rename_tag(tagID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void deleteTag(string tagID)
		{
			if(m_offline)
				return;

			asyncPayload pl = () => { FeedServer.get_default().deleteTag(tagID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().dropTag(tagID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void updateTagColor(string tagID, int color)
		{
			dbDaemon.get_default().update_tag_color(tagID, color);
		}

		public void resetDB()
		{
			dbDaemon.get_default().resetDB();
			dbDaemon.get_default().init();
		}

		public void resetAccount()
		{
			FeedServer.get_default().resetAccount();
		}

		public void markFeedAsRead(string feedID, bool isCat)
		{
			if(isCat)
			{
				if(m_offline)
				{
					m_cachedActions.markCategoryRead(feedID);
				}
				else
				{
					asyncPayload pl = () => { FeedServer.get_default().setCategorieRead(feedID); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { dbDaemon.get_default().markCategorieRead(feedID); };
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
					m_cachedActions.markFeedRead(feedID);
				}
				else
				{
					asyncPayload pl = () => { FeedServer.get_default().setFeedRead(feedID); };
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { dbDaemon.get_default().markFeedRead(feedID); };
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
				m_cachedActions.markAllRead();
			}
			else
			{
				asyncPayload pl = () => { FeedServer.get_default().markAllItemsRead(); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
			}

			asyncPayload pl = () => { dbDaemon.get_default().markAllRead(); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				updateBadge();
				newFeedList();
				updateArticleList();
			});
		}

		public void removeCategory(string catID)
		{
			asyncPayload pl = () => { FeedServer.get_default().deleteCategory(catID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().delete_category(catID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void moveCategory(string catID, string newParentID)
		{
			asyncPayload pl = () => { FeedServer.get_default().moveCategory(catID, newParentID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().move_category(catID, newParentID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public string addCategory(string title, string? parentID = null, bool createLocally = false)
		{
			Logger.debug("daemon: addCategory " + title);
			string catID = FeedServer.get_default().createCategory(title, parentID);

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
					var parentCat = dbDaemon.get_default().read_category(parentID);
					level = parentCat.getLevel()+1;
				}

				var cat = new category(catID, title, 0, 99, parent, level);
				var list = new Gee.LinkedList<category>();
				list.add(cat);
				dbDaemon.get_default().write_categories(list);
			}

			return catID;
		}

		public void removeCategoryWithChildren(string catID)
		{
			var feeds = dbDaemon.get_default().read_feeds();
			deleteFeedsofCat(catID, feeds);

			var cats = dbDaemon.get_default().read_categories(feeds);
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
			asyncPayload pl = () => { FeedServer.get_default().renameCategory(catID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().rename_category(catID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void renameFeed(string feedID, string newName)
		{
			asyncPayload pl = () => { FeedServer.get_default().renameFeed(feedID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().rename_feed(feedID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void moveFeed(string feedID, string currentCatID, string? newCatID = null)
		{
			asyncPayload pl = () => { FeedServer.get_default().moveFeed(feedID, newCatID, currentCatID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().move_feed(feedID, currentCatID, newCatID); };
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
				asyncPayload pl = () => { FeedServer.get_default().addFeed(feedURL, catID, newCatName); };
				callAsync.begin((owned)pl, (obj, res) => {
					callAsync.end(res);
					feedAdded();
					startSync();
				});
			}
			else
			{
				FeedServer.get_default().addFeed(feedURL, catID, newCatName);
			}
		}

		public void removeFeed(string feedID)
		{
			asyncPayload pl = () => { FeedServer.get_default().removeFeed(feedID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().delete_feed(feedID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
				updateArticleList();
			});
		}

		public void removeFeedOnlyFromCat(string feedID, string catID)
		{
			asyncPayload pl = () => { FeedServer.get_default().removeCatFromFeed(feedID, catID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { dbDaemon.get_default().removeCatFromFeed(feedID, catID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void importOPML(string opml)
		{
			asyncPayload pl = () => { FeedServer.get_default().importOPML(opml); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				opmlImported();
			});
		}

		public void updateBadge()
		{
#if WITH_LIBUNITY
			if(!Settings.state().get_boolean("spring-cleaning")
			&& Settings.tweaks().get_boolean("show-badge"))
			{
				var count = dbDaemon.get_default().get_unread_total();
				Logger.debug("daemon: update badge count %u".printf(count));
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
			Logger.debug("Quit!");
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
		try
		{
		    conn.register_object("/org/gnome/feedreader", FeedDaemonServer.get_default());
		}
		catch (IOError e)
		{
		    Logger.warning("daemon: Could not register service. Will shut down!");
		    Logger.warning(e.message);
		    exit(-1);
		}
		Logger.debug("daemon: bus aquired");
	}

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


	int main(string[] args)
	{
		try
		{
			var opt_context = new GLib.OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		}
		catch(OptionError e)
		{
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
			Logger.init("daemon");
			stdout =(owned)old_stdout;
			stdout.printf("%u\n", dbDaemon.get_default().get_unread_total());
			return 0;
		}

		if(grabImages != null && articleUrl != null)
		{
			Logger.init("daemon");
			FeedServer.grabImages(grabImages, articleUrl);
			return 0;
		}

		if(grabArticle != null)
		{
			Logger.init("daemon");
			FeedServer.grabArticle(grabArticle);
			return 0;
		}

		Logger.init("daemon");
		Notification.init();
		Utils.copyAutostart();

		Logger.info("FeedReader Daemon " + AboutInfo.version);

		if(dbDaemon.get_default().uninitialized())
			dbDaemon.get_default().init();

		Bus.own_name (BusType.SESSION, "org.gnome.feedreader", BusNameOwnerFlags.NONE,
				      on_bus_aquired,
				      () => {
				      			Settings.state().set_boolean("currently-updating", false);
								Settings.state().set_boolean("spring-cleaning", false);
				      },
				      () => {
				      			Logger.warning("daemon: Could not aquire name (already running). Will shut down!");
				          		exit(-1);
				          	}
				      );
		var mainloop = new GLib.MainLoop();
		mainloop.run();
		return 0;
	}
}
