public class FeedReader.TagPopover : Gtk.Popover {

	private Gtk.ListBox m_list;
	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private Gtk.Viewport m_viewport;
	private Gtk.Entry m_entry;
	private GLib.List<tag> m_tags;
	private Gtk.EntryCompletion m_complete;
	private GLib.List<tag> m_availableTags;

	public TagPopover(Gtk.Widget widget)
	{
		m_availableTags = new GLib.List<tag>();
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			m_tags = window.getContent().getSelectedArticleTags();
		}


        m_list = new Gtk.ListBox();
		m_list.margin = 2;
		m_list.set_size_request(150, 0);
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        m_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_box.margin = 10;

		if(m_tags.length() != 0)
		{
	        m_label = new Gtk.Label(_("Tags:"));
			m_label.get_style_context().add_class("h4");
			m_label.set_alignment(0, 0.5f);

			populateList();

			var m_viewport = new Gtk.Viewport (null, null);
	        m_viewport.get_style_context().add_class("servicebox");
	        m_viewport.add(m_list);
			m_viewport.margin_bottom = 10;
			m_box.pack_start(m_label);
			m_box.pack_start(m_viewport);
		}
		else
		{
			m_label = new Gtk.Label(_("add Tags:"));
			m_label.get_style_context().add_class("h4");
			m_label.set_alignment(0, 0.5f);
			m_box.pack_start(m_label);
		}

		setupEntry();


		m_box.pack_start(m_entry);

		this.add(m_box);
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
			row.remove_tag.connect(removeTag);
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
				m_availableTags.append(Tag);
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
			bool available = false;
			string tagID = "";

			foreach(tag Tag in m_availableTags)
			{
				if(str == Tag.getTitle())
				{
					logger.print(LogMessage.DEBUG, "TagPopover: tag available");
					tagID = Tag.getTagID();
					available = true;
					break;
				}
			}

			if(!available)
			{
				tagID = feedDaemon_interface.createTag(str);
				logger.print(LogMessage.DEBUG, "TagPopover: " + str + " created with id " + tagID);
			}

			feedDaemon_interface.tagArticle(getActiveArticleID(), tagID, true);
		});

		prepareCompletion();
	}

	private void removeTag(TagPopoverRow row)
	{
		feedDaemon_interface.tagArticle(getActiveArticleID(), row.getTagID(), false);
		m_list.remove(row);

		if(m_list.get_children().length() == 0)
		{
			m_box.remove(m_viewport);
			m_label.set_label(_("add Tags"));
			this.show_all();
		}
	}

	private string getActiveArticleID()
	{
		string articleID = "";
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			articleID = window.getContent().getSelectedArticle();
		}

		return articleID;
	}

	public bool entryFocused()
	{
		return m_entry.has_focus;
	}

}
