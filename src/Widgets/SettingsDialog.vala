public class FeedReader.SettingsDialog : Gtk.Dialog {

    public signal void newFeedList(bool defaultSettings = false);
    public signal void newArticleList();
    public signal void reloadArticleView();

    public SettingsDialog(Gtk.Window parent)
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

        var feed_settings = new Gtk.Label(_("Feed List:"));
        feed_settings.set_alignment(0, 0.5f);
        feed_settings.get_style_context().add_class("h4");
        content.pack_start(feed_settings, false, true, 0);

        var box1 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_feeds = new Gtk.Label("only show Feeds");
        only_feeds.set_alignment(0, 0.5f);
        only_feeds.margin_start = 15;
        var only_feeds_switch = new Gtk.Switch();
        only_feeds_switch.active = settings_general.get_boolean(_("only-feeds"));
        only_feeds_switch.notify["active"].connect(() => {
            settings_state.set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
            settings_state.set_string("feedlist-selected-row", "feed -4");
            settings_general.set_boolean("only-feeds",  only_feeds_switch.active);
            newFeedList(true);
        });
        box1.pack_start(only_feeds, true, true, 0);
        box1.pack_end(only_feeds_switch, false, false, 0);
        content.pack_start(box1, false, true, 5);

        var box2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_unread = new Gtk.Label(_("only show unread"));
        only_unread.set_alignment(0, 0.5f);
        only_unread.margin_start = 15;
        var only_unread_switch = new Gtk.Switch();
        only_unread_switch.active = settings_general.get_boolean("feedlist-only-show-unread");
        only_unread_switch.notify["active"].connect(() => {
            settings_general.set_boolean("feedlist-only-show-unread",  only_unread_switch.active);
            newFeedList();
        });
        box2.pack_start(only_unread, true, true, 0);
        box2.pack_end(only_unread_switch, false, false, 0);
        content.pack_start(box2, false, true, 0);


        var sync_settings = new Gtk.Label(_("Sync:"));
        sync_settings.set_alignment(0, 0.5f);
        sync_settings.get_style_context().add_class("h4");
        content.pack_start(sync_settings, false, true, 5);

        var box3 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var sync_count = new Gtk.Label(_("number of articles"));
        sync_count.set_alignment(0, 0.5f);
        sync_count.margin_start = 15;
        var sync_count_button = new Gtk.SpinButton.with_range(10, 1000, 10);
        sync_count_button.set_value(settings_general.get_int("max-articles"));
        sync_count_button.value_changed.connect(() => {
            settings_general.set_int("max-articles", sync_count_button.get_value_as_int());
        });
        box3.pack_start(sync_count, true, true, 0);
        box3.pack_end(sync_count_button, false, false, 0);
        content.pack_start(box3, false, true, 0);

        var box4 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var sync_time = new Gtk.Label(_("every (seconds)"));
        sync_time.set_alignment(0, 0.5f);
        sync_time.margin_start = 15;
        var sync_time_button = new Gtk.SpinButton.with_range(60, 1080, 10);
        sync_time_button.set_value(settings_general.get_int("sync"));
        sync_time_button.value_changed.connect(() => {
            settings_general.set_int("sync", sync_time_button.get_value_as_int());
        });
        box4.pack_start(sync_time, true, true, 0);
        box4.pack_end(sync_time_button, false, false, 0);
        content.pack_start(box4, false, true, 5);

        var article_settings = new Gtk.Label(_("ArticleList:"));
        article_settings.set_alignment(0, 0.5f);
        article_settings.get_style_context().add_class("h4");
        content.pack_start(article_settings, false, true, 5);

        var box5 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var article_sort = new Gtk.Label(_("sort articles by"));
        article_sort.set_alignment(0, 0.5f);
        article_sort.margin_start = 15;

        var sort_liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter sort_by_date;
        sort_liststore.append(out sort_by_date);
        sort_liststore.set(sort_by_date, 0, _("date"));
		Gtk.TreeIter sort_by_inserted;
        sort_liststore.append(out sort_by_inserted);
        sort_liststore.set(sort_by_inserted, 0, _("received"));

        var sort_by_box = new Gtk.ComboBox.with_model(sort_liststore);
        var sort_renderer = new Gtk.CellRendererText();
        sort_by_box.pack_start (sort_renderer, false);
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
        box5.pack_start(article_sort, true, true, 0);
        box5.pack_end(sort_by_box, false, false, 0);
        content.pack_start(box5, false, true, 5);

        var box6 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var newest_first = new Gtk.Label(_("newest first"));
        newest_first.set_alignment(0, 0.5f);
        newest_first.margin_start = 15;
        var newest_first_switch = new Gtk.Switch();
        newest_first_switch.active = settings_general.get_boolean("articlelist-newest-first");
        newest_first_switch.notify["active"].connect(() => {
            settings_general.set_boolean("articlelist-newest-first",  newest_first_switch.active);
            newArticleList();
        });
        box6.pack_start(newest_first, true, true, 0);
        box6.pack_end(newest_first_switch, false, false, 0);
        content.pack_start(box6, false, true, 0);


        var articleview_settings = new Gtk.Label(_("ArticleView:"));
        articleview_settings.set_alignment(0, 0.5f);
        articleview_settings.get_style_context().add_class("h4");
        content.pack_start(articleview_settings, false, true, 5);

        var box7 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var article_theme = new Gtk.Label(_("Theme"));
        article_theme.set_alignment(0, 0.5f);
        article_theme.margin_start = 15;

        var theme_liststore = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter default;
        theme_liststore.append(out default);
        theme_liststore.set(default, 0, _("default"));
		Gtk.TreeIter spring;
        theme_liststore.append(out spring);
        theme_liststore.set(spring, 0, _("spring"));
        Gtk.TreeIter midnight;
        theme_liststore.append(out midnight);
        theme_liststore.set(midnight, 0, _("midnight"));
        Gtk.TreeIter parchment;
        theme_liststore.append(out parchment);
        theme_liststore.set(parchment, 0, _("parchment"));

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


        box7.pack_start(article_theme, true, true, 0);
        box7.pack_end(theme_box, false, false, 0);
        content.pack_start(box7, false, true, 5);

        this.add_button(_("Close"), 1);
        show_all();
    }
}
