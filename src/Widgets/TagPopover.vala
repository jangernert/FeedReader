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

public class FeedReader.TagPopover : Gtk.Popover {

	private Gtk.ListBox m_list;
	private Gtk.Box m_box;
	private Gtk.Viewport m_viewport;
	private Gtk.Entry m_entry;
	private Gtk.Stack m_stack;
	private Gee.ArrayList<tag> m_tags;
	private Gtk.EntryCompletion m_complete;
	private Gee.ArrayList<tag> m_availableTags;

	public TagPopover(Gtk.Widget widget)
	{
		m_availableTags = new Gee.ArrayList<tag>();
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			m_tags = window.getContent().getSelectedArticleTags();
		}

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.NONE);
		m_stack.set_transition_duration(0);

		var empty_label = new Gtk.Label(_("Add Tag:"));
		empty_label.get_style_context().add_class("h4");
		empty_label.set_alignment(0, 0.5f);
		m_stack.add_named(empty_label, "empty");

		m_list = new Gtk.ListBox();
		m_list.margin = 2;
		m_list.set_size_request(150, 0);
		m_list.set_selection_mode(Gtk.SelectionMode.NONE);
		m_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_box.margin = 10;

		var tag_label = new Gtk.Label(_("Tags:"));
		tag_label.get_style_context().add_class("h4");
		tag_label.set_alignment(0, 0.5f);
		m_viewport = new Gtk.Viewport(null, null);
		m_viewport.get_style_context().add_class("servicebox");
		m_viewport.add(m_list);
		m_viewport.margin_bottom = 10;
		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.pack_start(tag_label);
		box.pack_start(m_viewport);
		m_stack.add_named(box, "tags");


		setupEntry();
		populateList();


		m_box.pack_start(m_stack);
		m_box.pack_start(m_entry);

		this.add(m_box);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
		this.show_all();

		if(m_tags.size == 0)
			m_stack.set_visible_child_name("empty");
		else
			m_stack.set_visible_child_name("tags");
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
				m_availableTags.add(Tag);
			}
		}
	}

	private void setupEntry()
	{
		m_entry = new Gtk.Entry();
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
			if(str == "")
				return;
			bool available = false;
			string tagID = "";

			foreach(tag Tag in m_tags)
			{
				if(str == Tag.getTitle())
				{
					Logger.debug("TagPopover: article already tagged");
					m_entry.set_text("");
					return;
				}
			}

			foreach(tag Tag in m_availableTags)
			{
				if(str == Tag.getTitle())
				{
					Logger.debug("TagPopover: tag available");
					tagID = Tag.getTagID();
					available = true;
					break;
				}
			}

			try
			{
				if(!available)
				{
					tagID = DBusConnection.get_default().createTag(str);
					Logger.debug("TagPopover: " + str + " created with id " + tagID);
				}
				DBusConnection.get_default().tagArticle(getActiveArticleID(), tagID, true);
			}
			catch(GLib.Error e)
			{
				Logger.error("TagPopover.setupEntry: %s".printf(e.message));
			}


			var new_tag = dataBase.read_tag(tagID);
			var row = new TagPopoverRow(new_tag);
			row.remove_tag.connect(removeTag);
			m_list.add(row);
			m_stack.set_visible_child_name("tags");
			m_entry.set_text("");
		});

		prepareCompletion();
	}

	private void removeTag(TagPopoverRow row)
	{
		try
		{
			DBusConnection.get_default().tagArticle(getActiveArticleID(), row.getTagID(), false);
			m_list.remove(row);
		}
		catch(GLib.Error e)
		{
			Logger.error("TagPopover.removeTag: %s".printf(e.message));
		}

		foreach(tag Tag in m_tags)
		{
			if(Tag.getTagID() == row.getTagID())
			{
				m_tags.remove(Tag);
				break;
			}
		}

		if(m_list.get_children().length() == 0)
		{
			m_stack.set_visible_child_name("empty");
			this.show_all();
		}

		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			window.getContent().removeTagFromSelectedRow(row.getTagID());
		}
	}

	private string getActiveArticleID()
	{
		string articleID = "";
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
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
