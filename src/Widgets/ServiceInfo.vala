public class FeedReader.ServiceInfo : Gtk.Box {

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

        var ttrss_logo = new Gtk.Image.from_file("/usr/share/icons/hicolor/64x64/places/feed-service-%s.svg".printf(service_name));
        var label = new Gtk.Label(user_name);
        label.opacity = 0.6;

        this.pack_start(ttrss_logo, false, false, 0);
        this.pack_start(label, false, false, 5);

        this.orientation = Gtk.Orientation.VERTICAL;
        this.margin_top = 20;
        this.margin_bottom = 5;
    }
}
