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

public class FeedReader.ServiceSetup : Gtk.ListBoxRow {

	protected string m_name;
    protected Gtk.Revealer m_revealer;
    protected Gtk.Label m_label;
    protected Gtk.Box m_box;
	protected Gtk.Box m_labelBox;
	protected Gtk.Stack m_iconStack;
	protected Gtk.Stack m_labelStack;
    protected Gtk.Button m_login_button;
	protected Gtk.Button m_logout_button;
	protected Gtk.EventBox m_eventbox;
	protected Gtk.Box m_seperator_box;
	protected bool m_isLoggedIN;
	protected string m_id;
	protected bool m_systemAccount;
	public signal void removeRow();

	public ServiceSetup(string name, string iconName, bool loggedIn, string username, bool system = false)
	{
		m_name = name;
		m_systemAccount = system;
		m_isLoggedIN = loggedIn;
		m_iconStack = new Gtk.Stack();
		m_iconStack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
		m_iconStack.set_transition_duration(300);
		m_labelStack = new Gtk.Stack();

		m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		if(!m_systemAccount)
		{
			m_eventbox.enter_notify_event.connect(onEnter);
			m_eventbox.leave_notify_event.connect(onLeave);
		}
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
		m_iconStack.set_size_request(100, 0);

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.set_size_request(0, 50);

		var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DND);
		icon.set_size_request(100, 0);

		var label = new Gtk.Label(m_name);
		label.set_alignment(0.5f, 0.5f);

		var label1 = new Gtk.Label(m_name);
		m_label = new Gtk.Label(username);
		label1.set_alignment(0.5f, 1.0f);
		m_label.set_alignment(0.5f, 0.2f);
		m_label.opacity = 0.5;
		m_labelBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_labelBox.pack_start(label1, true, true, 0);
		m_labelBox.pack_start(m_label, true, true, 0);

		m_labelStack.add_named(label, "loggedOUT");
		m_labelStack.add_named(m_labelBox, "loggedIN");

		m_box.pack_start(icon, false, false, 0);
		m_box.pack_start(m_labelStack, true, true, 0);
        m_box.pack_end(m_eventbox, false, false, 0);

		m_seperator_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		m_seperator_box.pack_start(m_box, true, true, 0);
		m_seperator_box.pack_end(separator, false, false, 0);


		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(m_seperator_box);
		m_revealer.set_reveal_child(false);

		this.add(m_revealer);
		this.show_all();

		if(m_isLoggedIN)
		{
			m_iconStack.set_visible_child_name("loggedIN");
			m_labelStack.set_visible_child_name("loggedIN");
		}
		else
		{
			m_iconStack.set_visible_child_name("button");
			m_labelStack.set_visible_child_name("loggedOUT");
		}
	}

	public virtual void login()
	{

	}

	public virtual void logout()
	{

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

	public void reveal()
	{
		m_revealer.set_reveal_child(true);
		this.show_all();
	}

	public void unreveal()
	{
		m_revealer.set_reveal_child(false);
	}

	public bool isLoggedIn()
	{
		return m_isLoggedIN;
	}

	public string getID()
	{
		return m_id;
	}

	public bool isSystemAccount()
	{
		return m_systemAccount;
	}

	public string getUserName()
	{
		return m_label.get_text();
	}

}
