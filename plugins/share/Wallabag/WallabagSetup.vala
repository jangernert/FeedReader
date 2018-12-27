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

public class FeedReader.WallabagSetup : ServiceSetup {

private Gtk.Entry m_urlEntry;
private Gtk.Entry m_idEntry;
private Gtk.Entry m_secretEntry;
private Gtk.Entry m_userEntry;
private Gtk.Entry m_passEntry;
private Gtk.Revealer m_login_revealer;
private WallabagAPI m_api;

public WallabagSetup(string? id, WallabagAPI api, string username = "")
{
	bool loggedIN = false;
	if(username != "")
		loggedIN = true;

	base("wallabag", "feed-share-wallabag", loggedIN, username);

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

	m_urlEntry = new Gtk.Entry();
	m_idEntry = new Gtk.Entry();
	m_secretEntry = new Gtk.Entry();
	m_userEntry = new Gtk.Entry();
	m_passEntry = new Gtk.Entry();
	m_passEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
	m_passEntry.set_visibility(false);

	m_urlEntry.activate.connect(() => {
			m_idEntry.grab_focus();
		});

	m_idEntry.activate.connect(() => {
			m_secretEntry.grab_focus();
		});

	m_secretEntry.activate.connect(() => {
			m_userEntry.grab_focus();
		});

	m_userEntry.activate.connect(() => {
			m_passEntry.grab_focus();
		});

	m_passEntry.activate.connect(() => {
			login();
		});

	var urlLabel = new Gtk.Label(_("URL:"));
	var idLabel = new Gtk.Label(_("Client ID:"));
	var secretLabel = new Gtk.Label(_("Client Secret:"));
	var userLabel = new Gtk.Label(_("Username:"));
	var pwLabel = new Gtk.Label(_("Password:"));

	urlLabel.set_alignment(1.0f, 0.5f);
	idLabel.set_alignment(1.0f, 0.5f);
	secretLabel.set_alignment(1.0f, 0.5f);
	userLabel.set_alignment(1.0f, 0.5f);
	pwLabel.set_alignment(1.0f, 0.5f);

	grid.attach(urlLabel, 0, 0, 1, 1);
	grid.attach(idLabel, 0, 1, 1, 1);
	grid.attach(secretLabel, 0, 2, 1, 1);
	grid.attach(userLabel, 0, 3, 1, 1);
	grid.attach(pwLabel, 0, 4, 1, 1);
	grid.attach(m_urlEntry, 1, 0, 1, 1);
	grid.attach(m_idEntry, 1, 1, 1, 1);
	grid.attach(m_secretEntry, 1, 2, 1, 1);
	grid.attach(m_userEntry, 1, 3, 1, 1);
	grid.attach(m_passEntry, 1, 4, 1, 1);

	m_login_revealer = new Gtk.Revealer();
	m_login_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
	m_login_revealer.add(grid);
	//------------------------------------------------

	m_seperator_box.pack_start(m_login_revealer, false, false, 0);

	m_api = api;

	if(id != null)
		m_id = id;
}


public override void login()
{
	if(m_login_revealer.get_child_revealed())
	{
		string id = Share.get_default().generateNewID();
		string username = m_userEntry.get_text();
		string password = m_passEntry.get_text();
		string clientID = m_idEntry.get_text();
		string clientSecret = m_secretEntry.get_text();
		string baseURL = m_urlEntry.get_text();

		// check each and every value
		if(baseURL == null || baseURL == "")
		{
			showInfoBar(_("Please fill in the URL."));
			m_urlEntry.grab_focus();
			return;
		}
		else if(GLib.Uri.parse_scheme(baseURL) == null)
		{
			showInfoBar(_("URL seems to not be valid."));
			m_urlEntry.grab_focus();
			return;
		}

		if(!baseURL.has_suffix("/"))
			baseURL += "/";

		if(clientID == null || clientID == "")
		{
			showInfoBar(_("Please fill in the clientID."));
			m_idEntry.grab_focus();
			return;
		}

		if(clientSecret == null || clientSecret == "")
		{
			showInfoBar(_("Please fill in the clientSecret."));
			m_secretEntry.grab_focus();
			return;
		}

		if(password == null || password == "")
		{
			showInfoBar(_("Please fill in the password."));
			m_passEntry.grab_focus();
			return;
		}

		if(username == null || username == "")
		{
			showInfoBar(_("Please fill in the username."));
			m_userEntry.grab_focus();
			return;
		}

		m_spinner.start();
		m_iconStack.set_visible_child_name("spinner");

		if(m_api.getAccessToken(id, username, password, clientID, clientSecret, baseURL))
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
			m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
			showInfoBar(_("Something went wrong."));
		}

	}
	else
	{
		m_login_revealer.set_reveal_child(true);
		m_login_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		m_urlEntry.grab_focus();
	}
}

public override void logout()
{
	Logger.debug("WallabagSetup: logout");
	m_isLoggedIN = false;
	m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
	m_labelStack.set_visible_child_name("loggedOUT");
	m_api.logout(m_id);
	removeRow();
}

}
