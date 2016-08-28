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

public class FeedReader.ReadabilitySetup : ServiceSetup {

	private ReadabilityAPI m_api;

	public ReadabilitySetup(string? id, string username = "")
	{
		bool loggedIN = false;
		if(username != "")
			loggedIN = true;

		base("Readability", "feed-share-readability", loggedIN, username);

		m_api = new ReadabilityAPI();
		m_login_button.clicked.connect(logoutAPI);

		if(id != null)
			m_id = id;
	}


	public override void login()
	{
		string id = share.getNewID();
		string requestToken = m_api.getRequestToken();
		string url = m_api.getURL(requestToken);
		Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);

		m_login_button.set_label(_("waiting"));
		m_login_button.set_sensitive(false);
		((FeedApp)GLib.Application.get_default()).callback.connect((content) => {

			if(content.has_prefix(ReadabilitySecrets.oauth_callback))
			{
				int verifier_start = content.index_of("=")+1;
				int verifier_end = content.index_of("&", verifier_start);
				string verifier = content.substring(verifier_start, verifier_end-verifier_start);

				if(m_api.getAccessToken(id, verifier))
				{
					m_id = id;
					share.addAccount(id, m_api.pluginID(), m_api.getUsername(id), m_api.getIconName(), m_api.pluginName());
					m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_LEFT);
					m_isLoggedIN = true;
					m_label.set_label(share.getUsername(m_id));
					m_labelStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.CROSSFADE);
				}
			}
		});
	}

	private void logoutAPI()
	{
		m_api.logout(m_id);
	}
}
