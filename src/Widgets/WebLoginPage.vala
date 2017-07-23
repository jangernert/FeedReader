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
	private bool m_success = false;
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
		Logger.debug("WebLoginPage: load URL: " + url);
		m_view.load_uri(url);
	}

	public void redirection(WebKit.LoadEvent load_event)
	{
		switch(load_event)
		{
		case WebKit.LoadEvent.STARTED:
			check();
			break;
		case WebKit.LoadEvent.REDIRECTED:
			check();
			break;
		case WebKit.LoadEvent.COMMITTED:
			break;
		case WebKit.LoadEvent.FINISHED:
			break;
		}
	}

	private void check()
	{
		if(m_success)
			// code already successfully extracted
			return;

		string url = m_view.get_uri();

		if(getApiCode(url))
		{
			m_view.stop_loading();
			m_success = true;
			success();

		}
	}

	public void reset()
	{
		m_view.load_uri("about:blank");
		m_success = false;
	}
}
