public class FeedReader.WebLoginPage : Gtk.Bin {

	private WebKit.WebView m_view;
	private string m_url;
	private int m_serviceType;
	public signal void success();


	public WebLoginPage() {



		m_view = new WebKit.WebView();
		m_view.context_menu.connect(() => { return true; });
		m_view.load_changed.connect(redirection);
		this.add(m_view);
		this.show_all();
	}


	public void loadPage(int serviceType)
	{
		m_serviceType = serviceType;
		switch(serviceType)
		{
			case Backend.FEEDLY:
				m_url = buildFeedlyURL();
				break;
		}

		logger.print(LogMessage.DEBUG, "WebLoginPage: load URL: " + m_url);
		m_view.load_uri(m_url);
	}

	private string buildFeedlyURL()
	{
		string url = FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId;
		url = url + "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";
		return url;
	}

	public void redirection(WebKit.LoadEvent load_event)
	{
		logger.print(LogMessage.DEBUG, "WebLoginPage: webView redirection");
		switch(load_event)
		{
			case WebKit.LoadEvent.STARTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent STARTED");
				switch(m_serviceType)
				{
					case Backend.FEEDLY:
						string url = m_view.get_uri();
						logger.print(LogMessage.DEBUG, "WebLoginPage: redirection url: " + url);
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
							m_view.stop_loading();
							GLib.Thread.usleep(500000);
							success();
						}
						break;
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent COMMITED");
				break;
			case WebKit.LoadEvent.FINISHED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent FINISHED");
				break;
		}
	}


}
