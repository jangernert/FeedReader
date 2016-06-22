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

public class FeedReader.SharePopover : Gtk.Popover {

	private Gtk.ListBox m_list;
    public signal void showSettings(string panel);

	public SharePopover(Gtk.Widget widget)
	{
        m_list = new Gtk.ListBox();
        m_list.margin = 10;
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        m_list.row_activated.connect(shareURL);
        populateList();
		this.add(m_list);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
        this.show_all();
	}

    private void populateList()
    {
    	var list = share.getAccounts();

        foreach(var account in list)
        {
        	m_list.add(new ShareRow(account.getType(), account.getID(), account.getUsername()));
        }

		m_list.add(new ShareRow(OAuth.MAIL, "mail", null));

		var addIcon = new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.DND);
		var addLabel = new Gtk.Label(_("Configure more accounts"));
		addLabel.set_line_wrap_mode(Pango.WrapMode.WORD);
        addLabel.set_ellipsize(Pango.EllipsizeMode.END);
        addLabel.set_alignment(0.5f, 0.5f);
        addLabel.get_style_context().add_class("h4");
		var addBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		addBox.margin = 3;
        addBox.pack_start(addIcon, false, false, 8);
        addBox.pack_start(addLabel, true, true, 0);

		var addRow = new Gtk.ListBoxRow();
		addRow.margin = 2;
		addRow.add(addBox);

		m_list.add(addRow);
    }

    private void shareURL(Gtk.ListBoxRow row)
    {
        this.hide();
        ShareRow? shareRow = row as ShareRow;

		if(shareRow == null)
		{
			showSettings("service");
			logger.print(LogMessage.DEBUG, "SharePopover: open Settings");
			this.hide();
			return;
		}

        string url = "";
        string id = shareRow.getID();

        var window = this.get_toplevel() as readerUI;
        if(window != null)
            url = window.getContent().getSelectedURL();

        share.addBookmark(id, url);
        logger.print(LogMessage.DEBUG, "bookmark: %s to %s".printf(url, id));
    }
}
