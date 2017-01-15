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

public class FeedReader.TwitterSetup : ServiceSetup {

	private TwitterAPI m_api;

	public TwitterSetup(string? id, TwitterAPI api, string username = "")
	{
		bool loggedIN = false;
		if(username != "")
			loggedIN = true;

		base("Twitter", "feed-share-twitter", loggedIN, username);

		m_api = api;

		if(id != null)
			m_id = id;
	}


	public override void login()
	{
		string id = Share.generateNewID();
		string requestToken = m_api.getRequestToken();
		string url = m_api.getURL(requestToken);
		m_spinner.start();
		m_iconStack.set_visible_child_name("spinner");
		try
		{
			Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
		}
		catch(GLib.Error e)
		{

		}

		m_login_button.set_label(_("waiting"));
		m_login_button.set_sensitive(false);
		FeedReaderApp.get_default().callback.connect((content) => {

			if(content.has_prefix(TwitterSecrets.callback))
			{
				int token_start = content.index_of("token=")+6;
				int token_end = content.index_of("&", token_start);
				string token = content.substring(token_start, token_end-token_start);

				int verifier_start = content.index_of("verifier=")+9;
				string verifier = content.substring(verifier_start);

				if(token == requestToken)
				{
					if(m_api.getAccessToken(id, verifier))
					{
						m_id = id;
						m_api.addAccount(id, m_api.pluginID(), m_api.getUsername(id), m_api.getIconName(), m_api.pluginName());
						m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_LEFT);
						m_isLoggedIN = true;
						m_spinner.stop();
						m_label.set_label(m_api.getUsername(id));
						m_labelStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.CROSSFADE);
						m_login_button.clicked.disconnect(login);
						m_login_button.clicked.connect(logout);
					}
					else
					{
						m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
					}
				}

			}
		});
	}

	public override void logout()
	{
		m_isLoggedIN = false;
		m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
		m_labelStack.set_visible_child_name("loggedOUT");
		m_api.logout(m_id);
		removeRow();
	}

}
