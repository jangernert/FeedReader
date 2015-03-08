public class FeedReader.ResetPage : Gtk.Bin {

	private Gtk.Box m_layout;
	private Gtk.Button m_newAccountButton;
	private Gtk.Label m_deleteLabel;
	private Gtk.Box m_waitingBox;
	private bool m_reset;
	private Gtk.Spinner m_spinner;
	public signal void cancel();
	public signal void reset();

	public ResetPage()
	{
		m_reset = false;
		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_layout.set_size_request(700, 410);

		var titleText = new Gtk.Label(_("Change Account?"));
		titleText.get_style_context().add_class("h1");
		titleText.set_justify(Gtk.Justification.CENTER);

		var describtionText = new Gtk.Label(_("You are about to change the account you want FeedReader to use.\n This means deleting all local data of your old account."));
		describtionText.get_style_context().add_class("h2");
		describtionText.set_justify(Gtk.Justification.CENTER);

		m_deleteLabel = new Gtk.Label("New account");
		m_waitingBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		m_spinner = new Gtk.Spinner();
		var waitingLabel = new Gtk.Label("Waiting for current sync to finish");
		m_waitingBox.pack_start(m_spinner, false, false, 0);
		m_waitingBox.pack_start(waitingLabel, false, true, 0);

		var buttonBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_newAccountButton = new Gtk.Button();
		m_newAccountButton.add(m_deleteLabel);
		m_newAccountButton.set_size_request(80, 30);
		m_newAccountButton.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
		m_newAccountButton.clicked.connect(resetAllData);
		var cancelButton = new Gtk.Button.with_label("I changed my mind");
		cancelButton.set_size_request(80, 30);
		cancelButton.clicked.connect(abortReset);
		buttonBox.pack_start(cancelButton, false, false, 0);
		buttonBox.pack_end(m_newAccountButton, false, false, 0);

		m_layout.pack_start(titleText, false, true, 0);
		m_layout.pack_start(describtionText, true, true, 0);
		m_layout.pack_end(buttonBox, false, true, 0);


		this.set_halign(Gtk.Align.CENTER);
		this.set_valign(Gtk.Align.CENTER);
		this.margin = 20;
		this.add(m_layout);
		this.show_all();
	}


	private void resetAllData()
	{
		m_reset = true;
		m_newAccountButton.remove(m_deleteLabel);
		m_newAccountButton.add(m_waitingBox);
		m_waitingBox.show_all();
		m_spinner.start();
		m_newAccountButton.set_sensitive(false);

		while(settings_state.get_boolean("currently-updating"))
		{
			Gtk.main_iteration();
		}

		if(!m_reset)
			return;

		// set "currently-updating" ourself to prevent the daemon to start sync
		settings_state.set_boolean("currently-updating", true);

		//dataBase.resetDB();
		string db_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feedreader-02.db";
		string wal_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feedreader-02.db-wal";
		string shm_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feedreader-02.db-shm";
		var db = File.new_for_path (db_path);
		var wal = File.new_for_path (wal_path);
		var shm = File.new_for_path (shm_path);

		try {
			db.delete();
			wal.delete();
			shm.delete();
		}
		catch (Error e) {
			logger.print(LogMessage.ERROR, e.message);
		}

		dataBase = new dbManager();
		dataBase.init();

		resetSettings(settings_general);
		resetSettings(settings_state);
		resetSettings(settings_feedly);
		resetSettings(settings_ttrss);

		settings_state.set_boolean("currently-updating", false);
		reset();
	}

	private void resetSettings(GLib.Settings settings)
	{
		var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}
	}

	private void abortReset()
	{
		m_reset = false;
		m_newAccountButton.remove(m_waitingBox);
		m_newAccountButton.add(m_deleteLabel);
		m_deleteLabel.show_all();
		m_newAccountButton.set_sensitive(true);
		cancel();
	}


}
