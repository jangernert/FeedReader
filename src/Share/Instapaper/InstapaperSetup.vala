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
	private Gtk.InfoBar m_errorBar;
	private Gtk.Revealer m_login_revealer;

	public InstapaperSetup(string? id, bool loggedIn, string username = "")
	{
		base("Instapaper", "feed-share-instapaper", loggedIn, username);

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

		m_errorBar = new Gtk.InfoBar();
		m_errorBar.no_show_all = true;
		var error_content = m_errorBar.get_content_area();
		var errorLabel = new Gtk.Label(_("Username or Password incorrect"));
		errorLabel.show();
		error_content.add(errorLabel);
		m_errorBar.set_message_type(Gtk.MessageType.WARNING);
		m_errorBar.set_show_close_button(true);
		m_errorBar.response.connect((response_id) => {
			if(response_id == Gtk.ResponseType.CLOSE) {
					m_errorBar.set_visible(false);
			}
		});

        m_userEntry = new Gtk.Entry();
        m_passEntry = new Gtk.Entry();
		m_passEntry.set_invisible_char('*');
		m_passEntry.set_visibility(false);

		m_userEntry.activate.connect(() => {
			m_passEntry.grab_focus();
		});

		m_passEntry.activate.connect(() => {
			login();
		});

		grid.attach(m_errorBar, 0, 0, 2, 1);
        grid.attach(new Gtk.Label(_("Username:")), 0, 1, 1, 1);
        grid.attach(new Gtk.Label(_("Password:")), 0, 2, 1, 1);
        grid.attach(m_userEntry, 1, 1, 1, 1);
        grid.attach(m_passEntry, 1, 2, 1, 1);

		m_login_revealer = new Gtk.Revealer();
		m_login_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_login_revealer.add(grid);
		//------------------------------------------------

		m_seperator_box.pack_start(m_login_revealer, false, false, 0);

		if(id != null)
			m_id = id;
	}


	public override void login()
	{
		string id = "";
		if(m_login_revealer.get_child_revealed())
		{
			if(share.getAccessToken(OAuth.INSTAPAPER, out id, "",  m_userEntry.get_text(), m_passEntry.get_text()))
			{
				m_id = id;
				m_login_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
				m_login_revealer.set_reveal_child(false);
				m_isLoggedIN = true;
				m_iconStack.set_visible_child_name("loggedIN");
				m_label.set_label(share.getUsername(m_id));
				m_labelStack.set_visible_child_name("loggedIN");
			}
			else
			{
				m_errorBar.set_visible(true);
			}

		}
		else
		{
			m_login_revealer.set_reveal_child(true);
			m_login_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			m_userEntry.grab_focus();
		}
	}
}
