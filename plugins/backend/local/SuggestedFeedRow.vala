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

	public SuggestedFeedRow(string url, string iconURL, string category, string name, string desc, string lang)
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

		var uri = new Soup.URI(url);
		var fakeFeed = new Feed(uri.get_host(), "", "", 0);
		load_favicon.begin(iconStack, fakeFeed, iconURL, (obj, res) => {
			load_favicon.end(res);
		});
	}

	private async void load_favicon(Gtk.Stack iconStack, Feed feed, string iconURL)
	{
		bool success = yield FavIconManager.get_default().downloadFavIcon(feed, iconURL);

		Gtk.Image? icon = null;
		if(success)
		{
			var pixBuf = yield FavIconManager.get_default().getIcon(feed.getFeedID());
			if(pixBuf != null)
				icon = new Gtk.Image.from_pixbuf(pixBuf);
		}

		if(icon == null)
		{
			icon = new Gtk.Image.from_icon_name("feed-rss-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		}

		iconStack.add_named(icon, "icon");
		show_all();
		iconStack.set_visible_child_name("icon");
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
