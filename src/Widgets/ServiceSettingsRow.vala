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

public class FeedReader.ServiceRow : Gtk.ListBoxRow {

	private string m_name;
    private OAuth m_type;
    private Gtk.Label m_label;
    private Gtk.Box m_box;
	private Gtk.Box m_labelBox;
	private Gtk.Stack m_iconStack;
	private Gtk.Stack m_labelStack;
    private Gtk.Button m_login_button;
	private Gtk.Button m_logout_button;
	private Gtk.EventBox m_eventbox;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passEntry;
	private GLib.Settings m_serviceSettings;
	private bool m_isLoggedIN;
	private Gtk.InfoBar m_errorBar;
	private Gtk.Revealer m_revealer;

	public ServiceRow(string serviceName, OAuth type)
	{
		m_name = serviceName;
        m_type = type;
		m_isLoggedIN = false;
		m_iconStack = new Gtk.Stack();
		m_iconStack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
		m_iconStack.set_transition_duration(300);
		m_labelStack = new Gtk.Stack();
		string iconName = "";
		m_serviceSettings = settings_readability;

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

		m_errorBar = new Gtk.InfoBar();
		m_errorBar.no_show_all = true;
		var error_content = m_errorBar.get_content_area();
		var errorLabel = new Gtk.Label(_("Username or Password incorrect"));
		errorLabel.show();
		error_content.add(errorLabel);
		m_errorBar.set_message_type(Gtk.MessageType.WARNING);
		m_errorBar.set_show_close_button(true);
		m_errorBar.response.connect((response_id) => {
			if(response_id == Gtk.ResponseType.CLOSE) {
					m_errorBar.set_visible(false);
			}
		});

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

		grid.attach(m_errorBar, 0, 0, 2, 1);
        grid.attach(new Gtk.Label(_("Username:")), 0, 1, 1, 1);
        grid.attach(new Gtk.Label(_("Password:")), 0, 2, 1, 1);
        grid.attach(m_userEntry, 1, 1, 1, 1);
        grid.attach(m_passEntry, 1, 2, 1, 1);

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(grid);
		//------------------------------------------------

		m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_eventbox.enter_notify_event.connect(onEnter);
		m_eventbox.leave_notify_event.connect(onLeave);
		m_eventbox.add(m_iconStack);

        m_login_button = new Gtk.Button.with_label(_("Login"));
        m_login_button.hexpand = false;
        m_login_button.margin = 10;
        m_login_button.clicked.connect(login);

		m_logout_button = new Gtk.Button.with_label(_("Logout"));
		m_logout_button.hexpand = false;
		m_logout_button.margin = 10;
		m_logout_button.clicked.connect(logout);
		m_logout_button.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

		var loggedIN = new Gtk.Image.from_icon_name("feed-status-ok", Gtk.IconSize.LARGE_TOOLBAR);

		m_iconStack.add_named(m_login_button, "button");
		m_iconStack.add_named(loggedIN, "loggedIN");
		m_iconStack.add_named(m_logout_button, "logOUT");

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.set_size_request(0, 50);

		switch (m_type)
        {
            case OAuth.READABILITY:
                iconName = "feed-share-readability";
				m_serviceSettings = settings_readability;
                break;

            case OAuth.INSTAPAPER:
                iconName = "feed-share-instapaper";
				m_serviceSettings = settings_instapaper;
                break;

            case OAuth.POCKET:
                iconName = "feed-share-pocket";
				m_serviceSettings = settings_pocket;
                break;
        }

		var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DND);

		var label = new Gtk.Label(m_name);
		label.set_alignment(0.5f, 0.5f);



		var label1 = new Gtk.Label(m_name);
		m_label = new Gtk.Label(m_serviceSettings.get_string("username"));
		label1.set_alignment(0.5f, 1.0f);
		m_label.set_alignment(0.5f, 0.2f);
		m_label.opacity = 0.5;
		m_labelBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_labelBox.pack_start(label1, true, true, 0);
		m_labelBox.pack_start(m_label, true, true, 0);

		m_labelStack.add_named(label, "loggedOUT");
		m_labelStack.add_named(m_labelBox, "loggedIN");

		m_box.pack_start(icon, false, false, 8);
		m_box.pack_start(m_labelStack, true, true, 0);
        m_box.pack_end(m_eventbox, false, false, 0);

		var seperator_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 2);
		seperator_box.pack_start(m_box, true, true, 0);
		seperator_box.pack_start(m_revealer, false, false, 0);
		seperator_box.pack_start(separator, false, false, 0);

		this.add(seperator_box);
		this.show_all();

		if(m_serviceSettings.get_boolean("is-logged-in"))
		{
			m_isLoggedIN = true;
			m_iconStack.set_visible_child_name("loggedIN");
			m_labelStack.set_visible_child_name("loggedIN");
		}
		else
		{
			m_iconStack.set_visible_child_name("button");
			m_labelStack.set_visible_child_name("loggedOUT");
		}
	}

	private bool onEnter()
	{
		if(m_isLoggedIN)
			m_iconStack.set_visible_child_full("logOUT", Gtk.StackTransitionType.SLIDE_LEFT);
		return false;
	}

	private bool onLeave()
	{
		if(m_isLoggedIN)
			m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_RIGHT);

		return false;
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

	private void logout()
	{
		share.logout(m_type);
		m_isLoggedIN = false;
		m_iconStack.set_visible_child_full("button", Gtk.StackTransitionType.SLIDE_RIGHT);
		m_labelStack.set_visible_child_name("loggedOUT");
	}

	private void doOAuth()
	{
		if(share.getRequestToken(m_type))
		{
			Gtk.show_uri(Gdk.Screen.get_default(), Utils.buildURL(m_type), Gdk.CURRENT_TIME);
			m_login_button.set_label(_("waiting"));
			m_login_button.set_sensitive(false);
			((rssReaderApp)GLib.Application.get_default()).callback.connect((type) => {
				if(share.getAccessToken(type))
				{
					m_iconStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.SLIDE_LEFT);
					m_isLoggedIN = true;
					m_label.set_label(m_serviceSettings.get_string("username"));
					m_labelStack.set_visible_child_full("loggedIN", Gtk.StackTransitionType.CROSSFADE);
				}
			});
		}
	}

	private void doXAuth()
	{
		if(m_revealer.get_child_revealed())
		{
			if(share.getAccessToken(m_type,  m_userEntry.get_text(), m_passEntry.get_text()))
			{
				m_login_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
				m_revealer.set_reveal_child(false);
				m_isLoggedIN = true;
				m_iconStack.set_visible_child_name("loggedIN");
				m_label.set_label(m_serviceSettings.get_string("username"));
				m_labelStack.set_visible_child_name("loggedIN");
			}
			else
			{
				m_errorBar.set_visible(true);
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
