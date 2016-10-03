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

	public signal void newAccount(string type);


	public ServiceSettingsPopover(Gtk.Widget widget)
	{
        var list = new Gtk.ListBox();
        list.margin = 10;
        list.set_selection_mode(Gtk.SelectionMode.NONE);
        list.row_activated.connect((row) => {
			newAccount(((ServiceSettingsPopoverRow)row).getType());
			this.hide();
        });

		foreach(var account in Share.get_default().getAccountTypes())
		{
			var row = new ServiceSettingsPopoverRow(account.getAccountName(), account.getType(), account.getIconName());
			list.add(row);
		}

        this.add(list);
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
    private string m_type;

	public ServiceSettingsPopoverRow(string serviceName, string type, string iconName)
	{
		m_type = type;
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

    public string getType()
    {
        return m_type;
    }

    public string getName()
    {
    	return m_name;
    }

}
