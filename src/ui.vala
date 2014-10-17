/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * ui.vala
 * Copyright (C) 2014 JeanLuc <jeanluc@jeanluc-desktop>
 *
 * tt-rss is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * tt-rss is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Gtk;

public class readerUI : Gtk.ApplicationWindow 
{
	private  readerHeaderbar m_headerbar;
	private Gtk.Paned m_pane_feedlist;
	private Gtk.Paned m_pane_articlelist;
	private  loginDialog m_loginDialog;
	private articleView m_article_view;
	private articleList m_articleList;
	private feedList m_feedList;
	
	public readerUI(rssReaderApp app)
	{
		Object (application: app, title: _("FeedReader"));
		this.window_position = WindowPosition.CENTER;
		

		m_headerbar = new readerHeaderbar();
		m_headerbar.refresh.connect(app.sync);
		m_headerbar.change_unread.connect((only_unread) => {
			m_articleList.setOnlyUnread(only_unread);
			m_articleList.newHeadlineList(); 
		});

		m_headerbar.change_marked.connect((only_marked) => {
			m_articleList.setOnlyMarked(only_marked);
			m_articleList.newHeadlineList(); 
		});
		
		m_headerbar.search_term.connect((searchTerm) => {
			m_articleList.setSearchTerm(searchTerm);
			m_articleList.newHeadlineList();
		});
		
		
		var about_action = new SimpleAction (_("about"), null);
		about_action.activate.connect (this.about);
		add_action(about_action);

		var login_action = new SimpleAction (_("login"), null);
		login_action.activate.connect (() => {
			m_loginDialog = new loginDialog(this);
			m_loginDialog.submit_data.connect(() => {
				stdout.printf("initial sync\n");
				app.sync();
			});
			m_loginDialog.show_all();
		});
		add_action(login_action);

		
		m_article_view = new articleView();

		setupArticlelist();
		setupFeedlist();
		onClose();
		m_pane_articlelist.pack2(m_article_view, true, false);

		
		this.set_events(Gdk.EventMask.KEY_PRESS_MASK);
		this.add(m_pane_feedlist);
		this.set_titlebar(m_headerbar);
		this.set_title ("FeedReader");
		this.set_default_size(1600, 900);
		this.show_all();
	}

	public void setRefreshButton(bool refreshing)
	{
		m_headerbar.setRefreshButton(refreshing);
	}
	
	public bool currentlyUpdating()
	{
		return m_headerbar.currentlyUpdating();
	}


	private void onClose()
	{
		this.destroy.connect(() => {
			int only_unread = 0;
			if(m_headerbar.m_only_unread) only_unread = 1;
			int only_marked = 0;
			if(m_headerbar.m_only_marked) only_marked = 1;
		
			int feed_row_width = m_pane_feedlist.get_position();
			int article_row_width = m_pane_articlelist.get_position();
			
			
			feedreader_settings.set_strv("expanded-categories", m_feedList.getExpandedCategories());
			
			feedreader_settings.set_int("feed-row-width", feed_row_width);
			feedreader_settings.set_int("article-row-width", article_row_width);
			feedreader_settings.set_boolean("only-unread", m_headerbar.m_only_unread);
			feedreader_settings.set_boolean("only-marked", m_headerbar.m_only_marked);
		});
	}

	private void setupFeedlist()
	{
		int feed_row_width = feedreader_settings.get_int("feed-row-width");
		m_pane_feedlist = new ThinPaned(Gtk.Orientation.HORIZONTAL);
		m_pane_feedlist.set_position(feed_row_width);
		m_feedList = new feedList();
		m_pane_feedlist.pack1(m_feedList, false, false);
		m_pane_feedlist.pack2(m_pane_articlelist, true, false);

		m_feedList.newFeedSelected.connect((feedID) => {
			m_articleList.id_is_feedID = true;
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(feedID);
			m_articleList.newHeadlineList();
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			m_articleList.id_is_feedID = false;
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(categorieID);
			m_articleList.newHeadlineList();
		});
	}

	private void setupArticlelist()
	{
		try {
    		Gtk.CssProvider provider = new Gtk.CssProvider ();
    		provider.load_from_file(GLib.File.new_for_path("/usr/share/FeedReader/FeedReader.css"));
                

			weak Gdk.Display display = Gdk.Display.get_default ();
            weak Gdk.Screen screen = display.get_default_screen ();
			Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		} catch (Error e) {
			warning ("Error: %s", e.message);
		}

		
		int article_row_width = feedreader_settings.get_int("article-row-width");
		m_pane_articlelist = new ThinPaned(Gtk.Orientation.HORIZONTAL);
		m_pane_articlelist.set_size_request(500, 500);
		m_pane_articlelist.set_position(article_row_width);
		m_articleList = new articleList();
		m_pane_articlelist.pack1(m_articleList, false, false);
		m_articleList.setOnlyUnread(m_headerbar.m_only_unread);
		m_articleList.setOnlyMarked(m_headerbar.m_only_marked);
		

		m_articleList.row_activated.connect((row) => {
			if(row.isUnread()){
				ttrss.updateArticleUnread.begin(row.m_articleID, false, (obj, res) => {
					ttrss.updateArticleUnread.end(res);
				});
				row.updateUnread(false);
				row.removeUnreadIcon();
				//dataBase.update_headline(row.m_articleID, "unread", false);
				//dataBase.change_unread(row.m_feedID, false);
				
				dataBase.update_headline.begin(row.m_articleID, "unread", false, (obj, res) => {
					dataBase.update_headline.end(res);
				});
				dataBase.change_unread.begin(row.m_feedID, false, (obj, res) => {
					dataBase.change_unread.end(res);
				});
				updateFeedList();
			}
			m_article_view.fillContent(row.m_articleID);
		});

		m_articleList.updateFeedList.connect(() =>{
			updateFeedList();
		});

		m_articleList.load_more.connect(() => {
				m_articleList.createHeadlineList();
		});
	}

	public void createFeedlist()
	{
		m_feedList.createFeedlist();
	}


	public void updateFeedList()
	{
		m_feedList.updateFeedList.begin((obj, res) => {
			m_feedList.updateFeedList.end(res);
		});
	}

	public void createHeadlineList()
	{
		m_articleList.createHeadlineList();
	}

	public void updateHeadlineList()
	{
		m_articleList.updateHeadlineList();
	}


	private void about() 
	{
		string[] authors = { "Jan Lukas Gernert", null };
		string[] documenters = { "nobody", null };
		Gtk.show_about_dialog (this,
                               "program-name", ("tt-rss Reader"),
                               "copyright", ("Copyright © 2014 Jan Lukas Gernert"),
                               "authors", authors,
		                       "comments", "Desktop Client for tiny tiny rss",
                               "documenters", documenters,
		                       "license_type", Gtk.License.GPL_3_0,
		                       "logo_icon_name", "internet-news-reader",
                               null);
	}


	 
}
