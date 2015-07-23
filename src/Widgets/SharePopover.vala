public class FeedReader.SharePopover : Gtk.Popover {

	private Gtk.ListBox m_list;
    private Gtk.Button m_login_button;
    private bool m_haveServices;
    public signal void showSettings(string panel);

	public SharePopover(Gtk.Widget widget)
	{
        m_haveServices = false;
        m_list = new Gtk.ListBox();
        m_list.margin = 10;
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        m_list.row_activated.connect(shareURL);
        m_login_button = new Gtk.Button.with_label(_("Login"));
        m_login_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        m_login_button.get_style_context().add_class("h4");
        var emptyBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        emptyBox.margin = 30;

        var label1 = new Gtk.Label(_("please"));
        label1.get_style_context().add_class("h4");
        var label2 = new Gtk.Label(_("to a service to share this article"));
        label2.get_style_context().add_class("h4");

        emptyBox.pack_start(label1);
        emptyBox.pack_start(m_login_button);
        emptyBox.pack_start(label2);

        m_login_button.clicked.connect(() => {
            showSettings("service");
            this.hide();
        });

        populateList();

        if(m_haveServices)
        {
            this.add(m_list);
        }
        else
        {
            this.add(emptyBox);
        }

		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
        this.show_all();
	}

    private void populateList()
    {
        if(settings_readability.get_boolean("is-logged-in"))
        {
            var readabilityRow = new ShareRow("Readability", OAuth.READABILITY);
            m_list.add(readabilityRow);
            m_haveServices = true;
        }

        if(settings_pocket.get_boolean("is-logged-in"))
        {
            var pocketRow = new ShareRow("Pocket", OAuth.POCKET);
            m_list.add(pocketRow);
            m_haveServices = true;
        }

        if(settings_instapaper.get_boolean("is-logged-in"))
        {
            var instaRow = new ShareRow("Instapaper", OAuth.INSTAPAPER);
            m_list.add(instaRow);
            m_haveServices = true;
        }

		if(settings_evernote.get_boolean("is-logged-in"))
        {
            var evernoteRow = new ShareRow("Evernote", OAuth.EVERNOTE);
            m_list.add(evernoteRow);
            m_haveServices = true;
        }
    }

    private void shareURL(Gtk.ListBoxRow row)
    {
        this.hide();
        var shareRow = row as ShareRow;
        string url = "";
        OAuth type = shareRow.getType();

        var window = this.get_toplevel() as readerUI;
        if(window != null)
            url = window.getSelectedURL();

        share.addBookmark(type, url);
        logger.print(LogMessage.DEBUG, "bookmark: " + url);
    }
}
