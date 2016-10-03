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
	public signal bool getApiCode(string url);
	public signal void success();


	public WebLoginPage()
	{
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
		Logger.get().debug("WebLoginPage: load URL: " + url);
		m_view.load_uri(url);
	}

	public void redirection(WebKit.LoadEvent load_event)
	{
		Logger.get().debug("WebLoginPage: webView redirection");
		switch(load_event)
		{
			case WebKit.LoadEvent.STARTED:
				Logger.get().debug("WebLoginPage: LoadEvent STARTED");
				check();
				break;
			case WebKit.LoadEvent.REDIRECTED:
				Logger.get().debug("WebLoginPage: LoadEvent REDIRECTED");
				check();
				break;
			case WebKit.LoadEvent.COMMITTED:
				Logger.get().debug("WebLoginPage: LoadEvent COMMITED");
				break;
			case WebKit.LoadEvent.FINISHED:
				Logger.get().debug("WebLoginPage: LoadEvent FINISHED");
				break;
		}
	}

	private void check()
	{
		string url = m_view.get_uri();

		if(getApiCode(url))
		{
			m_view.stop_loading();
			success();
		}
	}

	public void reset()
	{
		m_view.load_uri("about:blank");
	}
}
