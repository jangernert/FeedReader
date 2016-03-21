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

public class FeedReader.AddPopover : Gtk.Popover {

	private Gtk.Stack m_stack;
	private Gtk.Box m_box;
	private Gtk.Grid m_feedGrid;
	private Gtk.Grid m_opmlGrid;
	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_catEntry;
	private Gtk.EntryCompletion m_complete;

	public AddPopover(Gtk.Widget parent)
	{
		this.relative_to = parent;
		this.position = Gtk.PositionType.TOP;

		Gtk.ListStore list_store = new Gtk.ListStore(1, typeof (string));
		Gtk.TreeIter iter;
		var cats = dataBase.read_categories();

		foreach(var cat in cats)
		{
			list_store.append(out iter);
			list_store.set(iter, 0, cat.getTitle());
		}

		m_urlEntry = new Gtk.Entry();
		m_catEntry = new Gtk.Entry();
		m_complete = new Gtk.EntryCompletion();
		m_complete.set_model(list_store);
		m_complete.set_text_column(0);
		m_catEntry.placeholder_text = _("Uncategorized");
		m_catEntry.set_completion(m_complete);
		var urlLabel = new Gtk.Label(_("URL:"));
		var catLabel = new Gtk.Label(_("Category:"));
		urlLabel.set_xalign(1.0f);
		catLabel.set_xalign(1.0f);
		var addButton = new Gtk.Button.with_label(_("Add"));
		addButton.get_style_context().add_class("suggested-action");
		addButton.halign = Gtk.Align.END;

		m_feedGrid = new Gtk.Grid();
		m_feedGrid.row_spacing = 5;
		m_feedGrid.column_spacing = 8;
		m_feedGrid.attach(urlLabel, 0, 0, 1, 1);
		m_feedGrid.attach(m_urlEntry, 1, 0, 1, 1);
		m_feedGrid.attach(catLabel, 0, 1, 1, 1);
		m_feedGrid.attach(m_catEntry, 1, 1, 1, 1);
		m_feedGrid.attach(addButton, 0, 2, 2, 1);

		m_opmlGrid = new Gtk.Grid();

		m_stack = new Gtk.Stack();
		m_stack.add_titled(m_feedGrid, "feeds", _("Add feed"));
		m_stack.add_titled(m_opmlGrid, "opml", _("Import OPML"));

		var switcher = new Gtk.StackSwitcher();
		switcher.halign = Gtk.Align.CENTER;
		switcher.set_stack(m_stack);

		m_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		m_box.margin = 10;
		m_box.pack_start(switcher);
		m_box.pack_start(m_stack);

		this.add(m_box);
		this.show_all();
	}
}
