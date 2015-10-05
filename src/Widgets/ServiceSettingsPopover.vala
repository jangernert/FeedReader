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

public class FeedReader.ServiceSettingsPopover : Gtk.Popover {

	private Gtk.ListBox m_list;
	public signal void newAccount(OAuth type);


	public ServiceSettingsPopover(Gtk.Widget widget)
	{
        m_list = new Gtk.ListBox();
        m_list.margin = 10;
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        m_list.row_activated.connect((row) => {
			newAccount(((ServiceSettingsPopoverRow)row).getType());
			this.hide();
        });

		var instapaper = new ServiceSettingsPopoverRow("Instapaper", OAuth.INSTAPAPER, "feed-share-instapaper");
        var readability = new ServiceSettingsPopoverRow("Readability", OAuth.READABILITY, "feed-share-readability");
        var pocket = new ServiceSettingsPopoverRow("Pocket", OAuth.POCKET, "feed-share-pocket");

        m_list.add(instapaper);
        m_list.add(readability);
        m_list.add(pocket);

        this.add(m_list);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
        this.show_all();
	}

}


public class FeedReader.ServiceSettingsPopoverRow : Gtk.ListBoxRow {

	private string m_name;
    private Gtk.Label m_label;
    private Gtk.Box m_box;
    private OAuth m_type;

	public ServiceSettingsPopoverRow(string serviceName, OAuth type, string iconName)
	{
		m_name = serviceName;
        m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        m_box.margin = 3;

        var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DND);

        m_label = new Gtk.Label(serviceName);
        m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
        m_label.set_ellipsize(Pango.EllipsizeMode.END);
        m_label.set_alignment(0.5f, 0.5f);
        m_label.set_justify(Gtk.Justification.LEFT);
        m_label.set_halign(Gtk.Align.START);

        m_box.pack_start(icon, false, false, 8);
        m_box.pack_start(m_label, true, true, 0);

		this.add(m_box);
		this.show_all();
	}

    public OAuth getType()
    {
        return m_type;
    }

}
