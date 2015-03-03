public class FeedReader.FeedServer : GLib.Object {
	private ttrss_interface m_ttrss;
	private FeedlyAPI m_feedly;
	private int m_type;

	public FeedServer(int type)
	{
		m_type = type;
		logger.print(LogMessage.DEBUG, "FeedServer: new with type %i".printf(type));

		switch(m_type)
		{
			case Backend.TTRSS:
				m_ttrss = new ttrss_interface();
				break;

			case Backend.FEEDLY:
				m_feedly = new FeedlyAPI();
				break;
		}
	}

	public int getType()
	{
		return m_type;
	}

	public int login()
	{
		switch(m_type)
		{
			case Backend.NONE:
				return LoginResponse.NO_BACKEND;

			case Backend.TTRSS:
				return m_ttrss.login();

			case Backend.FEEDLY:
				return m_feedly.login();
		}
		return LoginResponse.UNKNOWN_ERROR;
	}

	public async void syncContent()
	{
		SourceFunc callback = syncContent.callback;

		ThreadFunc<void*> run = () => {
			int before = dataBase.getHighestRowID();
			dataBase.markReadAllArticles();

			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.getCategories();
					m_ttrss.getFeeds();
					m_ttrss.getTags();
					m_ttrss.getArticles();
					break;

				case Backend.FEEDLY:
					m_feedly.getCategories();
					m_feedly.getFeeds();
					m_feedly.getTags();
					m_feedly.getArticles();
					break;
			}

			int after = dataBase.getHighestRowID();
			int newArticles = after-before;
			if(newArticles > 0)
			{
				sendNotification(newArticles);
				int newCount = settings_state.get_int("articlelist-new-rows") + newArticles;
				settings_state.set_int("articlelist-new-rows", newCount);
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("syncContent", run);
		yield;

		return;
	}

	public async void setArticleIsRead(string articleID, int read)
	{
		SourceFunc callback = setArticleIsRead.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleUnread(int.parse(articleID), read);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(articleID, "entries", read);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsRead", run);
		yield;
	}

	public async void setArticleIsMarked(string articleID, int marked)
	{
		SourceFunc callback = setArticleIsMarked.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleMarked(int.parse(articleID), marked);
					break;

				case Backend.FEEDLY:

					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsMarked", run);
		yield;
	}


	public static void sendNotification(uint headline_count)
	{
		try{
			string message;

			if(!Notify.is_initted())
			{
				logger.print(LogMessage.ERROR, "notification: libnotifiy not initialized");
				return;
			}

			if(headline_count > 0)
			{
				if(headline_count == 1)
					message = _("There is 1 new article");
				else if(headline_count == 200)
					message = _("There are >200 new articles");
				else
					message = _("There are %u new articles").printf(headline_count);

				notification = new Notify.Notification(_("New Articles"), message, "internet-news-reader");
				notification.set_urgency(Notify.Urgency.NORMAL);

				notification.add_action ("default", "Show FeedReader", (notification, action) => {
					logger.print(LogMessage.DEBUG, "notification: default action");
					try {
						notification.close();
					} catch (Error e) {
						logger.print(LogMessage.ERROR, e.message);
					}

					string[] spawn_args = {"feedreader"};
					try{
						GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
					}catch(GLib.SpawnError e){
						logger.print(LogMessage.ERROR, "spawning command line: %s".printf(e.message));
					}
				});

				notification.closed.connect(() => {
					logger.print(LogMessage.DEBUG, "notification: closed");
				});

				try {
					notification.show();
				} catch (GLib.Error e) {
					logger.print(LogMessage.ERROR, e.message);
				}
			}
		}catch (GLib.Error e) {
			logger.print(LogMessage.ERROR, e.message);
		}
	}


}
