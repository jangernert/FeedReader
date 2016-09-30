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

public class FeedReader.PocketSetup : ServiceSetup {

	private PocketAPI m_api;

	public PocketSetup(string? id, PocketAPI api, string username = "")
	{
		bool loggedIN = false;
		if(username != "")
			loggedIN = true;

		base("Pocket", "feed-share-pocket", loggedIN, username);

		m_api = api;

		if(id != null)
			m_id = id;
	}


	public override void login()
	{
		string id = Share.generateNewID();
		string requestToken = m_api.getRequestToken();
		string url = m_api.getURL(requestToken);
		try
		{
			Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
		}
		catch(GLib.Error e)
		{
			
		}


		m_login_button.set_label(_("waiting"));
		m_login_button.set_sensitive(false);
		((FeedApp)GLib.Application.get_default()).callback.connect((content) => {

			if(content == PocketSecrets.oauth_callback)
			{
				if(m_api.getAccessToken(id, requestToken))
				{
					m_id = id;
					m_api.addAccount(id, m_api.pluginID(), m_api.getUsername(id), m_api.getIconName(), m_api.pluginName());
					m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_LEFT);
					m_isLoggedIN = true;
					m_label.set_label(m_api.getUsername(id));
					m_labelStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.CROSSFADE);
					m_login_button.clicked.disconnect(login);
					m_login_button.clicked.connect(logout);
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
