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


public class FeedReader.ttrssLoginWidget : Gtk.Box {

	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private Gtk.Entry m_authPasswordEntry;
	private Gtk.Entry m_authUserEntry;
	private Gtk.Revealer m_revealer;
	private bool m_need_htaccess = false;
	private ttrssUtils m_utils;
	public signal void login();

	public ttrssLoginWidget()
	{
		m_utils = new ttrssUtils();

		var url_label = new Gtk.Label(_("TinyTinyRSS URL:"));
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		url_label.set_alignment(1.0f, 0.5f);
		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);

		url_label.set_hexpand(true);
		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_urlEntry = new Gtk.Entry();
		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_urlEntry.activate.connect(writeData);
		m_userEntry.activate.connect(writeData);
		m_passwordEntry.activate.connect(writeData);

		m_passwordEntry.set_invisible_char('*');
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		grid.attach(url_label, 0, 0, 1, 1);
		grid.attach(m_urlEntry, 1, 0, 1, 1);
		grid.attach(user_label, 0, 1, 1, 1);
		grid.attach(m_userEntry, 1, 1, 1, 1);
		grid.attach(password_label, 0, 2, 1, 1);
		grid.attach(m_passwordEntry, 1, 2, 1, 1);


		// http auth stuff ----------------------------------------------------
		var auth_user_label = new Gtk.Label(_("Username:"));
		var auth_password_label = new Gtk.Label(_("Password:"));

		auth_user_label.set_alignment(1.0f, 0.5f);
		auth_password_label.set_alignment(1.0f, 0.5f);

		auth_user_label.set_hexpand(true);
		auth_password_label.set_hexpand(true);

		m_authUserEntry = new Gtk.Entry();
		m_authPasswordEntry = new Gtk.Entry();
		m_authPasswordEntry.set_invisible_char('*');
		m_authPasswordEntry.set_visibility(false);

		m_authUserEntry.activate.connect(writeData);
		m_authPasswordEntry.activate.connect(writeData);

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(auth_user_label, 0, 0, 1, 1);
		authGrid.attach(m_authUserEntry, 1, 0, 1, 1);
		authGrid.attach(auth_password_label, 0, 1, 1, 1);
		authGrid.attach(m_authPasswordEntry, 1, 1, 1, 1);

		var frame = new Gtk.Frame(_("HTTP Authorization"));
		frame.set_halign(Gtk.Align.CENTER);
		frame.add(authGrid);
		m_revealer = new Gtk.Revealer();
		m_revealer.add(frame);
		//---------------------------------------------------------------------

		var logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-ttrss.svg");

		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 10;
		this.pack_start(logo, false, false, 10);
		this.pack_start(grid, true, true, 10);
		this.pack_start(m_revealer, true, true, 10);
		this.show_all();
	}

	public void showHtAccess()
	{
		m_revealer.set_reveal_child(true);
	}

	public void writeData()
	{
		m_utils.setURL(m_urlEntry.get_text());
		m_utils.setUser(m_userEntry.get_text());
		m_utils.setPassword(m_passwordEntry.get_text());
		if(m_need_htaccess)
		{
			m_utils.setHtaccessUser(m_authUserEntry.get_text());
			m_utils.setHtAccessPassword(m_authPasswordEntry.get_text());
		}
	}

	public void fill()
	{
		m_urlEntry.set_text(m_utils.getUnmodifiedURL());
		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());
	}
}
