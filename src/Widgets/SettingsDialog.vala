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

public class FeedReader.SettingsDialog : Gtk.Dialog {

    public signal void newFeedList(bool defaultSettings = false);
    public signal void newArticleList();
    public signal void reloadArticleView();
    private Gtk.Box m_uiBox;
    private Gtk.Box m_internalsBox;
    private Gtk.Box m_serviceBox;

    public SettingsDialog(Gtk.Window parent, string show)
    {
        this.title = "Settings";
		this.border_width = 20;
        this.set_transient_for(parent);
        this.set_modal(true);
		set_default_size(450, 550);

        this.response.connect((id) => {
            switch(id)
            {
                case 1:
                    this.destroy();
                    break;
            }
        });

        var content = get_content_area() as Gtk.Box;
        content.set_spacing(2);

        Gtk.StackSwitcher switcher = new Gtk.StackSwitcher();
        switcher.set_halign(Gtk.Align.CENTER);
        switcher.set_valign(Gtk.Align.CENTER);
        content.pack_start(switcher, false, false, 0);

        Gtk.Stack stack = new Gtk.Stack();
        stack.set_transition_duration(50);
        stack.set_halign(Gtk.Align.FILL);
        content.add(stack);

        switcher.set_stack(stack);


        m_uiBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        m_uiBox.expand = true;
        m_internalsBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        m_internalsBox.expand = true;
        m_serviceBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        m_serviceBox.expand = true;

        stack.add_titled(m_uiBox, "ui", _("Interface"));
        stack.add_titled(m_internalsBox, "internal", _("Internals"));
        stack.add_titled(m_serviceBox, "service", _("Services"));

        setup_feedlist_settings();
        setup_articlelist_settings();
        setup_articleview_settings();
        setup_sync_settings();
        setup_db_settings();
        setup_addfunc_settings();
        setup_service_settings();

        this.add_button(_("Close"), 1);
        this.show_all();

        stack.set_visible_child_name(show);
    }


    private void setup_feedlist_settings()
    {
        var feed_settings = new Gtk.Label(_("Feed List:"));
        feed_settings.margin_top = 15;
        feed_settings.set_alignment(0, 0.5f);
        feed_settings.get_style_context().add_class("h4");
        m_uiBox.pack_start(feed_settings, false, true, 0);

        var only_feeds_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_feeds = new Gtk.Label(_("Only show feeds"));
        only_feeds.set_alignment(0, 0.5f);
        only_feeds.margin_start = 15;
        var only_feeds_switch = new Gtk.Switch();
        only_feeds_switch.active = settings_general.get_boolean("only-feeds");
        only_feeds_switch.notify["active"].connect(() => {
            settings_state.set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
            settings_state.set_string("feedlist-selected-row", "feed -4");
            settings_general.set_boolean("only-feeds",  only_feeds_switch.active);
            newFeedList(true);
        });
        only_feeds_box.pack_start(only_feeds, true, true, 0);
        only_feeds_box.pack_end(only_feeds_switch, false, false, 0);
        m_uiBox.pack_start(only_feeds_box, false, true, 0);

        var only_unread_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_unread = new Gtk.Label(_("Only show unread"));
        only_unread.set_alignment(0, 0.5f);
        only_unread.margin_start = 15;
        var only_unread_switch = new Gtk.Switch();
        only_unread_switch.active = settings_general.get_boolean("feedlist-only-show-unread");
        only_unread_switch.notify["active"].connect(() => {
            settings_general.set_boolean("feedlist-only-show-unread",  only_unread_switch.active);
            newFeedList();
        });
        only_unread_box.pack_start(only_unread, true, true, 0);
        only_unread_box.pack_end(only_unread_switch, false, false, 0);
        m_uiBox.pack_start(only_unread_box, false, true, 0);


        var feedlist_sort_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var feedlist_sort = new Gtk.Label(_("Sort FeedList by"));
        feedlist_sort.set_alignment(0, 0.5f);
        feedlist_sort.margin_start = 15;

        var sort_liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter sort_by_received;
        sort_liststore.append(out sort_by_received);
        sort_liststore.set(sort_by_received, 0, _("Received"));
		Gtk.TreeIter sort_by_alphabetical;
        sort_liststore.append(out sort_by_alphabetical);
        sort_liststore.set(sort_by_alphabetical, 0, _("Alphabetically"));

        var sort_by_box = new Gtk.ComboBox.with_model(sort_liststore);
        var sort_renderer = new Gtk.CellRendererText();
        sort_by_box.pack_start(sort_renderer, false);
        sort_by_box.add_attribute(sort_renderer, "text", 0);
        sort_by_box.changed.connect(() => {
            settings_general.set_enum("feedlist-sort-by", sort_by_box.get_active());
            newFeedList();
        });

        sort_by_box.set_active(settings_general.get_enum("feedlist-sort-by"));
        feedlist_sort_box.pack_start(feedlist_sort, true, true, 0);
        feedlist_sort_box.pack_end(sort_by_box, false, false, 0);
        m_uiBox.pack_start(feedlist_sort_box, false, true, 0);
    }


