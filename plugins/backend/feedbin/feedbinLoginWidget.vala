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

FeedReader.Logger logger;

public class FeedReader.feedbinLoginWidget : Peas.ExtensionBase, LoginInterface {

	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private feedbinUtils m_utils;

	public Gtk.Stack m_stack { get; construct set; }
	public Gtk.ListStore m_listStore { get; construct set; }
	public Logger m_logger { get; construct set; }
	public string m_installPrefix { get; construct set; }

	public void init()
	{
		logger = m_logger;
		m_utils = new feedbinUtils();

		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);

		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_userEntry.activate.connect(() => { login(); });
		m_passwordEntry.activate.connect(() => { login(); });

		m_passwordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		grid.attach(user_label, 0, 0, 1, 1);
		grid.attach(m_userEntry, 1, 0, 1, 1);
		grid.attach(password_label, 0, 1, 1, 1);
		grid.attach(m_passwordEntry, 1, 1, 1, 1);

		var logo = new Gtk.Image.from_file(m_installPrefix + "/share/icons/hicolor/64x64/places/feed-service-feedbin.svg");

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(grid, true, true, 10);
		box.show_all();

		m_stack.add_named(box, "feedbinUI");

		Gtk.TreeIter iter;
		m_listStore.append(out iter);
		m_listStore.set(iter, 0, _("Feedbin"), 1, "feedbinUI");

		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());
	}

	public bool needWebLogin()
	{
		return false;
	}

	public void showHtAccess()
	{
		return;
	}

	public void writeData()
	{
		m_utils.setUser(m_userEntry.get_text());
		m_utils.setPassword(m_passwordEntry.get_text());
	}

	public bool extractCode(string redirectURL)
	{
		return false;
	}

	public string buildLoginURL()
	{
		return "";
	}
}


[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.feedbinLoginWidget));
}
