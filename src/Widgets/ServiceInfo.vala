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

public class FeedReader.ServiceInfo : Gtk.Overlay {
    private Gtk.Stack m_stack;
    private Gtk.Spinner m_spinner;
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

        m_spinner = new Gtk.Spinner();
        m_spinner.set_size_request(32,32);

        m_stack = new Gtk.Stack();
        m_stack.add_named(m_box, "info");
        m_stack.add_named(m_spinner, "spinner");
        this.add(m_stack);

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

        if(this.is_visible())
        {
            if(user_name == null || user_name == "")
            {
                m_spinner.start();
                m_stack.set_visible_child_name("spinner");
            }
            else
            {
                m_logo.set_from_file("/usr/share/icons/hicolor/64x64/places/feed-service-%s-grey.svg".printf(service_name));
                this.set_tooltip_text(server);
                m_label.set_label(user_name);
                m_stack.set_visible_child_name("info");
            }
        }

        show_all();
    }
}
