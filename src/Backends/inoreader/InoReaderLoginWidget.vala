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

public class FeedReader.InoReaderLoginWidget : Gtk.Box {

	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private InoReaderUtils m_utils;

	public InoReaderLoginWidget()
	{
		var userLabel = new Gtk.Label(_("Username:"));
		var passwordLabel = new Gtk.Label(_("Password:"));

		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_userEntry.activate.connect(writeData);
		m_passwordEntry.activate.connect(writeData);

		m_passwordEntry.set_invisible_char('*');
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		var logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-inoreader.svg");

		grid.attach(userLabel, 0, 0, 1, 1);
		grid.attach(m_userEntry, 1, 0, 1, 1);
		grid.attach(passwordLabel, 0, 1, 1, 1);
		grid.attach(m_passwordEntry, 1, 1, 1, 1);

		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 10;
		this.pack_start(logo, false, false, 10);
		this.pack_start(grid, true, true, 10);
		this.show_all();
	}

	public void writeData()
	{
		m_utils.setUser(m_userEntry.get_text());
		m_utils.setPassword(m_passwordEntry.get_text());
	}

	public void fill()
	{
		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());
	}
}
