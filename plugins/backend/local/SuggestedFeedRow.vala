//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.SuggestedFeedRow : Gtk.ListBoxRow {

	private string m_name;
	private string m_url;
	private string m_category;
	private string m_desc;
	private Gtk.CheckButton m_check;

	public SuggestedFeedRow(string url, string category, string name, string desc, string lang)
	{
		m_name = name;
		m_url = url;
		m_category = category;
		m_desc = desc;

		var iconStack = new Gtk.Stack();
		iconStack.set_size_request(24, 24);
		iconStack.set_transition_duration(100);
		iconStack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);

		var spinner = new Gtk.Spinner();
		iconStack.add_named(spinner, "spinner");
		spinner.start();

		m_check = new Gtk.CheckButton();
		var label = new Gtk.Label(name);
		label.get_style_context().add_class("h3");
		label.set_alignment(0.0f, 0.5f);

		var langLabel = new Gtk.Label(lang);
		langLabel.opacity = 0.7;
		langLabel.set_alignment(1.0f, 0.5f);
		langLabel.get_style_context().add_class("preview");

		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		box.margin_top = 5;
		box.margin_bottom = 5;
		box.pack_start(m_check, false, false, 10);
		box.pack_start(iconStack, false, false, 10);
		box.pack_start(label, true, true, 10);
		box.pack_end(langLabel, false, false, 10);
		var box2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box2.pack_start(box);
		box2.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
		this.add(box2);
		this.set_tooltip_text(m_desc);
		show_all();

		downloadIcon.begin("/tmp/",m_url, (obj, res) => {
			bool success = downloadIcon.end(res);
			Gtk.Image? icon = null;

			if(success)
			{
				try
				{
					string filename = "/tmp/" + m_url.replace("/", "_").replace(".", "_") + ".ico";
					Logger.debug("load icon %s".printf(filename));
					var tmp_icon = new Gdk.Pixbuf.from_file_at_scale(filename, 24, 24, true);
					icon = new Gtk.Image.from_pixbuf(tmp_icon);
				}
				catch(GLib.Error e)
				{
					Logger.error("SuggestedFeedRow.constructor: %s".printf(e.message));
				}
			}
			else
			{
				icon = new Gtk.Image.from_icon_name("feed-rss-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
			}

			iconStack.add_named(icon, "icon");
   			show_all();
   			iconStack.set_visible_child_name("icon");
		});
	}

	private async bool downloadIcon(string path, string url)
	{
		if(url == "" || url == null || GLib.Uri.parse_scheme(url) == null)
            return false;

		SourceFunc callback = downloadIcon.callback;
		bool success = false;
		string filename = "/tmp/" + m_url.replace("/", "_").replace(".", "_") + ".ico";

		new GLib.Thread<void*>(null, () => {

			if(FileUtils.test(filename, GLib.FileTest.EXISTS))
			{
				success = true;
				Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
				return null;
			}

			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
			session.timeout = 5;
			var msg = new Soup.Message("GET", m_url.escape(""));
			session.send_message(msg);
			string xml = (string)msg.response_body.flatten().data;

			Rss.Parser parser = new Rss.Parser();
			try
			{
				parser.load_from_data(xml, xml.length);
			}
			catch(GLib.Error e)
			{
				Logger.error("SuggestedFeedRow.downloadIcon: %s".printf(e.message));
			}
			var doc = parser.get_document();

			if(doc.image_url != ""
			&& doc.image_url != null
			&& GLib.Uri.parse_scheme(doc.image_url) != null)
			{
				Soup.Message message_dlIcon;
				message_dlIcon = new Soup.Message("GET", doc.image_url);
				var status = session.send_message(message_dlIcon);
				if(status == 200)
				{
					try{
						FileUtils.set_contents(	filename,
												(string)message_dlIcon.response_body.flatten().data,
												(long)message_dlIcon.response_body.length);
					}
					catch(GLib.FileError e)
					{
						Logger.error("Error writing icon: %s".printf(e.message));
					}
					success = true;
				}
				Logger.error("Error downloading icon for feed: %s".printf(m_url));
			}
			else
			{
				if(Utils.downloadFavIcon(session, url, url, path))
					success = true;
			}
			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		});
		yield;

		return success;
	}

	public bool checked()
	{
		return m_check.active;
	}

	public string getName()
	{
		return m_name;
	}

	public string getURL()
	{
		return m_url;
	}

	public string getCategory()
	{
		return m_category;
	}
}
