public class FeedReader.TagPopover : Gtk.Popover {

	private Gtk.ListBox m_list;

	public TagPopover(Gtk.Widget widget)
	{
        m_list = new Gtk.ListBox();
		m_list.margin = 2;
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.margin = 10;

        var label = new Gtk.Label(_("Tags:"));
		label.get_style_context().add_class("h4");
		label.set_alignment(0, 0.5f);

		populateList();

		var viewport = new Gtk.Viewport (null, null);
        viewport.get_style_context().add_class("servicebox");
        viewport.add(m_list);

		box.pack_start(label);
		box.pack_start(viewport);

		this.add(box);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
        this.show_all();
	}


	private void populateList()
	{

		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			var tags = window.getContent().getSelectedArticleTags();

			foreach(tag Tag in tags)
			{
				var row = new TagPopoverRow(Tag);
				m_list.add(row);
			}
		}
		else
		{
			logger.print(LogMessage.ERROR, "TagPopover: cant get window");
		}
	}

}
