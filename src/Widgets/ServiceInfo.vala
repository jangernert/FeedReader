public class FeedReader.ServiceInfo : Gtk.Overlay {
    private Gtk.Image m_logo;
    private Gtk.Label m_label;
    private Gtk.Box m_box;

    public ServiceInfo()
    {
        m_logo = new Gtk.Image.from_file("");
        m_label = new Gtk.Label("");
        m_label.margin_start = 10;
        m_label.margin_end = 10;
        m_label.set_ellipsize(Pango.EllipsizeMode.END);
        m_label.opacity = 0.6;

        refresh();

        m_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        m_box.pack_start(m_logo, false, false, 0);
        m_box.pack_start(m_label, false, false, 5);
        m_box.margin_top = 20;
        m_box.margin_bottom = 5;
        this.add(m_box);

        var label = new Gtk.Label("OFFLINE");
        label.margin_start = 40;
        label.margin_end = 40;
        label.margin_top = 30;
        label.margin_bottom = 10;
        label.get_style_context().add_class("offline");
        //this.add_overlay(label);
    }

    public void refresh()
    {
        string service_name = "";
        string user_name = "";
        string server = "";

        switch(settings_general.get_enum("account-type"))
        {
            case Backend.TTRSS:
                service_name = "ttrss";
                user_name = settings_ttrss.get_string("username");
                server = Utils.shortenURL(settings_ttrss.get_string("url"));
                break;
            case Backend.FEEDLY:
                service_name = "feedly";
                user_name = settings_feedly.get_string("email");
                break;
            case Backend.OWNCLOUD:
                service_name = "owncloud";
                user_name = settings_owncloud.get_string("username");
                server = Utils.shortenURL(settings_owncloud.get_string("url"));
                break;
        }

        m_logo.set_from_file("/usr/share/icons/hicolor/64x64/places/feed-service-%s-grey.svg".printf(service_name));
        this.set_tooltip_text(server);
        m_label.set_label(user_name);
        show_all();
    }
}
