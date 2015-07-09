public class FeedReader.ServiceRow : baseRow {

	private string m_name;
    private OAuth m_type;
    private Gtk.Label m_label;
    private Gtk.Box m_box;
	private Gtk.Stack m_stack;
    private Gtk.Button m_login_button;
	private Gtk.Revealer m_revealer;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passEntry;

	public ServiceRow(string serviceName, OAuth type)
	{
		m_name = serviceName;
        m_type = type;
		m_stack = new Gtk.Stack();
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		string iconPath = "";
		GLib.Settings serviceSettings = settings_readability;

		//------------------------------------------------
		// XAuth revealer
		//------------------------------------------------
		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);
		grid.margin_bottom = 10;
		grid.margin_top = 5;

        m_userEntry = new Gtk.Entry();
        m_passEntry = new Gtk.Entry();
		m_passEntry.set_invisible_char('*');
		m_passEntry.set_visibility(false);

		m_userEntry.activate.connect(() => {
			m_passEntry.grab_focus();
		});

		m_passEntry.activate.connect(() => {
			login();
		});

        grid.attach(new Gtk.Label(_("Username:")), 0, 0);
        grid.attach(new Gtk.Label(_("Password:")), 0, 1);
        grid.attach(m_userEntry, 1, 0);
        grid.attach(m_passEntry, 1, 1);
		m_revealer.add(grid);
		//------------------------------------------------

        m_login_button = new Gtk.Button.with_label(_("Login"));
        m_login_button.hexpand = false;
        m_login_button.margin = 10;
        m_login_button.clicked.connect(login);

		var loggedIN = new Gtk.Image.from_icon_name("dialog-apply", Gtk.IconSize.LARGE_TOOLBAR);

		m_stack.add_named(m_login_button, "button");
		m_stack.add_named(loggedIN, "loggedIN");

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.set_size_request(0, 50);

		switch (m_type)
        {
            case OAuth.READABILITY:
                iconPath = "/usr/share/FeedReader/readability.svg";
				serviceSettings = settings_readability;
                break;

            case OAuth.INSTAPAPER:
                iconPath = "/usr/share/FeedReader/instapaper.svg";
				serviceSettings = settings_instapaper;
                break;

            case OAuth.POCKET:
                iconPath = "/usr/share/FeedReader/pocket.svg";
				serviceSettings = settings_pocket;
                break;
        }

        var icon = new Gtk.Image.from_file(iconPath);

		m_label = new Gtk.Label(m_name);
		m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_label.set_ellipsize(Pango.EllipsizeMode.END);
		m_label.set_alignment(0.5f, 0.5f);

		m_box.pack_start(icon, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
        m_box.pack_end(m_stack, false, false, 0);

		var seperator_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 2);
		seperator_box.pack_start(m_box, true, true, 0);
		seperator_box.pack_start(m_revealer, false, false, 0);
		seperator_box.pack_start(separator, false, false, 0);

		this.add(seperator_box);
		this.show_all();

		if(serviceSettings.get_boolean("is-logged-in"))
		{
			m_stack.set_visible_child_name("loggedIN");
		}
		else
		{
			m_stack.set_visible_child_name("button");
		}
	}


	private void login()
	{
		switch(m_type)
		{
			case OAuth.READABILITY:
			case OAuth.POCKET:
				doOAuth();
				break;

			case OAuth.INSTAPAPER:
				doXAuth();
				break;
		}
	}

	private void doOAuth()
	{
		if(share.getRequestToken(m_type))
		{
			var dialog = new LoginDialog(m_type);
			dialog.sucess.connect(() => {
				if(share.getAccessToken(m_type))
				{
					m_stack.set_visible_child_name("loggedIN");
				}
			});
		}
	}

	private void doXAuth()
	{
		if(m_revealer.get_child_revealed())
		{
			if(share.getAccessToken(OAuth.INSTAPAPER,  m_userEntry.get_text(), m_passEntry.get_text()))
			{
				settings_instapaper.set_string("username", m_userEntry.get_text());
				var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE,
												"Username", Secret.SchemaAttributeType.STRING);

				var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
				attributes["Username"] = m_userEntry.get_text();
				try{
					Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedreader: Instapaper login", m_passEntry.get_text(), null);
				}
				catch(GLib.Error e){}

				m_login_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
				m_revealer.set_reveal_child(false);
				m_stack.set_visible_child_name("loggedIN");
			}
			else
			{
				//FIXME pop up infobar with error
			}

		}
		else
		{
			m_revealer.set_reveal_child(true);
			m_login_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			m_userEntry.grab_focus();
		}
	}

}
