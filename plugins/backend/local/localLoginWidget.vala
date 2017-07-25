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

	private Gtk.ListBox m_feedlist;

	public void init()
	{

	}

	public string getWebsite()
	{
		return "http://jangernert.github.io/FeedReader/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.LOCAL | BackendFlags.FREE_SOFTWARE | BackendFlags.FREE);
	}

	public string getID()
	{
		return "local";
	}

	public string iconName()
	{
		return "feed-service-local";
	}

	public string serviceName()
	{
		return "Local RSS";
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
		var doneLabel = new Gtk.Label(_("Done"));
		var waitingLabel = new Gtk.Label(_("Adding Feeds"));
		var waitingSpinner = new Gtk.Spinner();
		var waitingBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		waitingBox.pack_start(waitingSpinner, false, false, 0);
		waitingBox.pack_start(waitingLabel, true, false, 0);
		var loginStack = new Gtk.Stack();
		loginStack.add_named(doneLabel, "label");
		loginStack.add_named(waitingBox, "waiting");
		var loginButton = new Gtk.Button();
		loginButton.add(loginStack);
		loginButton.halign = Gtk.Align.END;
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		loginButton.clicked.connect(() => {
			login();
			loginButton.set_sensitive(false);
			waitingSpinner.start();
			loginButton.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			loginStack.set_visible_child_name("waiting");
		});
		loginButton.show_all();

		var headlineLabel = new Gtk.Label("Recommended Feeds:");
		headlineLabel.get_style_context().add_class("h1");
		headlineLabel.set_justify(Gtk.Justification.CENTER);

		var loginLabel = new Gtk.Label("Fill your library with feeds. Here are some recommendations.");
		loginLabel.get_style_context().add_class("h2");
		loginLabel.set_justify(Gtk.Justification.CENTER);
		loginLabel.set_lines(3);

		m_feedlist = new Gtk.ListBox();
		m_feedlist.set_selection_mode(Gtk.SelectionMode.NONE);
		m_feedlist.set_sort_func(sortFunc);
		m_feedlist.set_header_func(headerFunc);

		try
		{
			uint8[] contents;
			var file = File.new_for_uri("resource:///org/gnome/FeedReader/recommendedFeeds.json");
			file.load_contents(null, out contents, null);

			var parser = new Json.Parser();
			parser.load_from_data((string)contents);

			Json.Array array = parser.get_root().get_array();

			for (int i = 0; i < array.get_length (); i++)
			{
				Json.Object object = array.get_object_element(i);

				m_feedlist.add(
					new SuggestedFeedRow(
						object.get_string_member("url"),
						object.get_string_member("category"),
						object.get_string_member("name"),
						object.get_string_member("description"),
						object.get_string_member("language")
						)
				);
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("localLoginWidget: loading json filed");
			Logger.error(e.message);
		}

		var scroll = new Gtk.ScrolledWindow(null, null);
		scroll.set_size_request(450, 0);
		scroll.set_halign(Gtk.Align.CENTER);
		scroll.get_style_context().add_class(Gtk.STYLE_CLASS_FRAME);
		scroll.add(m_feedlist);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.margin = 50;
		box.valign = Gtk.Align.FILL;
		box.halign = Gtk.Align.CENTER;
		box.pack_start(headlineLabel, false, false, 0);
		box.pack_start(loginLabel, false, false, 2);
		box.pack_start(scroll, true, true, 20);
		box.pack_end(loginButton, false, false, 0);
		return box;
	}

	public void showHtAccess()
	{
		return;
	}

	public void writeData()
	{
		return;
	}

	public async void postLoginAction()
	{
		SourceFunc callback = postLoginAction.callback;
		new GLib.Thread<void*>(null, () => {
			var children = m_feedlist.get_children();
			foreach(var r in children)
			{
				var row = r as SuggestedFeedRow;
				if(row.checked())
				{
					try
					{
						DBusConnection.get_default().addFeed(row.getURL(), row.getCategory(), false, false);
					}
					catch(GLib.Error e)
					{
						Logger.error("localLoginWidget.postLoginAction: %s".printf(e.message));
					}
				}
			}
			Idle.add((owned) callback);
			return null;
		});
		yield;
	}

	public string buildLoginURL()
	{
		return "";
	}

	public bool extractCode(string redirectURL)
	{
		return false;
	}

	private int sortFunc(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2)
	{
		var r1 = row1 as SuggestedFeedRow;
		var r2 = row2 as SuggestedFeedRow;

		string cat1 = r1.getCategory();
		string cat2 = r2.getCategory();

		string name1 = r1.getName();
		string name2 = r2.getName();

		if(cat1 != cat2)
			return cat1.collate(cat2);

		return name1.collate(name2);
	}

	private void headerFunc(Gtk.ListBoxRow row, Gtk.ListBoxRow? before)
	{
		var r1 = row as SuggestedFeedRow;
		string cat1 = r1.getCategory();

		var label = new Gtk.Label(cat1);
		label.get_style_context().add_class("bold");
		label.margin_top = 20;
		label.margin_bottom = 5;

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.pack_start(label, true, true, 0);
		box.pack_end(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 0);
		box.show_all();

		if(before == null)
		{
			row.set_header(box);
			return;
		}

		var r2 = before as SuggestedFeedRow;
		string cat2 = r2.getCategory();

		if(cat1 != cat2)
			row.set_header(box);
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
