public class FeedReader.ServiceInfo : Gtk.Box {
    private Gtk.Image m_logo;
    private Gtk.Label m_label;

    public ServiceInfo()
    {
        string service_name = "";
        string user_name = "";

        switch(settings_general.get_enum("account-type"))
        {
            case Backend.TTRSS:
                service_name = "ttrss";
                user_name = settings_ttrss.get_string("username") + "@" + settings_ttrss.get_string("url");
                break;
            case Backend.FEEDLY:
                service_name = "feedly";
                user_name = settings_feedly.get_string("email");
                break;
            case Backend.OWNCLOUD:
                service_name = "owncloud";
                user_name = "username@Server";
                break;
        }

        m_logo = new Gtk.Image.from_file("/usr/share/icons/hicolor/64x64/places/feed-service-%s.svg".printf(service_name));
        m_label = new Gtk.Label(user_name);
        m_label.opacity = 0.6;

        this.pack_start(m_logo, false, false, 0);
        this.pack_start(m_label, false, false, 5);

        this.orientation = Gtk.Orientation.VERTICAL;
        this.margin_top = 20;
        this.margin_bottom = 5;
    }

    public void refresh()
    {
        string service_name = "";
        string user_name = "";

        switch(settings_general.get_enum("account-type"))
        {
            case Backend.TTRSS:
                service_name = "ttrss";
                user_name = settings_ttrss.get_string("username") + "@" + settings_ttrss.get_string("url");
                break;
            case Backend.FEEDLY:
                service_name = "feedly";
                user_name = settings_feedly.get_string("email");
                break;
            case Backend.OWNCLOUD:
                service_name = "owncloud";
                user_name = "username@Server";
                break;
        }

        m_logo = new Gtk.Image.from_file("/usr/share/icons/hicolor/64x64/places/feed-service-%s.svg".printf(service_name));
        m_label = new Gtk.Label(user_name);
        m_label.opacity = 0.6;
        show_all();
    }
}
