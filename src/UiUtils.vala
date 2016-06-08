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

public class FeedReader.UiUtils : GLib.Object {


	public static uint getRelevantArticles(int newArticlesCount)
	{
		string[] selectedRow = {};
		ArticleListState state = ArticleListState.ALL;
		string searchTerm = "";
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			var interfacestate = window.getInterfaceState();
			selectedRow = interfacestate.getFeedListSelectedRow().split(" ", 2);
			state = interfacestate.getArticleListState();
			searchTerm = interfacestate.getSearchTerm();
		}

		FeedListType IDtype = FeedListType.FEED;

		logger.print(LogMessage.DEBUG, "selectedRow 0: %s".printf(selectedRow[0]));
		logger.print(LogMessage.DEBUG, "selectedRow 1: %s".printf(selectedRow[1]));

		switch(selectedRow[0])
		{
			case "feed":
				IDtype = FeedListType.FEED;
				break;

			case "cat":
				IDtype = FeedListType.CATEGORY;
				break;

			case "tag":
				IDtype = FeedListType.TAG;
				break;
		}


		bool only_unread = false;
		bool only_marked = false;

		switch(state)
		{
			case ArticleListState.ALL:
				break;
			case ArticleListState.UNREAD:
				only_unread = true;
				break;
			case ArticleListState.MARKED:
				only_marked = true;
				break;
		}

		var articles = dataBase.read_articles(
			selectedRow[1],
			IDtype,
			only_unread,
			only_marked,
			searchTerm,
			newArticlesCount,
			0,
			newArticlesCount);

		return articles.size;
	}

	public static bool canManipulateContent(bool? online = null)
	{
		// if backend = local RSS -> return true;

		// when we already know wheather feedreader is online or offline
		if(online != null)
		{
			if(online)
				return true;
			else
				return false;
		}

		// otherwise check if online
		return feedDaemon_interface.isOnline();
	}

	public static GLib.Menu getMenu()
	{
		var settingMenu = new GLib.Menu();
		settingMenu.append(Menu.settings, "win.settings");
		settingMenu.append(Menu.reset, "win.reset");

		var urlMenu = new GLib.Menu();
		urlMenu.append(Menu.bugs, "win.bugs");
		urlMenu.append(Menu.bounty, "win.bounty");

		var aboutMenu = new GLib.Menu();
#if USE_GTK320
		aboutMenu.append(Menu.shortcuts, "win.shortcuts");
#endif
		aboutMenu.append(Menu.about, "win.about");
		aboutMenu.append(Menu.quit, "app.quit");

		var menu = new GLib.Menu();
		menu.append_section("", settingMenu);
		menu.append_section("", urlMenu);

		if(GLib.Environment.get_variable("XDG_CURRENT_DESKTOP").down() != "pantheon")
		{
			menu.append_section("", aboutMenu);
		}

		return menu;
	}
}
