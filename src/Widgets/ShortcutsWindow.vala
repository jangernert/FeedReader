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

public class FeedReader.ShortcutsWindow : Gtk.ShortcutsWindow {

	public ShortcutsWindow(Gtk.Window parent)
	{
		//--------------------------------------------------
		var general = newGroup(_("General"));
		//--------------------------------------------------
		var refresh = newShortcut(_("Refresh"), "F5");
		var search = newShortcut(_("Search"), "<Primary>F");
		var quit = newShortcut(_("Quit"), "<Primary>Q");
		general.add(refresh);
		general.add(search);
		general.add(quit);
		//--------------------------------------------------


		//--------------------------------------------------
		var feedList = newGroup(_("Feed-List"));
		//--------------------------------------------------
		var navigate = newShortcut(_("Navigate the feed-list"), "Up Down");
		var expCol = newShortcut(_("Collapse/Expand categories"), "Left Right");
		var flmark = newShortcut(_("Mark the currently selected as read"), "<SHIFT>A");
		feedList.add(navigate);
		feedList.add(expCol);
		feedList.add(flmark);
		//--------------------------------------------------


		//--------------------------------------------------
		var articleList = newGroup(_("Article-List"));
		//--------------------------------------------------
		var nextprev = newShortcut(_("Select next/previous article"), "J K");
		var toggleRead = newShortcut(_("Toggle the selected article un/read"), "R");
		var toggleMarked = newShortcut(_("Toggle the selected article un/marked"), "M");
		var openURL = newShortcut(_("Open the URL of the selected article"), "O");
		var upDown = newShortcut(_("Scroll all the way up/down"), "Page_Up Page_Down");
		var centerSelected = newShortcut(_("Center the currently selected article"), "S");
		articleList.add(nextprev);
		articleList.add(toggleRead);
		articleList.add(toggleMarked);
		articleList.add(openURL);
		articleList.add(upDown);
		articleList.add(centerSelected);
		//--------------------------------------------------


		//--------------------------------------------------
		var section = newSection("test", "section", 10);
		//--------------------------------------------------
		section.add(general);
		section.add(feedList);
		section.add(articleList);
		//--------------------------------------------------


		this.add(section);
		this.set_transient_for(parent);
		this.set_modal(true);
		this.show_all();
	}

	private Gtk.ShortcutsSection newSection(string title, string section_name, int maxHeight)
	{
		var section = (Gtk.ShortcutsSection)Object.new(typeof(Gtk.ShortcutsSection), title: title, section_name: section_name, max_height: maxHeight);
		section.show();
		return section;
	}

	private Gtk.ShortcutsGroup newGroup(string title)
	{
		var group = (Gtk.ShortcutsGroup)Object.new(typeof(Gtk.ShortcutsGroup), title: title);
		group.show();
		return group;
	}

	private Gtk.ShortcutsShortcut newShortcut(string title, string key)
	{
		var shortcut = (Gtk.ShortcutsShortcut)Object.new(typeof(Gtk.ShortcutsShortcut), title: title, accelerator: key);
		shortcut.show();
		return shortcut;
	}

}