    private void setup_articlelist_settings()
    {
        var article_settings = new Gtk.Label(_("Article List:"));
        article_settings.margin_top = 15;
        article_settings.set_alignment(0, 0.5f);
        article_settings.get_style_context().add_class("h4");
        m_uiBox.pack_start(article_settings, false, true, 0);

        var article_sort_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var article_sort = new Gtk.Label(_("Sort articles by"));
        article_sort.set_alignment(0, 0.5f);
        article_sort.margin_start = 15;

        var sort_liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter sort_by_date;
        sort_liststore.append(out sort_by_date);
        sort_liststore.set(sort_by_date, 0, _("Date"));
		Gtk.TreeIter sort_by_inserted;
        sort_liststore.append(out sort_by_inserted);
        sort_liststore.set(sort_by_inserted, 0, _("Received"));

        var sort_by_box = new Gtk.ComboBox.with_model(sort_liststore);
        var sort_renderer = new Gtk.CellRendererText();
        sort_by_box.pack_start(sort_renderer, false);
        sort_by_box.add_attribute(sort_renderer, "text", 0);
        sort_by_box.changed.connect(() => {
            if(sort_by_box.get_active() == 0)
                settings_general.set_boolean("articlelist-sort-by-date", true);
            else if(sort_by_box.get_active() == 1)
                settings_general.set_boolean("articlelist-sort-by-date", false);

            newArticleList();
        });
        if(settings_general.get_boolean("articlelist-sort-by-date"))
            sort_by_box.set_active(0);
        else
            sort_by_box.set_active(1);
        article_sort_box.pack_start(article_sort, true, true, 0);
        article_sort_box.pack_end(sort_by_box, false, false, 0);
        m_uiBox.pack_start(article_sort_box, false, true, 0);

        var newest_first_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var newest_first = new Gtk.Label(_("Newest first"));
        newest_first.set_alignment(0, 0.5f);
        newest_first.margin_start = 15;
        var newest_first_switch = new Gtk.Switch();
        newest_first_switch.active = settings_general.get_boolean("articlelist-newest-first");
        newest_first_switch.notify["active"].connect(() => {
            settings_general.set_boolean("articlelist-newest-first",  newest_first_switch.active);
            newArticleList();
        });
        newest_first_box.pack_start(newest_first, true, true, 0);
        newest_first_box.pack_end(newest_first_switch, false, false, 0);
        m_uiBox.pack_start(newest_first_box, false, true, 0);
    }


