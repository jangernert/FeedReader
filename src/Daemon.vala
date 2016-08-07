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
		private uint m_timeout_source_id = 0;

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
			login((Backend)settings_general.get_enum("account-type"));

#if WITH_LIBUNITY
			m_launcher = Unity.LauncherEntry.get_for_desktop_id("feedreader.desktop");
			updateBadge();
#endif
			scheduleSync(settings_general.get_int("sync"));
		}

		public void startSync()
		{
			sync.begin((obj, res) => {
				sync.end(res);
			});
		}

		public void startInitSync()
		{
			initSync.begin((obj, res) => {
				initSync.end(res);
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

		public bool supportMultiLevelCategories()
		{
			return server.supportMultiLevelCategories();
		}

		public string? symbolicIcon()
		{
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
				if(!settings_state.get_boolean("currently-updating"))
				{
			   		logger.print(LogMessage.DEBUG, "daemon: Timeout!");
					startSync();
				}
				return true;
			});
		}

		private async void sync()
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
				login((Backend)settings_general.get_enum("account-type"));
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
				yield server.syncContent();
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
				login((Backend)settings_general.get_enum("account-type"));
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


		private async void initSync()
		{
			if(m_loggedin != LoginResponse.SUCCESS)
			{
				login((Backend)settings_general.get_enum("account-type"));
			}

			if(m_loggedin == LoginResponse.SUCCESS && settings_state.get_boolean("currently-updating") == false)
			{
				syncStarted();
				logger.print(LogMessage.INFO, "daemon: initSync started");
				settings_state.set_boolean("currently-updating", true);
				yield server.InitSyncContent();
				updateBadge();
				settings_state.set_boolean("currently-updating", false);
				syncFinished();
				logger.print(LogMessage.INFO, "daemon: initSync finished");
			}
			else
				logger.print(LogMessage.DEBUG, "Cant sync because login failed or sync already ongoing");
		}

		public LoginResponse login(Backend type)
		{
			logger.print(LogMessage.DEBUG, "daemon: new FeedServer and login");
			server = new FeedServer(type);
			this.setOffline.connect(server.setOffline);
			this.setOnline.connect(server.setOnline);

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
				settings_general.set_enum("account-type", type);
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

				server.setArticleIsRead.begin(articleID, status, (obj, res) => {
					server.setArticleIsRead.end(res);
				});

				dataBase.update_article.begin(articleID, "unread", status, (obj, res) => {
					dataBase.update_article.end(res);
					updateFeedList();
					updateBadge();
				});
			}
			else if(status == ArticleStatus.MARKED || status == ArticleStatus.UNMARKED)
			{
				server.setArticleIsMarked(articleID, status);

				dataBase.update_article.begin(articleID, "marked", status, (obj, res) => {
					dataBase.update_article.end(res);
				});
			}
		}


		public string createTag(string caption)
		{
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
			string tags = dataBase.read_article_tags(articleID);

			if(add)
			{
				server.addArticleTag.begin(articleID, tagID, (obj, res) => {
					server.setArticleIsRead.end(res);
				});

				if(!tags.contains(tagID))
				{
					tags = tags + tagID + ",";
				}
			}
			else
			{
				logger.print(LogMessage.DEBUG, "daemon: remove tag: " + tagID + " from article: " + articleID);
				server.removeArticleTag.begin(articleID, tagID, (obj, res) => {
					server.setArticleIsRead.end(res);
				});

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
						server.deleteTag.begin(tagID, (obj, res) => {
							server.deleteTag.end(res);
						});

						dataBase.dropTag.begin(tagID, (obj, res) => {
							dataBase.dropTag.end(res);
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
			server.renameTag.begin(tagID, newName, (obj, res) => {
				server.renameTag.end(res);
			});

			dataBase.rename_tag.begin(tagID, newName, (obj, res) => {
				dataBase.rename_tag.end(res);
				newFeedList();
			});
		}

		public void deleteTag(string tagID)
		{
			server.deleteTag.begin(tagID, (obj, res) => {
				server.deleteTag.end(res);
			});

			dataBase.dropTag.begin(tagID, (obj, res) => {
				dataBase.dropTag.end(res);
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
				server.setCategorieRead.begin(feedID, (obj, res) => {
					server.setCategorieRead.end(res);
				});

				dataBase.markCategorieRead.begin(feedID, (obj, res) => {
					dataBase.markCategorieRead.end(res);
					updateBadge();
					newFeedList();
					updateArticleList();
				});
			}
			else
			{
				server.setFeedRead.begin(feedID, (obj, res) => {
					server.setFeedRead.end(res);
				});

				dataBase.markFeedRead.begin(feedID, (obj, res) => {
					dataBase.markFeedRead.end(res);
					updateBadge();
					newFeedList();
					updateArticleList();
				});
			}
		}

		public void markAllItemsRead()
		{
			server.markAllItemsRead.begin((obj, res) => {
				server.markAllItemsRead.end(res);
			});

			dataBase.markAllRead.begin((obj, res) => {
				dataBase.markAllRead.end(res);
				updateBadge();
				newFeedList();
				updateArticleList();
			});
		}

		public void removeCategory(string catID)
		{
			server.deleteCategory.begin(catID, (obj, res) => {
				server.deleteCategory.end(res);
			});

			dataBase.delete_category.begin(catID, (obj, res) => {
				dataBase.delete_category.end(res);
				newFeedList();
			});
		}

		public void moveCategory(string catID, string newParentID)
		{
			server.moveCategory.begin(catID, newParentID, (obj, res) => {
				server.moveCategory.end(res);
			});

			dataBase.move_category.begin(catID, newParentID, (obj, res) => {
				dataBase.move_category.end(res);
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
					parent = CategoryID.MASTER;
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
			server.renameCategory.begin(catID, newName, (obj, res) => {
				server.renameCategory.end(res);
			});

			dataBase.rename_category.begin(catID, newName, (obj, res) => {
				dataBase.rename_category.end(res);
				newFeedList();
			});
		}

		public void renameFeed(string feedID, string newName)
		{
			server.renameFeed.begin(feedID, newName, (obj, res) => {
				server.renameFeed.end(res);
			});

			dataBase.rename_feed.begin(feedID, newName, (obj, res) => {
				dataBase.rename_feed.end(res);
				newFeedList();
			});
		}

		public void moveFeed(string feedID, string currentCatID, string? newCatID = null)
		{
			server.moveFeed.begin(feedID, newCatID, currentCatID, (obj, res) => {
				server.moveFeed.end(res);
			});

			dataBase.move_feed.begin(feedID, currentCatID, newCatID, (obj, res) => {
				dataBase.move_feed.end(res);
				newFeedList();
			});
		}

		public void addFeed(string feedURL, string cat, bool isID)
		{
			string catID = null;
			string newCatName = null;

			if(isID)
				catID = cat;
			else
				newCatName = cat;

			server.addFeed.begin(feedURL, catID, newCatName, (obj, res) => {
				server.addFeed.end(res);
				feedAdded();
				startSync();
			});
		}

		public void removeFeed(string feedID)
		{
			server.removeFeed.begin(feedID, (obj, res) => {
				server.removeFeed.end(res);
			});

			dataBase.delete_feed.begin(feedID, (obj, res) => {
				dataBase.delete_feed.end(res);
				newFeedList();
			});
		}

		public void removeFeedOnlyFromCat(string feedID, string catID)
		{
			server.removeCatFromFeed.begin(feedID, catID, (obj, res) => {
				server.removeCatFromFeed.end(res);
			});

			dataBase.removeCatFromFeed.begin(feedID, catID, (obj, res) => {
				dataBase.removeCatFromFeed.end(res);
				newFeedList();
			});
		}

		public void importOPML(string opml)
		{
			server.importOPML.begin(opml, (obj, res) => {
				server.importOPML.end(res);
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
	GLib.Settings settings_feedly;
	GLib.Settings settings_ttrss;
	GLib.Settings settings_owncloud;
	GLib.Settings settings_inoreader;
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
		stderr = FileStream.open ("/dev/null", "w");
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_feedly = new GLib.Settings ("org.gnome.feedreader.feedly");
		settings_ttrss = new GLib.Settings ("org.gnome.feedreader.ttrss");
		settings_owncloud = new GLib.Settings ("org.gnome.feedreader.owncloud");
		settings_inoreader = new GLib.Settings ("org.gnome.feedreader.inoreader");
		settings_tweaks = new GLib.Settings ("org.gnome.feedreader.tweaks");

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
			DebugUtils.grabImages(grabImages, articleUrl);
			return 0;
		}

		if(grabArticle != null)
		{
			logger = new Logger("daemon");
			DebugUtils.grabArticle(grabArticle);
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
