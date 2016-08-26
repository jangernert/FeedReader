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

	public PocketSetup(string? id, bool loggedIn, string username = "")
	{
		base("Pocket", "feed-share-pocket", loggedIn, username);

		if(id != null)
			m_id = id;
	}


	public override void login()
	{
		string id = "";
		string requestToken = share.getRequestToken(OAuth.POCKET);
		share.loginPage(OAuth.POCKET, requestToken);

		m_login_button.set_label(_("waiting"));
		m_login_button.set_sensitive(false);
		((FeedApp)GLib.Application.get_default()).callback.connect((type, oauthVerifier) => {
			if(share.getAccessToken(OAuth.POCKET, out id, oauthVerifier))
			{
				m_id = id;
				m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_LEFT);
				m_isLoggedIN = true;
				m_label.set_label(share.getUsername(m_id));
				m_labelStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.CROSSFADE);
			}
		});
	}

}
