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
    private Gtk.Label m_offline;
    private Gtk.Box m_box;

    public ServiceInfo()
    {
        m_logo = new Gtk.Image.from_icon_name("", Gtk.IconSize.DIALOG);
        m_logo = new Gtk.Image.from_file("");
        m_logo.get_style_context().add_class("sidebar-symbolic");
        m_label = new Gtk.Label("");
        m_label.margin_start = 10;
        m_label.margin_end = 10;
        m_label.set_ellipsize(Pango.EllipsizeMode.END);

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
        m_stack.get_style_context().add_class("sidebar");
        this.add(m_stack);

        m_offline = new Gtk.Label("OFFLINE");
        m_offline.margin_start = 40;
        m_offline.margin_end = 40;
        m_offline.margin_top = 30;
        m_offline.margin_bottom = 10;
        m_offline.get_style_context().add_class("overlay");
        m_offline.no_show_all = true;
        this.add_overlay(m_offline);
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
            case Backend.INOREADER:
                service_name = "inoreader";
                user_name = settings_inoreader.get_string("username");
                break;
            case Backend.THEOLDREADER:
                service_name = "theoldreader";
                user_name = settings_theoldreader.get_string("username");
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
                m_logo.set_from_icon_name("feed-service-%s-symbolic".printf(service_name), Gtk.IconSize.INVALID);
                m_logo.get_style_context().add_class("sidebar-symbolic");
                this.set_tooltip_text(server);
                m_label.set_label(user_name);
                m_stack.set_visible_child_name("info");
            }
        }

        show_all();
    }

    public void setOffline()
    {
        m_offline.show();
    }

    public void setOnline()
    {
        m_offline.hide();
    }
}
