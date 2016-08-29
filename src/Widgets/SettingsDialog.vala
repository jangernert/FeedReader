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
    public signal void newArticleList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE);
    public signal void reloadArticleView();
    public signal void reloadCSS();

    public SettingsDialog(Gtk.Window parent, string show)
    {
    	Object(use_header_bar: 1);
        this.title = _("Settings");
		this.border_width = 20;
        this.set_transient_for(parent);
        this.set_modal(true);
		set_default_size(550, 550);

        var stack = new Gtk.Stack();
        stack.set_transition_duration(50);
        stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
        stack.set_halign(Gtk.Align.FILL);
        stack.add_titled(setup_UI(), "ui", _("Interface"));
        stack.add_titled(setup_Internal(), "internal", _("Internals"));
        stack.add_titled(setup_Service(), "service", _("Share"));

		Gtk.StackSwitcher switcher = new Gtk.StackSwitcher();
        switcher.set_halign(Gtk.Align.CENTER);
        switcher.set_valign(Gtk.Align.CENTER);
        switcher.set_stack(stack);

        var content = get_content_area() as Gtk.Box;
        content.set_spacing(2);
        content.pack_start(switcher, false, false, 0);
        content.add(stack);
        this.show_all();

        stack.set_visible_child_name(show);
    }


    private Gtk.Box setup_UI()
    {
        var feed_settings = headline(_("Feed List:"));

        var only_feeds = new SettingSwitch(_("Only show feeds"), settings_general, "only-feeds");
        only_feeds.changed.connect(() => {
        	settings_state.set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
        	settings_state.set_string("feedlist-selected-row", "feed -4");
        	newFeedList(true);
        });

        var only_unread = new SettingSwitch(_("Only show unread"), settings_general, "feedlist-only-show-unread");
        only_unread.changed.connect(() => {
        	newFeedList();
        });

		var feedlist_sort = new SettingDropbox(_("Sort FeedList by"), settings_general, "feedlist-sort-by", {_("Received"), _("Alphabetically")});
        feedlist_sort.changed.connect(() => {
        	newFeedList();
        });

        var feedlist_theme = new SettingDropbox(_("Theme"), settings_general, "feedlist-theme", {_("Gtk+"), _("Dark"), _("elementary")});
        feedlist_theme.changed.connect(() => {
        	reloadCSS();
        });

        var article_settings = headline(_("Article List:"));

        var article_sort = new SettingDropbox(_("Sort articles by"), settings_general, "articlelist-sort-by", {_("Received"), _("Date")});
        article_sort.changed.connect(() => {
        	newArticleList();
        });

        var newest_first = new SettingSwitch(_("Newest first"), settings_general, "articlelist-newest-first");
        newest_first.changed.connect(() => {
        	newArticleList();
        });

        var articleview_settings = headline(_("Article View:"));

        var article_theme = new SettingDropbox(_("Theme"), settings_general, "article-theme", {_("Default"), _("Spring"), _("Midnight"), _("Parchment")});
		article_theme.changed.connect(() => {
			reloadArticleView();
		});

        var fontsize = new SettingDropbox(_("Font Size"), settings_general, "fontsize", {_("Small"), _("Normal"), _("Large"), _("Huge")});
		fontsize.changed.connect(() => {
			reloadArticleView();
		});


		var uiBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        uiBox.expand = true;
        uiBox.pack_start(feed_settings, false, true, 0);
		uiBox.pack_start(only_feeds, false, true, 0);
		uiBox.pack_start(only_unread, false, true, 0);
        uiBox.pack_start(feedlist_sort, false, true, 0);
        uiBox.pack_start(feedlist_theme, false, true, 0);
        uiBox.pack_start(article_settings, false, true, 0);
        uiBox.pack_start(article_sort, false, true, 0);
        uiBox.pack_start(newest_first, false, true, 0);
        uiBox.pack_start(articleview_settings, false, true, 0);
        uiBox.pack_start(article_theme, false, true, 0);
        uiBox.pack_start(fontsize, false, true, 0);

        return uiBox;
    }


    private Gtk.Box setup_Internal()
    {
		var sync_settings = headline(_("Sync:"));

		var sync_count = new SettingSpin(_("Number of articles"), settings_general, "max-articles", 10, 5000, 10);

		var sync_time = new SettingSpin(_("Every (Minutes)"), settings_general, "sync", 5, 600, 5);
		sync_time.changed.connect(() => {
			feedDaemon_interface.scheduleSync(settings_general.get_int("sync"));
		});

		var db_settings = headline(_("Database:"));

        var drop_articles = new SettingDropbox(_("Delete articles after"), settings_general, "drop-articles-after",
												{_("Never"), _("1 Week"), _("1 Month"), _("6 Months")});

		var service_settings = headline(_("Additional Functionality:"));

        var grabber = new SettingSwitch(_("Content Grabber"), settings_general,"content-grabber");

        var mediaplayer = new SettingSwitch(_("Internal Media Player"), settings_general,"mediaplayer");


    	var internalsBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        internalsBox.expand = true;
        internalsBox.pack_start(sync_settings, false, true, 0);
        if(feedDaemon_interface.useMaxArticles())
		      internalsBox.pack_start(sync_count, false, true, 0);
    	internalsBox.pack_start(sync_time, false, true, 0);
    	internalsBox.pack_start(db_settings, false, true, 0);
        internalsBox.pack_start(drop_articles, false, true, 0);
        internalsBox.pack_start(service_settings, false, true, 0);
        internalsBox.pack_start(grabber, false, true, 0);
        internalsBox.pack_start(mediaplayer, false, true, 0);

		return internalsBox;
    }


    private Gtk.Box setup_Service()
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

        var list = share.getAccounts();

        foreach(var account in list)
        {
            if(share.needSetup(account.getID()))
            {
                ServiceSetup row = share.newSetup_withID(account.getID());
    			row.removeRow.connect(() => {
    				removeRow(row, service_list);
    			});
    			service_list.add(row);
    			row.reveal();
            }
        }

        var addAccount = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.DND);
        addAccount.set_relief(Gtk.ReliefStyle.NONE);
        addAccount.get_style_context().add_class("addServiceButton");
        addAccount.set_size_request(0, 48);
		service_list.add(addAccount);

		addAccount.clicked.connect(() => {
			var children = service_list.get_children();
			foreach(Gtk.Widget row in children)
			{
				var tmpRow = row as ServiceSetup;
				if(tmpRow != null && !tmpRow.isLoggedIn())
				{
					share.deleteAccount(tmpRow.getID());
					removeRow(tmpRow, service_list);
				}
			}

			var popover = new ServiceSettingsPopover(addAccount);
			popover.newAccount.connect((type) => {
                ServiceSetup row = share.newSetup(type);
    			row.removeRow.connect(() => {
    				removeRow(row, service_list);
    			});
    			service_list.insert(row, 0);
    			row.reveal();
			});
		});

    	var serviceBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        serviceBox.expand = true;
        serviceBox.pack_start(service_scroll, false, true, 0);

        return serviceBox;
    }


    private Gtk.Label headline(string name)
    {
    	var headline = new Gtk.Label(name);
        headline.margin_top = 15;
        headline.set_alignment(0, 0.5f);
        headline.get_style_context().add_class("bold");
        return headline;
    }

    public void removeRow(ServiceSetup row, Gtk.ListBox list)
	{
		row.unreveal();
		GLib.Timeout.add(700, () => {
		    list.remove(row);
			return false;
		});
	}
}
