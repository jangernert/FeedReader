public class FeedReader.TagPopover : Gtk.Popover {

	private Gtk.ListBox m_list;
	private Gtk.Entry m_entry;
	private GLib.List<tag> m_tags;
	private Gtk.EntryCompletion m_complete;

	public TagPopover(Gtk.Widget widget)
	{
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			m_tags = window.getContent().getSelectedArticleTags();
		}


        m_list = new Gtk.ListBox();
		m_list.margin = 2;
		m_list.set_size_request(150, 0);
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.margin = 10;

		if(m_tags.length() != 0)
		{
	        var label = new Gtk.Label(_("Tags:"));
			label.get_style_context().add_class("h4");
			label.set_alignment(0, 0.5f);

			populateList();

			var viewport = new Gtk.Viewport (null, null);
	        viewport.get_style_context().add_class("servicebox");
	        viewport.add(m_list);
			viewport.margin_bottom = 10;
			box.pack_start(label);
			box.pack_start(viewport);
		}
		else
		{
			var label = new Gtk.Label(_("add Tags:"));
			label.get_style_context().add_class("h4");
			label.set_alignment(0, 0.5f);
			box.pack_start(label);
		}

		setupEntry();


		box.pack_start(m_entry);

		this.add(box);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
        this.show_all();
	}


	private void populateList()
	{
		foreach(tag Tag in m_tags)
		{
			var row = new TagPopoverRow(Tag);
			m_list.add(row);
		}
	}

	private void prepareCompletion()
	{
		m_complete = new Gtk.EntryCompletion();
		m_entry.set_completion(m_complete);

		Gtk.ListStore list_store = new Gtk.ListStore(1, typeof (string));
		m_complete.set_model(list_store);
		m_complete.set_text_column(0);
		Gtk.TreeIter iter;

		var tags = dataBase.read_tags();

		foreach(tag Tag in tags)
		{
			bool alreadyHasTag = false;

			foreach(tag Tag2 in m_tags)
			{
				if(Tag2.getTitle() == Tag.getTitle())
					alreadyHasTag = true;
			}

			if(!alreadyHasTag)
			{
				list_store.append(out iter);
				list_store.set(iter, 0, Tag.getTitle());
			}
		}
	}

	private void setupEntry()
	{
		m_entry = new Gtk.Entry ();
		m_entry.margin_top = 0;
		m_entry.set_placeholder_text(_("add Tag"));
		m_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "edit-clear");
		m_entry.icon_press.connect((pos, event) => {
			if(pos == Gtk.EntryIconPosition.SECONDARY)
			{
				m_entry.set_text("");
			}
		});
		m_entry.activate.connect(() => {
			unowned string str = m_entry.get_text();
			stdout.printf ("%s\n", str);
		});

		prepareCompletion();
	}

}
