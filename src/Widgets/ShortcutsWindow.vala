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
		string globalSync = Settings.keybindings().get_string("global-sync");
		string globalSearch = Settings.keybindings().get_string("global-search");
		string globalQuit = Settings.keybindings().get_string("global-quit");
		var refresh = newShortcut(_("Refresh"), globalSync);
		var search = newShortcut(_("Search"), globalSearch);
		var quit = newShortcut(_("Quit"), globalQuit);
		general.add(refresh);
		general.add(search);
		general.add(quit);
		//--------------------------------------------------


		//--------------------------------------------------
		var feedList = newGroup(_("Feed List"));
		//--------------------------------------------------
		string flprev = Settings.keybindings().get_string("feedlist-prev");
		string flnext = Settings.keybindings().get_string("feedlist-next");
		string feedListMarkRead = Settings.keybindings().get_string("feedlist-mark-read");
		var flNext = newShortcut(_("Select next item"), flnext);
		var flPrev = newShortcut(_("Select previous item"), flprev);
		var expCol = newShortcut(_("Collapse/Expand categories"), "Left Right");
		var flmark = newShortcut(_("Mark the currently selected as read"), feedListMarkRead);
		feedList.add(flNext);
		feedList.add(flPrev);
		feedList.add(expCol);
		feedList.add(flmark);
		//--------------------------------------------------


		//--------------------------------------------------
		var articleList = newGroup(_("Article List"));
		//--------------------------------------------------
		string prev = Settings.keybindings().get_string("articlelist-prev");
		string next = Settings.keybindings().get_string("articlelist-next");
		string nextPrev = "%s %s".printf(prev, next);
		string center = Settings.keybindings().get_string("articlelist-center-selected");
		string toggleRead = Settings.keybindings().get_string("articlelist-toggle-read");
		string toggleMarked = Settings.keybindings().get_string("articlelist-toggle-marked");
		string openUrl = Settings.keybindings().get_string("articlelist-open-url");
		var nextprev = newShortcut(_("Select next/previous article"), nextPrev);
		var toggleread = newShortcut(_("Toggle reading status of selected article"), toggleRead);
		var togglemarked = newShortcut(_("Toggle marking of selected article"), toggleMarked);
		var openURL = newShortcut(_("Open the URL of the selected article"), openUrl);
		var upDown = newShortcut(_("Scroll all the way up/down"), "Page_Up Page_Down");
		var centerSelected = newShortcut(_("Center the currently selected article"), center);
		articleList.add(nextprev);
		articleList.add(toggleread);
		articleList.add(togglemarked);
		articleList.add(openURL);
		articleList.add(upDown);
		articleList.add(centerSelected);
		//--------------------------------------------------


		//--------------------------------------------------
		var articleView = newGroup(_("Article View"));
		//--------------------------------------------------
		string up = Settings.keybindings().get_string("articleview-up");
		string down = Settings.keybindings().get_string("articleview-down");
		string AVupDown = "%s %s".printf(up, down);
		var AVupdown = newShortcut(_("Scroll up/down"), AVupDown);
		articleView.add(AVupdown);
		//--------------------------------------------------


		//--------------------------------------------------
		var section = newSection("test", "section", 10);
		//--------------------------------------------------
		section.add(general);
		section.add(feedList);
		section.add(articleList);
		section.add(articleView);
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
