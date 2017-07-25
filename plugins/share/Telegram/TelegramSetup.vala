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

public class FeedReader.TelegramSetup : ServiceSetup {

	private Telegram m_tg;

	public TelegramSetup(string? id, Telegram tg, string username = "")
	{
		bool loggedIN = false;
		if(username != "")
			loggedIN = true;

		base("Telegram", "feed-share-telegram", loggedIN, username);

		m_tg = tg;
		//no login, so change the labels
		m_login_button.set_label(_("Add"));
		m_logout_button.set_label(_("Remove"));
		m_id = m_tg.pluginID();
	}


	public override void login()
	{
		showInfoBar(_("Info: Telegram would need to be installed for this plugin to work."));
		m_login_button.set_sensitive(false);
		Settings.share("telegram").set_boolean("enabled", true);
		m_tg.addAccount(m_id, m_tg.pluginID(), m_tg.getUsername(m_id), m_tg.getIconName(), m_tg.pluginName());
		m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_LEFT);
		m_isLoggedIN = true;
		m_label.set_label(m_tg.getUsername(m_id));
		m_labelStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.CROSSFADE);
		m_login_button.clicked.disconnect(login);
		m_login_button.clicked.connect(logout);
	}

	public override void logout()
	{
		m_isLoggedIN = false;
		m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
		m_labelStack.set_visible_child_name("loggedOUT");
		m_tg.logout(m_id);
		removeRow();
	}

}
