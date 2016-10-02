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
        m_logo = new Gtk.Image();
        m_logo = new Gtk.Image.from_file("");
        m_logo.get_style_context().add_class("fr-sidebar-symbolic");
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
        m_stack.get_style_context().add_class("fr-sidebar");
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
        try
        {
            if(!feedDaemon_interface.isOnline())
                return;

            string? service_icon = feedDaemon_interface.symbolicIcon();
            string? user_name = feedDaemon_interface.accountName();
            string? server = feedDaemon_interface.getServerURL();

            if(this.is_visible())
            {
                if(user_name == null || service_icon == null)
                {
                    m_spinner.start();
                    m_stack.set_visible_child_name("spinner");
                }
                else
                {
                    m_logo.set_from_resource("/org/gnome/FeedReader/icons/hicolor/64x64/places/%s.svg".printf(service_icon));
                    m_logo.get_style_context().add_class("fr-sidebar-symbolic");
                    m_label.set_label(user_name);
                    m_stack.set_visible_child_name("info");
                    if(server != null)
                        this.set_tooltip_text(Utils.shortenURL(server));
                }
            }
        }
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "ServiceInfo.refresh: %s".printf(e.message));
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
