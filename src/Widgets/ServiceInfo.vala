public class FeedReader.ServiceInfo : Gtk.Box {
    private Gtk.Image m_logo;
    private Gtk.Label m_label;

    public ServiceInfo()
    {
        m_logo = new Gtk.Image.from_file("");
        m_label = new Gtk.Label("");
        m_label.margin_start = 10;
        m_label.margin_end = 10;
        m_label.set_ellipsize(Pango.EllipsizeMode.END);
        m_label.opacity = 0.6;

        refresh();

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
                user_name = settings_ttrss.get_string("username") + "@" + shortenURL(settings_ttrss.get_string("url"));
                break;
            case Backend.FEEDLY:
                service_name = "feedly";
                user_name = settings_feedly.get_string("email");
                break;
            case Backend.OWNCLOUD:
                service_name = "owncloud";
                user_name = settings_owncloud.get_string("username") + "@" + shortenURL(settings_owncloud.get_string("url"));
                break;
        }

        m_logo.set_from_file("/usr/share/icons/hicolor/64x64/places/feed-service-%s.svg".printf(service_name));
        m_label.set_label(user_name);
        show_all();
    }

    private string shortenURL(string url)
    {
        string longURL = url;
        if(longURL.has_prefix("https://"))
        {
            longURL = longURL.substring(8);
        }
        else if(longURL.has_prefix("http://"))
        {
            longURL = longURL.substring(7);
        }

        if(longURL.has_prefix("www."))
        {
            longURL = longURL.substring(4);
        }

        if(longURL.has_suffix("api/"))
        {
            longURL = longURL.substring(0, longURL.length - 4);
        }

        return longURL;
    }
}
