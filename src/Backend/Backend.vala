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

	public class FeedReaderBackend : GLib.Object {

		#if LIBUNITY
		private Unity.LauncherEntry m_launcher;
		#endif
		private LoginResponse m_loggedin;
		private GLib.Cancellable m_cancellable;
		private bool m_offline = true;
		private bool m_cacheSync = false;
		private uint m_timeout_source_id = 0;
		private Mutex m_sync_lock;
		private delegate void asyncPayload();

		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void newFeedList();
		public signal void refreshFeedListCounter();
		public signal void updateArticleList();
		public signal void showArticleListOverlay();
		public signal void setOffline();
		public signal void setOnline();
		public signal void feedAdded(bool error, string errmsg);
		public signal void opmlImported();
		public signal void updateSyncProgress(string progress);
		public signal void tryLogin();

		private static FeedReaderBackend? m_backend;

		public static FeedReaderBackend get_default()
		{
			if(m_backend == null)
			{
				m_backend = new FeedReaderBackend();
			}

			return m_backend;
		}

		private FeedReaderBackend()
		{
			Logger.debug("backend: constructor");
			var plugID = Settings.general().get_string("plugin");

			if(plugID == "none")
			{
				m_loggedin = LoginResponse.NO_BACKEND;
			}
			else
			{
				login(plugID);
			}

			#if LIBUNITY
			m_launcher = Unity.LauncherEntry.get_for_desktop_id("org.gnome.FeedReader.desktop");
			updateBadge();
			#endif
			m_cancellable = new GLib.Cancellable();
			scheduleSync(Settings.general().get_int("sync"));

			GLib.NetworkMonitor.get_default().network_changed.connect((available) => {
				if(available)
				{
					checkOnline();
				}
				else
				{
					setOffline();
				}
			});

			this.setOffline.connect(() => {
				m_offline = true;
			});
			this.setOnline.connect(() => {
				m_offline = false;
				CachedActionManager.get_default().executeActions();
			});
		}

		public void startSync(bool initSync = false)
		{
			m_cancellable.reset();
			asyncPayload pl = () => { sync(initSync, m_cancellable); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
			});
		}

		public void cancelSync()
		{
			Logger.warning("backend: Cancel current sync");
			m_cancellable.cancel();
		}

		public string getVersion()
		{
			return AboutInfo.version;
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

		public string symbolicIcon()
		{
			Logger.debug("backend: symbolicIcon");
			return FeedServer.get_default().symbolicIcon();
		}

		public string accountName()
		{
			return FeedServer.get_default().accountName();
		}

		public string getServerURL()
		{
			return FeedServer.get_default().getServerURL();
		}

		public string uncategorizedID()
		{
			return FeedServer.get_default().uncategorizedID();
		}

		public bool hideCategoryWhenEmpty(string catID)
		{
			return FeedServer.get_default().hideCategoryWhenEmpty(catID);
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

			if(time == 0)
			{
				return;
			}

			m_timeout_source_id = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, time*60, () => {
				if(!Settings.state().get_boolean("currently-updating")
				&& FeedServer.get_default().pluginLoaded())
				{
					Logger.debug("backend: Timeout!");
					startSync(false);
				}
				return true;
			});
		}

		private void sync(bool initSync = false, GLib.Cancellable? cancellable = null)
		{
			// Prevent multiple concurrent syncs or spring cleanings
			// We would prefer to use MutexLocker but it doesn't seem to work
			m_sync_lock.lock();
			try
			{
				if(Settings.state().get_boolean("currently-updating"))
				{
					Logger.debug("Cant sync because login failed or sync/clean already ongoing");
					return;
				}

				if(Utils.springCleaningNecessary())
				{
					Logger.info("backend: spring cleaning");
					springCleanStarted();
					DataBase.writeAccess().springCleaning();
					springCleanFinished();
				}

				if(cancellable != null && cancellable.is_cancelled())
				{
					return;
				}

				Logger.info("backend: sync started");
				syncStarted();
				Settings.state().set_boolean("currently-updating", true);

				if(!checkOnline())
				{
					Logger.info("Cancelling sync because we're not online");
					finishSync();
					return;
				}

				if(cancellable != null && cancellable.is_cancelled())
				{
					finishSync();
					return;
				}

				m_cacheSync = true;

				if(initSync && FeedServer.get_default().doInitSync())
				{
					FeedServer.get_default().InitSyncContent(cancellable);
				}
				else
				{
					FeedServer.get_default().syncContent(cancellable);
				}

				if(cancellable != null && cancellable.is_cancelled())
				{
					finishSync();
					return;
				}

				updateBadge();
				m_cacheSync = false;
				FeedServer.get_default().grabContent.begin(cancellable, (obj, res) => {
					FeedServer.get_default().grabContent.end(res);
					finishSync();
				});
			}
			finally
			{
				m_sync_lock.unlock();
			}
		}

		private void finishSync()
		{
			Settings.state().set_boolean("currently-updating", false);
			Settings.state().set_string("sync-status", "");
			Logger.info("backend: sync finished/cancelled");
			syncFinished();
		}

		public bool checkOnline()
		{
			Logger.debug("backend: checkOnline");

			if(GLib.NetworkMonitor.get_default().get_connectivity() != GLib.NetworkConnectivity.FULL)
			{
				Logger.error("backend: no network available");
			}

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
				if(m_loggedin != LoginResponse.SUCCESS)
				{
					setOffline();
					return false;
				}
			}

			setOnline();
			return true;
		}


		public async bool checkOnlineAsync()
		{
			if(!FeedServer.get_default().pluginLoaded())
			{
				return false;
			}

			Logger.debug("backend: checkOnlineAsync");
			bool online = false;
			SourceFunc callback = checkOnlineAsync.callback;
			ThreadFunc<void*> run = () => {
				Idle.add((owned) callback);
				online = checkOnline();
				return null;
			};

			new Thread<void*>("checkOnlineAsync", run);
			yield;
			return online;
		}

		public LoginResponse login(string plugName)
		{
			Logger.debug("backend: new FeedServer and login");

			FeedServer.get_default().setActivePlugin(plugName);

			if(!FeedServer.get_default().pluginLoaded())
			{
				Logger.error(@"backend: no active plugin");
				m_loggedin = LoginResponse.NO_BACKEND;
				return m_loggedin;
			}

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


			Logger.debug("backend: login status = " + m_loggedin.to_string());
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

		public void updateArticleRead(Article article)
		{
			if(m_offline)
			{
				CachedActionManager.get_default().markArticleRead(article.getArticleID(), article.getUnread());
			}
			else
			{
				if(m_cacheSync)
				{
					ActionCache.get_default().markArticleRead(article.getArticleID(), article.getUnread());
				}

				asyncPayload pl = () => { FeedServer.get_default().setArticleIsRead(article.getArticleID(), article.getUnread()); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
			}

			asyncPayload pl = () => { DataBase.writeAccess().update_article(article); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				refreshFeedListCounter();
				updateBadge();
			});
		}

		public void updateArticleMarked(Article article)
		{
			if(m_offline)
			{
				CachedActionManager.get_default().markArticleStarred(article.getArticleID(), article.getMarked());
			}
			else
			{
				if(m_cacheSync)
				{
					ActionCache.get_default().markArticleStarred(article.getArticleID(), article.getMarked());
				}
				asyncPayload pl = () => { FeedServer.get_default().setArticleIsMarked(article.getArticleID(), article.getMarked()); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
			}


			asyncPayload pl = () => { DataBase.writeAccess().update_article(article); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				refreshFeedListCounter();
			});
		}


		public Tag? createTag(string caption)
		{
			if(m_offline)
			{
				return null;
			}

			string tagID = FeedServer.get_default().createTag(caption);
			var tag = new Tag(tagID, caption, 0);
			DataBase.writeAccess().write_tag(tag);
			newFeedList();

			return tag;
		}

		public void tagArticle(Article article, Tag tag, bool add)
		{
			if(m_offline)
			{
				return;
			}

			if(add)
			{
				asyncPayload pl = () => { FeedServer.get_default().tagArticle(article, tag); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

				article.addTag(tag.getTagID());

			}
			else
			{
				Logger.debug("backend: remove tag: " + tag.getTagID() + " from article: " + article.getArticleID());

				asyncPayload pl = () => { FeedServer.get_default().removeArticleTag(article, tag); };
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

				article.removeTag(tag.getTagID());
			}

			var db = DataBase.writeAccess();
			db.update_article(article);

			if(!add && !db.tag_still_used(tag))
			{
				Logger.debug("backend: remove tag completely");
				asyncPayload pl2 = () => { FeedServer.get_default().deleteTag(tag.getTagID()); };
				callAsync.begin((owned)pl2, (obj, res) => { callAsync.end(res); });

				asyncPayload pl3 = () => { db.dropTag(tag); };
				callAsync.begin((owned)pl3, (obj, res) => {
					callAsync.end(res);
					newFeedList();
				});
			}
		}

		public Tag renameTag(Tag tag, string newName)
		{
			if(m_offline)
			{
				return tag;
			}

			tag.setTitle(newName);

			asyncPayload pl = () => { FeedServer.get_default().renameTag(tag.getTagID(), newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { DataBase.writeAccess().update_tag(tag); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});

			return tag;
		}

		public void deleteTag(Tag tag)
		{
			if(m_offline)
			{
				return;
			}

			asyncPayload pl = () => { FeedServer.get_default().deleteTag(tag.getTagID()); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { DataBase.writeAccess().dropTag(tag); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void updateTagColor(Tag tag)
		{
			DataBase.writeAccess().update_tag(tag);
		}

		public void resetDB()
		{
			var db = DataBase.writeAccess();
			db.resetDB();
			db.init();
		}

		public void resetAccount()
		{
			FeedServer.get_default().resetAccount();
		}

		public void markFeedAsRead(string feedID, bool isCat)
		{
			var useID = FeedServer.get_default().alwaysSetReadByID();
			var articleIDs = "";
			if(useID)
			{
				var listType = isCat ? FeedListType.CATEGORY : FeedListType.FEED;
				var articles = DataBase.readOnly().read_articles(feedID, listType, ArticleListState.UNREAD, "", -1);
				var articleIDsList = new Gee.ArrayList<string>();
				foreach (var article in articles)
				{
					articleIDsList.add(article.getArticleID());
				}
				articleIDs = StringUtils.join(articleIDsList, ",");
			}

			if(isCat)
			{
				if(m_offline)
				{
					if(useID)
					{
						CachedActionManager.get_default().markArticleRead(articleIDs, ArticleStatus.READ);
					}
					else
					{
						CachedActionManager.get_default().markCategoryRead(feedID);
					}
				}
				else
				{
					if(m_cacheSync)
					{
						if(useID)
						{
							ActionCache.get_default().markArticleRead(articleIDs, ArticleStatus.READ);
						}
						else
						{
							ActionCache.get_default().markCategoryRead(feedID);
						}
					}
					asyncPayload pl = () => {
						if(useID)
						{
							FeedServer.get_default().setArticleIsRead(articleIDs, ArticleStatus.READ);
						}
						else
						{
							FeedServer.get_default().setCategoryRead(feedID);
						}
					};
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { DataBase.writeAccess().markCategorieRead(feedID); };
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
					if(useID)
					{
						CachedActionManager.get_default().markArticleRead(articleIDs, ArticleStatus.READ);
					}
					else
					{
						CachedActionManager.get_default().markFeedRead(feedID);
					}
				}
				else
				{
					if(m_cacheSync)
					{
						if(useID)
						{
							ActionCache.get_default().markArticleRead(articleIDs, ArticleStatus.READ);
						}
						else
						{
							ActionCache.get_default().markFeedRead(feedID);
						}
					}
					asyncPayload pl = () => {
						if(useID)
						{
							FeedServer.get_default().setArticleIsRead(articleIDs, ArticleStatus.READ);
						}
						else
						{
							FeedServer.get_default().setFeedRead(feedID);
						}
					};
					callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
				}

				asyncPayload pl = () => { DataBase.writeAccess().markFeedRead(feedID); };
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
			var useID = FeedServer.get_default().alwaysSetReadByID();
			var articleIDs = "";
			if(useID)
			{
				var articles = DataBase.readOnly().read_articles(FeedID.ALL.to_string(), FeedListType.FEED, ArticleListState.UNREAD, "", -1);
				var articleIDsList = new Gee.ArrayList<string>();
				foreach (var article in articles)
				{
					articleIDsList.add(article.getArticleID());
				}
				articleIDs = StringUtils.join(articleIDsList, ",");
			}

			if(m_offline)
			{
				if(useID)
				{
					CachedActionManager.get_default().markArticleRead(articleIDs, ArticleStatus.READ);
				}
				else
				{
					CachedActionManager.get_default().markAllRead();
				}
			}
			else
			{
				if(m_cacheSync)
				{
					if(useID)
					{
						ActionCache.get_default().markArticleRead(articleIDs, ArticleStatus.READ);
					}
					else
					{
						ActionCache.get_default().markAllRead();
					}
				}
				asyncPayload pl = () => {
					if(useID)
					{
						FeedServer.get_default().setArticleIsRead(articleIDs, ArticleStatus.READ);
					}
					else
					{
						FeedServer.get_default().markAllItemsRead();
					}
				};
				callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });
			}

			asyncPayload pl = () => { DataBase.writeAccess().markAllRead(); };
			callAsync.begin((owned)pl, (obj, res) => {
				callAsync.end(res);
				updateBadge();
				newFeedList();
				updateArticleList();
			});
		}

		public void removeCategory(string catID)
		{
			var db = DataBase.writeAccess();
			var feeds = db.read_feeds();
			foreach(Feed feed in feeds)
			{
				if(feed.hasCat(catID))
				{
					moveFeed(feed.getFeedID(), catID);
				}
			}

			var cats = db.read_categories(feeds);
			foreach(var cat in cats)
			{
				if(cat.getParent() == catID)
				{
					moveCategory(cat.getCatID(), uncategorizedID());
				}
			}

			asyncPayload pl = () => { FeedServer.get_default().deleteCategory(catID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { db.delete_category(catID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void moveCategory(string catID, string newParentID)
		{
			asyncPayload pl = () => { FeedServer.get_default().moveCategory(catID, newParentID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { DataBase.writeAccess().move_category(catID, newParentID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public string addCategory(string title, string? parentID = null, bool createLocally = false)
		{
			Logger.debug("backend: addCategory " + title);
			string catID = FeedServer.get_default().createCategory(title, parentID);

			if(createLocally)
			{
				string? parent = parentID;
				int level = 1;
				var db = DataBase.writeAccess();
				if(parentID == null || parentID == "")
				{
					parent = CategoryID.MASTER.to_string();
				}
				else
				{
					var parentCat = db.read_category(parentID);
					level = parentCat.getLevel()+1;
				}

				var cat = new Category(catID, title, 0, 99, parent, level);
				var list = new Gee.LinkedList<Category>();
				list.add(cat);
				db.write_categories(list);
			}

			return catID;
		}

		public void removeCategoryWithChildren(string catID)
		{
			var db = DataBase.readOnly();
			var feeds = db.read_feeds();
			deleteFeedsInCategory(catID, feeds);

			var cats = db.read_categories(feeds);
			foreach(var cat in cats)
			{
				if(cat.getParent() == catID)
				{
					removeCategoryWithChildren(catID);
				}
			}

			removeCategory(catID);
		}

		private void deleteFeedsInCategory(string catID, Gee.List<Feed> feeds)
		{
			foreach(Feed feed in feeds)
			{
				if(feed.hasCat(catID))
				{
					removeFeed(feed.getFeedID());
				}
			}
		}

		public void renameCategory(string catID, string newName)
		{
			asyncPayload pl = () => { FeedServer.get_default().renameCategory(catID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { DataBase.writeAccess().rename_category(catID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void renameFeed(string feedID, string newName)
		{
			asyncPayload pl = () => { FeedServer.get_default().renameFeed(feedID, newName); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { DataBase.writeAccess().rename_feed(feedID, newName); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void moveFeed(string feedID, string currentCatID, string? newCatID = null)
		{
			asyncPayload pl = () => { FeedServer.get_default().moveFeed(feedID, newCatID, currentCatID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => { DataBase.writeAccess().move_feed(feedID, currentCatID, newCatID); };
			callAsync.begin((owned)pl2, (obj, res) => {
				callAsync.end(res);
				newFeedList();
			});
		}

		public void addFeed(string feedURL, string cat, bool isID)
		{
			string? catID = null;
			string? newCatName = null;
			string? feedID = null;

			if(cat != "")
			{
				if(isID)
				{
					catID = cat;
				}
				else
				{
					newCatName = cat;
				}
			}

			string errmsg;
			bool success = FeedServer.get_default().addFeed(feedURL, catID, newCatName, out feedID, out errmsg);
			errmsg = success ? "" : errmsg;
			feedAdded(!success, errmsg);
			if(success)
			{
				startSync();
			}
		}

		public void removeFeed(string feedID)
		{
			asyncPayload pl = () => { FeedServer.get_default().removeFeed(feedID); };
			callAsync.begin((owned)pl, (obj, res) => { callAsync.end(res); });

			asyncPayload pl2 = () => {
				FeedReader.FavIcon.delete_feed(feedID);
				DataBase.writeAccess().delete_feed(feedID);
			};
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

			asyncPayload pl2 = () => { DataBase.writeAccess().removeCatFromFeed(feedID, catID); };
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
			#if LIBUNITY
			if(Settings.tweaks().get_boolean("show-badge"))
			{
				var count = DataBase.readOnly().get_unread_total();
				Logger.debug("backend: update badge count %u".printf(count));
				m_launcher.count = count;
				if(count > 0)
				{
					m_launcher.count_visible = true;
				}
				else
				{
					m_launcher.count_visible = false;
				}
			}
			#endif
		}

		private async void callAsync(owned asyncPayload func)
		{
			SourceFunc callback = callAsync.callback;
			new Thread<void*>(null, () => {
				func();
				Idle.add((owned) callback);
				return null;
			});
			yield;
		}

	}
}
