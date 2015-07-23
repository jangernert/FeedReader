public class FeedReader.WebLoginPage : Gtk.Bin {

	private WebKit.WebView m_view;
	private string m_url;
	private int m_serviceType;
	public signal void success();


	public WebLoginPage() {
		var settings = new WebKit.Settings();
		settings.set_user_agent_with_application_details("FeedReader", AboutInfo.version);
		m_view = new WebKit.WebView();
		m_view.set_settings(settings);
		m_view.context_menu.connect(() => { return true; });
		m_view.load_changed.connect(redirection);
		this.add(m_view);
		this.show_all();
	}


	public void loadPage(OAuth serviceType)
	{
		m_serviceType = serviceType;
		m_url = Utils.buildURL(serviceType);
		logger.print(LogMessage.DEBUG, "WebLoginPage: load URL: " + m_url);
		m_view.load_uri(m_url);
	}

	public void redirection(WebKit.LoadEvent load_event)
	{
		logger.print(LogMessage.DEBUG, "WebLoginPage: webView redirection");
		switch(load_event)
		{
			case WebKit.LoadEvent.STARTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent STARTED");
				checkURL();
				break;
			case WebKit.LoadEvent.REDIRECTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent REDIRECTED");
				checkURL();
				break;
			case WebKit.LoadEvent.COMMITTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent COMMITED");
				break;
			case WebKit.LoadEvent.FINISHED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent FINISHED");
				break;
		}
	}

	void checkURL()
	{
		string url = m_view.get_uri();

		switch(m_serviceType)
		{
			case OAuth.FEEDLY:
				if(getFeedlyApiCode(url))
				{
					m_view.stop_loading();
					success();
				}
				break;
		}
	}

	bool getFeedlyApiCode(string url)
	{
		if(url.has_prefix(FeedlySecret.apiRedirectUri))
		{
			int start = url.index_of("=")+1;
			int end = url.index_of("&");
			string code = url.substring(start, end-start);
			if(!settings_feedly.set_string("feedly-api-code", code))
			{
				logger.print(LogMessage.DEBUG, "WebLoginPage: could not set api code");
			}
			logger.print(LogMessage.DEBUG, "WebLoginPage: set feedly-api-code: " + settings_feedly.get_string("feedly-api-code"));
			GLib.Thread.usleep(500000);
			return true;
		}
		else
			return false;
	}
}
