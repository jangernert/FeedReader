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
	private string m_plug;
	public signal bool getApiCode(string url);
	public signal void success(string plug);


	public WebLoginPage(string plug)
	{
		m_plug = plug;
		var settings = new WebKit.Settings();
		settings.set_user_agent_with_application_details("FeedReader", AboutInfo.version);
		m_view = new WebKit.WebView();
		m_view.set_settings(settings);
		m_view.context_menu.connect(() => { return true; });
		m_view.load_changed.connect(redirection);
		this.add(m_view);
		this.show_all();
	}


	public void loadPage(string url)
	{
		logger.print(LogMessage.DEBUG, "WebLoginPage: load URL: " + url);
		m_view.load_uri(url);
	}

	public void redirection(WebKit.LoadEvent load_event)
	{
		logger.print(LogMessage.DEBUG, "WebLoginPage: webView redirection");
		switch(load_event)
		{
			case WebKit.LoadEvent.STARTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent STARTED");
				check();
				break;
			case WebKit.LoadEvent.REDIRECTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent REDIRECTED");
				check();
				break;
			case WebKit.LoadEvent.COMMITTED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent COMMITED");
				break;
			case WebKit.LoadEvent.FINISHED:
				logger.print(LogMessage.DEBUG, "WebLoginPage: LoadEvent FINISHED");
				break;
		}
	}

	// FIXME: let the plugin get the api-code
	void check()
	{
		string url = m_view.get_uri();

		if(getApiCode(url))
		{
			m_view.stop_loading();
			success(m_plug);
		}
	}

	// FIXME: let the plugin get the api-code
	bool getFeedlyApiCode(string url)
	{
		/*
		int start = url.index_of("=")+1;
		int end = url.index_of("&");
		string code = url.substring(start, end-start);
		m_feedlyUtils.setApiCode(code);
		logger.print(LogMessage.DEBUG, "WebLoginPage: set feedly-api-code: " + code);
		GLib.Thread.usleep(500000);
		*/
		return true;
	}


	/*
	string url = FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId
				+ "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";


	logger.print(LogMessage.DEBUG, url);
	*/

}
