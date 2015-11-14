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


		public bool supportTags()
		{
			return server.supportTags();
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


		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void updateFeedlistUnreadCount(string feedID, bool increase);
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void updateArticleList();

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

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				m_loggedin = login((Backend)settings_general.get_enum("account-type"));
				if(m_loggedin != LoginResponse.SUCCESS)
				{
					exit(-1);
				}
			}

			if(m_loggedin == LoginResponse.SUCCESS && settings_state.get_boolean("currently-updating") == false)
			{
				syncStarted();
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


		private async void initSync()
		{
			if(m_loggedin != LoginResponse.SUCCESS)
			{
				m_loggedin = login((Backend)settings_general.get_enum("account-type"));
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

			server.newFeedList.connect(() => {
				newFeedList();
			});

			server.updateFeedList.connect(() => {
				updateFeedList();
			});

			server.newArticleList.connect(() => {
				updateArticleList();
			});

			m_loggedin = server.login();

			if(m_loggedin == LoginResponse.SUCCESS)
			{
				settings_general.set_enum("account-type", type);
			}
			else
			{
				//FIXME: offline mode
			}


			logger.print(LogMessage.DEBUG, "daemon: login status = %i".printf(m_loggedin));
			return m_loggedin;
		}

		public int isLoggedIn()
		{
			return m_loggedin;
		}

		public void changeArticle(string articleID, ArticleStatus status)
		{
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
					updateFeedlistUnreadCount(dataBase.getFeedIDofArticle(articleID), increase);
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

						dataBase.dropTag(tagID);
						newFeedList();
					}
				}
			}

			logger.print(LogMessage.DEBUG, "daemon: set tag string: " + tags);
			dataBase.set_article_tags(articleID, tags);
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
	}

	[DBus (name = "org.gnome.feedreaderError")]
	public errordomain FeedError
	{
		SOME_ERROR
	}

	void on_bus_aquired (DBusConnection conn) {
		try {
		    conn.register_object ("/org/gnome/feedreader", new FeedDaemonServer());
		} catch (IOError e) {
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
	GLib.Settings settings_tweaks;
	FeedServer server;
	Logger logger;
	Notify.Notification notification;
	bool m_notifyActionSupport = false;

	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "FeedReader version number", null },
		{ "grabArticle", 0, 0, OptionArg.STRING, ref grabArticle, "use the ContentGrabber to grab the given URL", "URL" },
		{ null }
	};
	private static bool version = false;
	private static string? grabArticle = null;


	int main (string[] args)
	{
		stderr = FileStream.open ("/dev/null", "w");
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_feedly = new GLib.Settings ("org.gnome.feedreader.feedly");
		settings_ttrss = new GLib.Settings ("org.gnome.feedreader.ttrss");
		settings_owncloud = new GLib.Settings ("org.gnome.feedreader.owncloud");
		settings_tweaks = new GLib.Settings ("org.gnome.feedreader.tweaks");
		logger = new Logger("daemon");

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

		if(grabArticle != null)
		{
			DEBUGgrabArticle(grabArticle);
			return 0;
		}

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

	public static void DEBUGgrabArticle(string url)
	{
		var grabber = new Grabber(url, null, null);
		if(grabber.process())
		{
			grabber.print();

			string html = grabber.getArticle();
			string xml = "<?xml";

			while(html.has_prefix(xml))
			{
				int end = html.index_of_char('>');
				html = html.slice(end+1, html.length).chug();
			}

			string path = GLib.Environment.get_home_dir() + "/grabbedArticle.html";

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			var file = GLib.File.new_for_path(path);
			var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

			stream.write(html.data);
			logger.print(LogMessage.DEBUG, "Grabber: article html written to " + path);

			string output = "";
			string[] spawn_args = {"html2text", "-utf8", "-nobs", "-style", "pretty", "-rcfile", "/usr/share/FeedReader/html2textrc", path};
			try{
				GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
			}
			catch(GLib.SpawnError e){
				logger.print(LogMessage.ERROR, "html2text: %s".printf(e.message));
			}

			output = output.strip();

			if(output == "" || output == null || output.has_prefix("Input recoding failed"))
			{
				logger.print(LogMessage.DEBUG, "use vilistextum as fallback for html2text");

				string[] spawn_args_fallback = {"vilistextum", "-a", "-n", "-r", "-t", "-u", path, "-"};
				try{
					GLib.Process.spawn_sync(null, spawn_args_fallback, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
				}
				catch(GLib.SpawnError e){
					logger.print(LogMessage.ERROR, "vilistextum: %s".printf(e.message));
				}
			}

			if(output == "" || output == null)
			{
				logger.print(LogMessage.ERROR, "could not generate preview text");
				return;
			}

			output = output.replace("\n"," ");
			output = output.replace("_"," ");

			path = GLib.Environment.get_home_dir() + "/grabbedArticlePreview.txt";

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			file = GLib.File.new_for_path(path);
			stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

			stream.write(output.data);
			logger.print(LogMessage.DEBUG, "Grabber: preview written to " + path);
		}
		else
		{
			logger.print(LogMessage.ERROR, "Grabber: article could not be processed " + url);
		}
	}

}
