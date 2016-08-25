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

public class FeedReader.localLoginWidget : Peas.ExtensionBase, LoginInterface {


	public Gtk.Stack m_stack { get; construct set; }
	public Gtk.ListStore m_listStore { get; construct set; }
	public Logger m_logger { get; construct set; }
	public string m_installPrefix { get; construct set; }


	public void init()
	{
		var logo = new Gtk.Image.from_file(m_installPrefix + "/share/icons/hicolor/64x64/places/feed-service-local.svg");

		var text = new Gtk.Label(_("Nothing you have to do. Just go ahead and add feeds."));
		text.get_style_context().add_class("h3");
		text.set_justify(Gtk.Justification.CENTER);
		text.set_line_wrap_mode(Pango.WrapMode.WORD);
		text.set_line_wrap(true);
		text.set_lines(3);
		text.expand = false;
		text.set_width_chars(60);
		text.set_max_width_chars(60);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(text, true, true, 10);
		box.show_all();

		m_stack.add_named(box, "localUI");

		Gtk.TreeIter iter;
		m_listStore.append(out iter);
		m_listStore.set(iter, 0, _("Local RSS"), 1, "localUI");
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
		return;
	}

	public string buildLoginURL()
	{
		return "";
	}

	public bool extractCode(string redirectURL)
	{
		return false;
	}
}


//--------------------------------------------------------------------------------------
// Boilerplate code for the plugin. Replace "demoLoginWidget" with the name
// of your interface-class.
//--------------------------------------------------------------------------------------
[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.LoginInterface), typeof(FeedReader.localLoginWidget));
}