    private void setup_articleview_settings()
    {
        var articleview_settings = new Gtk.Label(_("Article View:"));
        articleview_settings.margin_top = 15;
        articleview_settings.set_alignment(0, 0.5f);
        articleview_settings.get_style_context().add_class("h4");
        m_uiBox.pack_start(articleview_settings, false, true, 0);

        var article_theme_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var article_theme = new Gtk.Label(_("Theme"));
        article_theme.set_alignment(0, 0.5f);
        article_theme.margin_start = 15;

        var theme_liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter default;
        theme_liststore.append(out default);
        theme_liststore.set(default, 0, _("Default"));
		Gtk.TreeIter spring;
        theme_liststore.append(out spring);
        theme_liststore.set(spring, 0, _("Spring"));
        Gtk.TreeIter midnight;
        theme_liststore.append(out midnight);
        theme_liststore.set(midnight, 0, _("Midnight"));
        Gtk.TreeIter parchment;
        theme_liststore.append(out parchment);
        theme_liststore.set(parchment, 0, _("Parchment"));

        var theme_box = new Gtk.ComboBox.with_model(theme_liststore);
        var theme_renderer = new Gtk.CellRendererText();
        theme_box.pack_start(theme_renderer, false);
        theme_box.add_attribute(theme_renderer, "text", 0);
        theme_box.changed.connect(() => {
            settings_general.set_enum("article-theme", theme_box.get_active());
            reloadArticleView();
        });

        switch(settings_general.get_enum("article-theme"))
		{
			case ArticleTheme.DEFAULT:
                theme_box.set_active(0);
				break;

			case ArticleTheme.SPRING:
                theme_box.set_active(1);
				break;

			case ArticleTheme.MIDNIGHT:
                theme_box.set_active(2);
				break;

			case ArticleTheme.PARCHMENT:
                theme_box.set_active(3);
				break;
		}

        article_theme_box.pack_start(article_theme, true, true, 0);
        article_theme_box.pack_end(theme_box, false, false, 0);
        m_uiBox.pack_start(article_theme_box, false, true, 0);
    }

    private void setup_sync_settings()
    {
        var sync_settings = new Gtk.Label(_("Sync:"));
        sync_settings.margin_top = 15;
        sync_settings.set_alignment(0, 0.5f);
        sync_settings.get_style_context().add_class("h4");
        m_internalsBox.pack_start(sync_settings, false, true, 0);

        var sync_count_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var sync_count = new Gtk.Label(_("Number of articles"));
        sync_count.set_alignment(0, 0.5f);
        sync_count.margin_start = 15;
        var sync_count_button = new Gtk.SpinButton.with_range(10, 1000, 10);
        sync_count_button.set_value(settings_general.get_int("max-articles"));
        sync_count_button.value_changed.connect(() => {
            settings_general.set_int("max-articles", sync_count_button.get_value_as_int());
        });
        sync_count_box.pack_start(sync_count, true, true, 0);
        sync_count_box.pack_end(sync_count_button, false, false, 0);
        m_internalsBox.pack_start(sync_count_box, false, true, 0);

        var sync_time_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var sync_time = new Gtk.Label(_("Every (seconds)"));
        sync_time.set_alignment(0, 0.5f);
        sync_time.margin_start = 15;
        var sync_time_button = new Gtk.SpinButton.with_range(60, 1080, 10);
        sync_time_button.set_value(settings_general.get_int("sync"));
        sync_time_button.value_changed.connect(() => {
            settings_general.set_int("sync", sync_time_button.get_value_as_int());
        });
        sync_time_box.pack_start(sync_time, true, true, 0);
        sync_time_box.pack_end(sync_time_button, false, false, 0);
        m_internalsBox.pack_start(sync_time_box, false, true, 0);
    }


