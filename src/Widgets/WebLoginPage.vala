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

public class FeedReader.WebLoginPage : Gtk.Bin {

	private WebKit.WebView m_view;
	private string m_url;
	private int m_serviceType;
	public signal void success(Backend be);


	public WebLoginPage() {
		var settings = new WebKit.Settings();
		settings.set_user_agent_with_application_details("FeedReader", AboutInfo.version);
		m_view = new WebKit.WebView.with_settings(settings);
		m_view.context_menu.connect(() => { return true; });
		m_view.load_changed.connect(redirection);
		this.add(m_view);
		this.show_all();
	}


	public void loadPage(OAuth serviceType)
	{
		m_serviceType = serviceType;
		m_url = buildURL(serviceType);
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

					success(Backend.FEEDLY);
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

	public static string buildURL(OAuth serviceType)
	{
		string url = "";

		switch(serviceType)
		{
			case OAuth.FEEDLY:
				url = FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId
					+ "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";
				break;
		}

		logger.print(LogMessage.DEBUG, url);
		return url;
	}
}
