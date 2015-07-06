public class FeedReader.WebLoginPage : Gtk.Bin {

	private WebKit.WebView m_view;
	private string m_url;
	private int m_serviceType;
	public signal void success_backend();
	public signal void success_share();


	public WebLoginPage() {
		m_view = new WebKit.WebView();
		m_view.context_menu.connect(() => { return true; });
		m_view.load_changed.connect(redirection);
		this.add(m_view);
		this.show_all();
	}


	public void loadPage(OAuth serviceType)
	{
		m_serviceType = serviceType;
		switch(serviceType)
		{
			case OAuth.FEEDLY:
				m_url = buildFeedlyURL();
				break;
			case OAuth.READABILITY:
				m_url = buildReadabilityURL();
				break;
		}

		logger.print(LogMessage.DEBUG, "WebLoginPage: load URL: " + m_url);
		m_view.load_uri(m_url);
	}

	private string buildFeedlyURL()
	{
		string url = FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId;
		url += "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";
		return url;
	}

	private string buildReadabilityURL()
	{
		var now = new DateTime.now_local();
		string url = ReadabilitySecrets.authorize_uri + "?oauth_consumer_key=" + ReadabilitySecrets.oauth_consumer_key + "&oauth_timestamp=" + now.to_unix().to_string();
		url += "&oauth_nonce=" + Utils.string_random(42) + "&oauth_consumer_secret=" + ReadabilitySecrets.oauth_consumer_secret;
		url += "&oauth_callback=" + ReadabilitySecrets.oauth_callback + "&oauth_signature=" + ReadabilitySecrets.oauth_consumer_secret + "%26";
		return url;
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
					success_backend();
				}
				break;
			case OAuth.READABILITY:
				if(getReadabilityApiCode(url))
				{
					m_view.stop_loading();
					success_share();
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


	bool getReadabilityApiCode(string url)
	{
		if(url.has_prefix(ReadabilitySecrets.oauth_callback))
		{
			int verifier_start = url.index_of("=")+1;
			int verifier_end = url.index_of("&", verifier_start);
			string verifier = url.substring(verifier_start, verifier_end-verifier_start);
			settings_readability.set_string("oauth-verifier", verifier);

			int token_start = url.index_of("=", verifier_end)+1;
			int token_end = url.index_of("&",token_start);
			string token = url.substring(token_start, token_end-token_start);
			settings_readability.set_string("oauth-token", token);

			GLib.Thread.usleep(500000);
			return true;
		}
		else
			return false;
	}


}
