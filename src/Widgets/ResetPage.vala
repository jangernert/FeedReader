public class FeedReader.ResetPage : Gtk.Alignment {
	
	private Gtk.Box m_layout;
	public signal void cancel();
	public signal void reset();

	public ResetPage()
	{
		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_layout.set_size_request(700, 410);
	
		var titleText = new Gtk.Label(_("Change Account?"));
		titleText.get_style_context().add_class("h1");
		titleText.set_justify(Gtk.Justification.CENTER);
		
		var describtionText = new Gtk.Label(_("You are about to change the account you want FeedReader to use.\n This means deleting all local data of your old account."));
		describtionText.get_style_context().add_class("h2");
		describtionText.set_justify(Gtk.Justification.CENTER);
		
		var buttonBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		var newAccountButton = new Gtk.Button.with_label("New account");
		newAccountButton.set_size_request(80, 30);
		newAccountButton.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
		newAccountButton.clicked.connect(resetAllData);
		var cancelButton = new Gtk.Button.with_label("I changed my mind");
		cancelButton.set_size_request(80, 30);
		cancelButton.clicked.connect(() => {
			cancel();
		});
		buttonBox.pack_start(cancelButton, false, false, 0);
		buttonBox.pack_end(newAccountButton, false, false, 0);
		
		m_layout.pack_start(titleText, false, true, 0);
		m_layout.pack_start(describtionText, true, true, 0);
		m_layout.pack_end(buttonBox, false, true, 0);
		
		
		this.@set(0.5f, 0.5f, 0.0f, 0.0f);
		this.set_padding(20, 20, 20, 20);
		this.add(m_layout);
		this.show_all();
	}
	
	
	private void resetAllData()
	{
		if(settings_state.get_boolean("currently-updating") == false)
		{
			//dataBase.resetDB();
			//dataBase.init();
		
			//resetSettings(settings_general);
			//resetSettings(settings_state);
			//resetSettings(settings_feedly);
			//resetSettings(settings_ttrss);
		
			reset();
		}
	}
	
	private void resetSettings(GLib.Settings settings)
	{
		var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}
	}
	
	
}
