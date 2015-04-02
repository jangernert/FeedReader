public class FeedReader.InitSyncPage : Gtk.Bin {

	private Gtk.Spinner m_spinner;
	private Gtk.Box m_spinnerBox;
	private Gtk.Box m_layout;
	private Gtk.Grid m_grid;
	private Gtk.Label m_tags;
	private Gtk.Label m_feeds;
	public signal void finished();

	public InitSyncPage() {
		m_spinnerBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);

		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(40, 40);
		m_spinner.start();

		var label = new Gtk.Label(_("FeedReader is now getting the first batch of articles.\nDepending on your connection and settings this can take some time."));
		label.get_style_context().add_class("h2");
		label.set_alignment(0, 0.5f);
		label.set_ellipsize (Pango.EllipsizeMode.END);
		label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		label.set_line_wrap(true);
		label.set_lines(2);

		m_grid = new Gtk.Grid();
		m_grid.set_column_homogeneous(false);
		m_grid.set_column_spacing(10);
		m_grid.set_row_spacing(5);
		m_grid.set_halign(Gtk.Align.CENTER);
		m_grid.set_size_request(400, 0);

		var label2 = new Gtk.Label("Categories");
		label2.get_style_context().add_class("h3");
		label2.set_alignment(0, 0.5f);
		label2.set_hexpand(true);

		var label3 = new Gtk.Label("Feeds");
		label3.get_style_context().add_class("h3");
		label3.set_alignment(0, 0.5f);

		var label4 = new Gtk.Label("Tags");
		label4.get_style_context().add_class("h3");
		label4.set_alignment(0, 0.5f);

		var label5 = new Gtk.Label("all unread Articles");
		label5.get_style_context().add_class("h3");
		label5.set_alignment(0, 0.5f);

		var label6 = new Gtk.Label("%i starred Articles".printf(settings_general.get_int("max-articles")));
		label6.get_style_context().add_class("h3");
		label6.set_alignment(0, 0.5f);

		var label7 = new Gtk.Label("%i Articles for each Tag".printf(settings_general.get_int("max-articles")/4));
		label7.get_style_context().add_class("h3");
		label7.set_alignment(0, 0.5f);

		m_tags = new Gtk.Label("");
		m_tags.get_style_context().add_class("h3");
		m_tags.set_alignment(0, 0.5f);
		m_tags.set_ellipsize (Pango.EllipsizeMode.MIDDLE);
		m_tags.set_size_request(150, 0);

		var label8 = new Gtk.Label("%i Articles for each Feed".printf(settings_general.get_int("max-articles")/4));
		label8.get_style_context().add_class("h3");
		label8.set_alignment(0, 0.5f);

		m_feeds = new Gtk.Label("");
		m_feeds.get_style_context().add_class("h3");
		m_feeds.set_alignment(0, 0.5f);
		m_feeds.set_ellipsize (Pango.EllipsizeMode.MIDDLE);

		for(int i = 1; i < 8; i++)
		{
			m_grid.attach(new Gtk.Label("%i.".printf(i)), 0, i-1, 1, 1);
			m_grid.attach(new Gtk.Image.from_icon_name("dialog-apply", Gtk.IconSize.MENU), 3, i-1, 1, 1);
		}

		m_grid.attach(label2, 1, 0, 1, 1);
		m_grid.attach(label3, 1, 1, 1, 1);
		m_grid.attach(label4, 1, 2, 1, 1);
		m_grid.attach(label5, 1, 3, 1, 1);
		m_grid.attach(label6, 1, 4, 1, 1);
		m_grid.attach(label7, 1, 5, 1, 1);
		m_grid.attach(label8, 1, 6, 1, 1);

		m_grid.attach(m_tags, 2, 5, 1, 1);
		m_grid.attach(m_feeds, 2, 6, 1, 1);

		m_spinnerBox.pack_start(m_spinner, false, true, 0);
		m_spinnerBox.pack_start(label, false, true, 0);

		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 50);
		m_layout.pack_start(m_spinnerBox, false, true, 0);
		m_layout.pack_start(m_grid, false, true, 0);

		this.set_halign(Gtk.Align.CENTER);
		this.set_valign(Gtk.Align.CENTER);
		this.margin = 20;
		this.add(m_layout);


		feedDaemon_interface.initSyncStage.connect((stage) => {
			logger.print(LogMessage.DEBUG, "InitSyncPage: stage %i".printf(stage));
			setStage(stage);
		});

		feedDaemon_interface.initSyncTag.connect((tagName) => {
			setCurrentTag(tagName);
		});

		feedDaemon_interface.initSyncFeed.connect((feedName) => {
			setCurrentFeed(feedName);
		});

		if(settings_state.get_int("initial-sync-level") != 0)
		{
			setStage(settings_state.get_int("initial-sync-level"));
		}
	}


	public void start()
	{
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 2, () => {
			try{
				feedDaemon_interface.startInitSync();
			}catch (IOError e) {
				logger.print(LogMessage.ERROR, e.message);
			}
			return false;
		});
	}

	private void setCurrentTag(string tag)
	{
		if(tag == "")
		{
			m_tags.set_text("");
			return;
		}

		m_tags.set_text("(%s)".printf(tag));
	}

	private void setCurrentFeed(string feed)
	{
		if(feed == "")
		{
			m_feeds.set_text("");
			return;
		}

		m_feeds.set_text("(%s)".printf(feed));
	}

	private void setStage(int stage)
	{
		settings_state.set_int("initial-sync-level", stage);
		for(int i = 0; i < stage; ++i)
		{
			m_grid.get_child_at(3, i).show();
		}
	}

	public void hideChecks()
	{
		for(int i = 1; i < 8; i++)
		{
			m_grid.get_child_at(3, i-1).hide();
		}
	}
}
