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
	private Gtk.FileChooserButton m_chooser;
	private Gtk.EntryCompletion m_complete;
	private Gee.List<Category> m_cats;
	
	public AddPopover(Gtk.Widget parent)
	{
		this.relative_to = parent;
		this.position = Gtk.PositionType.TOP;
		
		m_urlEntry = new Gtk.Entry();
		m_urlEntry.activate.connect(() => {
			m_catEntry.grab_focus();
		});
		m_catEntry = new Gtk.Entry();
		m_catEntry.placeholder_text = _("Uncategorized");
		m_catEntry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "edit-clear");
		m_catEntry.activate.connect(addFeed);
		m_catEntry.icon_press.connect((pos, event) => {
			if(pos == Gtk.EntryIconPosition.SECONDARY)
			{
				m_catEntry.set_text("");
			}
		});
		var urlLabel = new Gtk.Label(_("URL:"));
		var catLabel = new Gtk.Label(_("Category:"));
		urlLabel.set_alignment(1.0f, 0.5f);
		catLabel.set_alignment(1.0f, 0.5f);
		var addButton = new Gtk.Button.with_label(_("Add"));
		addButton.get_style_context().add_class("suggested-action");
		addButton.halign = Gtk.Align.END;
		addButton.clicked.connect(addFeed);
		
		m_feedGrid = new Gtk.Grid();
		m_feedGrid.row_spacing = 5;
		m_feedGrid.column_spacing = 8;
		m_feedGrid.attach(urlLabel, 0, 0, 1, 1);
		m_feedGrid.attach(m_urlEntry, 1, 0, 1, 1);
		m_feedGrid.attach(catLabel, 0, 1, 1, 1);
		m_feedGrid.attach(m_catEntry, 1, 1, 1, 1);
		m_feedGrid.attach(addButton, 0, 2, 2, 1);
		
		var opmlLabel = new Gtk.Label(_("OPML File:"));
		opmlLabel.expand = true;
		m_chooser = new Gtk.FileChooserButton(_("Select OPML File"), Gtk.FileChooserAction.OPEN);
		var filter = new Gtk.FileFilter();
		filter.add_mime_type("text/x-opml");
		m_chooser.set_filter(filter);
		m_chooser.expand = true;
		
		var importButton = new Gtk.Button.with_label(_("Import"));
		importButton.get_style_context().add_class("suggested-action");
		importButton.halign = Gtk.Align.END;
		importButton.clicked.connect(importOPML);
		importButton.sensitive = false;
		
		m_chooser.file_set.connect(() => {
			importButton.sensitive = true;
		});
		
		m_opmlGrid = new Gtk.Grid();
		m_opmlGrid.row_spacing = 10;
		m_opmlGrid.column_spacing = 8;
		m_opmlGrid.attach(opmlLabel, 0, 0, 1, 1);
		m_opmlGrid.attach(m_chooser, 1, 0, 1, 1);
		m_opmlGrid.attach(importButton, 0, 1, 2, 1);
		
		
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
		m_urlEntry.grab_focus();
		
		GLib.Idle.add(() => {
			Gtk.ListStore list_store = new Gtk.ListStore(1, typeof (string));
			Gtk.TreeIter iter;
			m_cats = DataBase.readOnly().read_categories();
			
			foreach(var cat in m_cats)
			{
				list_store.append(out iter);
				list_store.set(iter, 0, cat.getTitle());
			}
			m_complete = new Gtk.EntryCompletion();
			m_complete.set_text_column(0);
			m_complete.set_model(list_store);
			m_catEntry.set_completion(m_complete);
			return false;
		}, GLib.Priority.HIGH_IDLE);
	}
	
	private void addFeed()
	{
		string url = m_urlEntry.text;
		if(url == "")
		{
			m_urlEntry.grab_focus();
			return;
		}
		
		string? catID = DataBase.readOnly().getCategoryID(m_catEntry.text);
		bool isID = true;
		
		if(catID == null)
		{
			catID = m_catEntry.text;
			isID = false;
		}
		
		
		if (GLib.Uri.parse_scheme(url) == null)
		{
			url = "http://" + url;
		}
		
		Logger.debug("addFeed: %s, %s".printf(url, (catID == "") ? "null" : catID));
		FeedReaderBackend.get_default().addFeed(url, catID, isID);
		
		setBusy();
	}
	
	private void importOPML()
	{
		try
		{
			Logger.info("selection_changed");
			var file = m_chooser.get_file();
			uint8[] contents;
			file.load_contents (null, out contents, null);
			Logger.debug((string)contents);
			FeedReaderBackend.get_default().importOPML((string)contents);
		}
		catch(GLib.Error e)
		{
			Logger.error("AddPopover.importOPML: %s".printf(e.message));
		}
		setBusy();
	}
	
	private void setBusy()
	{
		ColumnView.get_default().footerSetBusy();
		this.hide();
	}
}
