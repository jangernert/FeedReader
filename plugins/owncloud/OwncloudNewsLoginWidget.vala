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


public class FeedReader.OwnCloudNewsLoginWidget : Gtk.Box {

	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private Gtk.Entry m_AuthUserEntry;
	private Gtk.Entry m_AuthPasswordEntry;
	private Gtk.Revealer m_revealer;
	private OwncloudNewsUtils m_utils;
	private bool m_need_htaccess = false;

	public OwnCloudNewsLoginWidget()
	{
		m_utils = new OwncloudNewsUtils();

		var urlLabel = new Gtk.Label(_("OwnCloud URL:"));
		var userLabel = new Gtk.Label(_("Username:"));
		var passwordLabel = new Gtk.Label(_("Password:"));

		urlLabel.set_alignment(1.0f, 0.5f);
		userLabel.set_alignment(1.0f, 0.5f);
		passwordLabel.set_alignment(1.0f, 0.5f);

		urlLabel.set_hexpand(true);
		userLabel.set_hexpand(true);
		passwordLabel.set_hexpand(true);

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

		var logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-owncloud.svg");

		grid.attach(urlLabel, 0, 0, 1, 1);
		grid.attach(m_urlEntry, 1, 0, 1, 1);
		grid.attach(userLabel, 0, 1, 1, 1);
		grid.attach(m_userEntry, 1, 1, 1, 1);
		grid.attach(passwordLabel, 0, 2, 1, 1);
		grid.attach(m_passwordEntry, 1, 2, 1, 1);

		// http auth stuff ----------------------------------------------------
		var authUserLabel = new Gtk.Label(_("Username:"));
		var authPasswordLabel = new Gtk.Label(_("Password:"));

		authUserLabel.set_alignment(1.0f, 0.5f);
		authPasswordLabel.set_alignment(1.0f, 0.5f);

		authUserLabel.set_hexpand(true);
		authPasswordLabel.set_hexpand(true);

		m_AuthUserEntry = new Gtk.Entry();
		m_AuthPasswordEntry = new Gtk.Entry();
		m_AuthPasswordEntry.set_invisible_char('*');
		m_AuthPasswordEntry.set_visibility(false);

		m_AuthUserEntry.activate.connect(writeData);
		m_AuthPasswordEntry.activate.connect(writeData);

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(authUserLabel, 0, 0, 1, 1);
		authGrid.attach(m_AuthUserEntry, 1, 0, 1, 1);
		authGrid.attach(authPasswordLabel, 0, 1, 1, 1);
		authGrid.attach(m_AuthPasswordEntry, 1, 1, 1, 1);

		var frame = new Gtk.Frame(_("HTTP Authorization"));
		frame.set_halign(Gtk.Align.CENTER);
		frame.add(authGrid);
		m_revealer = new Gtk.Revealer();
		m_revealer.add(frame);
		//---------------------------------------------------------------------

		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 10;
		this.pack_start(logo, false, false, 10);
		this.pack_start(grid, true, true, 10);
		this.pack_start(m_revealer, true, true, 10);
		this.show_all();
	}

	public void writeData()
	{
		m_utils.setURL(m_urlEntry.get_text());
		m_utils.setUser(m_userEntry.get_text());
		m_utils.setPassword(m_passwordEntry.get_text());
		if(m_need_htaccess)
		{
			m_utils.setHtaccessUser(m_AuthUserEntry.get_text());
			m_utils.setHtAccessPassword(m_AuthPasswordEntry.get_text());
		}
	}

	public void showHtAccess()
	{
		m_revealer.set_reveal_child(true);
	}

	public void fill()
	{
		m_urlEntry.set_text(m_utils.getUnmodifiedURL());
		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());
	}

	public void populateList(Gtk.ListStore liststore)
	{
		Gtk.TreeIter iter;
		liststore.append(out iter);
		liststore.set(iter, 0, _("OwnCloud"));
	}
}
