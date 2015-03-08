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
        only_feeds_switch.set_state(settings_general.get_boolean("only-feeds"));
        only_feeds_switch.state_set.connect((state) => {
            settings_state.set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
            settings_general.set_boolean("only-feeds",  state);
            newFeedList();
            return false;
        });
        box1.pack_start(only_feeds, true, true, 0);
        box1.pack_end(only_feeds_switch, false, false, 0);
        content.pack_start(box1, false, true, 5);

        var box2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var only_unread = new Gtk.Label("only show unread");
        only_unread.set_alignment(0, 0.5f);
        only_unread.margin_start = 15;
        var only_unread_switch = new Gtk.Switch();
        only_unread_switch.set_state(settings_general.get_boolean("feedlist-only-show-unread"));
        only_unread_switch.state_set.connect((state) => {
            settings_general.set_boolean("feedlist-only-show-unread",  state);
            newFeedList();
            return false;
        });
        box2.pack_start(only_unread, true, true, 0);
        box2.pack_end(only_unread_switch, false, false, 0);
        content.pack_start(box2, false, true, 0);

        this.add_button(_("Close"), 1);
        show_all();
    }
}
