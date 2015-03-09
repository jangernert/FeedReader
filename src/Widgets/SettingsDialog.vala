public class FeedReader.SettingsDialog : Gtk.Dialog {

    public signal void newFeedList();

    public SettingsDialog(Gtk.Window parent)
    {
        this.title = "Settings";
		this.border_width = 20;
        this.set_transient_for(parent);
        this.set_modal(true);
		set_default_size (450, 500);

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

        var feed_settings = new Gtk.Label("Feed List:");
        feed_settings.set_alignment(0, 0.5f);
        feed_settings.get_style_context().add_class("h4");
        content.pack_start(feed_settings, false, true, 0);

        var box1 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_feeds = new Gtk.Label("only show Feeds");
        only_feeds.set_alignment(0, 0.5f);
        only_feeds.margin_start = 15;
        var only_feeds_switch = new Gtk.Switch();
        only_feeds_switch.active = settings_general.get_boolean("only-feeds");
        only_feeds_switch.notify["active"].connect(() => {
            settings_state.set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
            settings_general.set_boolean("only-feeds",  only_feeds_switch.active);
            newFeedList();
        });
        box1.pack_start(only_feeds, true, true, 0);
        box1.pack_end(only_feeds_switch, false, false, 0);
        content.pack_start(box1, false, true, 5);

        var box2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_unread = new Gtk.Label("only show unread");
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


        var sync_settings = new Gtk.Label("Sync:");
        sync_settings.set_alignment(0, 0.5f);
        sync_settings.get_style_context().add_class("h4");
        content.pack_start(sync_settings, false, true, 5);

        var box3 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var sync_count = new Gtk.Label("number of articles");
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
        var sync_time = new Gtk.Label("every (seconds)");
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

        this.add_button(_("Close"), 1);
        show_all();
    }
}