    private void setup_db_settings()
    {
        var db_settings = new Gtk.Label(_("Database:"));
        db_settings.margin_top = 15;
        db_settings.set_alignment(0, 0.5f);
        db_settings.get_style_context().add_class("h4");
        m_internalsBox.pack_start(db_settings, false, true, 0);

        var drop_articles_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var drop_articles = new Gtk.Label(_("Drop articles after"));
        drop_articles.set_alignment(0, 0.5f);
        drop_articles.margin_start = 15;

        var drop_liststore = new Gtk.ListStore(1, typeof(string));
		Gtk.TreeIter never;
        drop_liststore.append(out never);
        drop_liststore.set(never, 0, _("Never"));
		Gtk.TreeIter week;
        drop_liststore.append(out week);
        drop_liststore.set(week, 0, _("1 Week"));
        Gtk.TreeIter month;
        drop_liststore.append(out month);
        drop_liststore.set(month, 0, _("1 Month"));
        Gtk.TreeIter half_year;
        drop_liststore.append(out half_year);
        drop_liststore.set(half_year, 0, _("6 Months"));

        var drop_box = new Gtk.ComboBox.with_model(drop_liststore);
        var drop_renderer = new Gtk.CellRendererText();
        drop_box.pack_start(drop_renderer, false);
        drop_box.add_attribute(drop_renderer, "text", 0);
        drop_box.changed.connect(() => {
            settings_general.set_enum("drop-articles-after", drop_box.get_active());
        });

        switch(settings_general.get_enum("drop-articles-after"))
		{
			case DropArticles.NEVER:
                drop_box.set_active(0);
				break;

			case DropArticles.ONE_WEEK:
                drop_box.set_active(1);
				break;

			case DropArticles.ONE_MONTH:
                drop_box.set_active(2);
				break;

			case DropArticles.SIX_MONTHS:
                drop_box.set_active(3);
				break;
		}

        drop_articles_box.pack_start(drop_articles, true, true, 0);
        drop_articles_box.pack_end(drop_box, false, false, 0);
        m_internalsBox.pack_start(drop_articles_box, false, true, 0);
    }


    private void setup_addfunc_settings()
    {
        var service_settings = new Gtk.Label(_("Additional Functionality:"));
        service_settings.margin_top = 15;
        service_settings.set_alignment(0, 0.5f);
        service_settings.get_style_context().add_class("h4");
        m_internalsBox.pack_start(service_settings, false, true, 0);

        var grabber_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var grabber = new Gtk.Label(_("Content Grabber"));
        grabber.set_alignment(0, 0.5f);
        grabber.margin_start = 15;

        var grabber_liststore = new Gtk.ListStore(1, typeof(string));
		Gtk.TreeIter none;
        grabber_liststore.append(out none);
        grabber_liststore.set(none, 0, _("None"));
		Gtk.TreeIter builtin;
        grabber_liststore.append(out builtin);
        grabber_liststore.set(builtin, 0, _("Built in grabber"));
        //Gtk.TreeIter readability;
        //grabber_liststore.append(out readability);
        //grabber_liststore.set(readability, 0, _("Readability.com"));

        var grabber_dropbox = new Gtk.ComboBox.with_model(grabber_liststore);
        var grabber_renderer = new Gtk.CellRendererText();
        grabber_dropbox.pack_start(grabber_renderer, false);
        grabber_dropbox.add_attribute(grabber_renderer, "text", 0);
        grabber_dropbox.changed.connect(() => {
            settings_general.set_enum("content-grabber", grabber_dropbox.get_active());
        });

        switch(settings_general.get_enum("content-grabber"))
		{
			case ContentGrabber.NONE:
            grabber_dropbox.set_active(0);
				break;

			case ContentGrabber.BUILTIN:
            grabber_dropbox.set_active(1);
				break;

			//case ContentGrabber.READABILITY:
            //grabber_dropbox.set_active(2);
			//	break;
		}

        grabber_box.pack_start(grabber, true, true, 0);
        grabber_box.pack_end(grabber_dropbox, false, false, 0);
        m_internalsBox.pack_start(grabber_box, false, true, 0);
    }

    private void setup_service_settings()
    {
        var service_list = new Gtk.ListBox();
        service_list.set_selection_mode(Gtk.SelectionMode.NONE);

        var service_scroll = new Gtk.ScrolledWindow(null, null);
        service_scroll.expand = true;
        service_scroll.margin_top = 10;
        service_scroll.margin_bottom = 10;

        var viewport = new Gtk.Viewport (null, null);
        viewport.get_style_context().add_class("servicebox");
        viewport.add(service_list);
        service_scroll.add(viewport);

        var readabilityRow = new ServiceRow("Readability.com", OAuth.READABILITY);
        var pocketRow = new ServiceRow("Pocket", OAuth.POCKET);
        var instaRow = new ServiceRow("Instapaper", OAuth.INSTAPAPER);
        service_list.insert(readabilityRow, -1);
        service_list.insert(pocketRow, -1);
        service_list.insert(instaRow, -1);
        m_serviceBox.pack_start(service_scroll, false, true, 0);
    }
}
