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

public class FeedReader.InstapaperSetup : ServiceSetup {
	
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passEntry;
	private Gtk.Revealer m_login_revealer;
	private InstaAPI m_api;
	
	public InstapaperSetup(string? id, InstaAPI api, string username = "")
	{
		bool loggedIN = false;
		if(username != "")
		{
			loggedIN = true;
		}
		
		base("Instapaper", "feed-share-instapaper", loggedIN, username);
		
		//------------------------------------------------
		// XAuth revealer
		//------------------------------------------------
		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);
		grid.margin_bottom = 10;
		grid.margin_top = 5;
		
		m_userEntry = new Gtk.Entry();
		m_passEntry = new Gtk.Entry();
		m_passEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_passEntry.set_visibility(false);
		
		m_userEntry.activate.connect(() => {
			m_passEntry.grab_focus();
		});
		
		m_passEntry.activate.connect(() => {
			login();
		});
		
		grid.attach(new Gtk.Label(_("Username:")), 0, 0, 1, 1);
		grid.attach(new Gtk.Label(_("Password:")), 0, 1, 1, 1);
		grid.attach(m_userEntry, 1, 0, 1, 1);
		grid.attach(m_passEntry, 1, 1, 1, 1);
		
		m_login_revealer = new Gtk.Revealer();
		m_login_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_login_revealer.add(grid);
		//------------------------------------------------
		
		m_seperator_box.pack_start(m_login_revealer, false, false, 0);
		
		m_api = api;
		
		if(id != null)
		{
			m_id = id;
		}
	}
	
	
	public override void login()
	{
		if(m_login_revealer.get_child_revealed())
		{
			m_spinner.start();
			m_iconStack.set_visible_child_name("spinner");
			string id = Share.get_default().generateNewID();
			string username = m_userEntry.get_text();
			string password = m_passEntry.get_text();
			
			if(m_api.getAccessToken(id, username, password))
			{
				m_id = id;
				m_api.addAccount(id, m_api.pluginID(), username, m_api.getIconName(), m_api.pluginName());
				m_login_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
				m_login_revealer.set_reveal_child(false);
				m_isLoggedIN = true;
				m_iconStack.set_visible_child_name("loggedIN");
				m_spinner.stop();
				m_label.set_label(username);
				m_labelStack.set_visible_child_name("loggedIN");
				m_login_button.clicked.disconnect(login);
				m_login_button.clicked.connect(logout);
			}
			else
			{
				showInfoBar(_("Username or Password incorrect"));
				m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
			}
			
		}
		else
		{
			m_login_revealer.set_reveal_child(true);
			m_login_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			m_userEntry.grab_focus();
		}
	}
	
	public override void logout()
	{
		Logger.debug("InstapaperSetup.logout()");
		m_isLoggedIN = false;
		m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
		m_labelStack.set_visible_child_name("loggedOUT");
		m_api.logout(m_id);
		removeRow();
	}
}
