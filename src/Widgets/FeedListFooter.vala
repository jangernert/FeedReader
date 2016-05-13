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

public class FeedReader.FeedListFooter : Gtk.Box {

	private Gtk.Box m_box;
	private Gtk.Stack m_addStack;
	private Gtk.Spinner m_addSpinner;
	private Gtk.Button m_addButton;
	private Gtk.Button m_removeButton;
	private FeedListType m_type;
	private string m_id;
	private bool m_online = true;

	public FeedListFooter()
	{
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 0;
		this.set_size_request(0, 40);
		this.valign = Gtk.Align.END;
		this.get_style_context().add_class("footer");

		m_addButton = new Gtk.Button.from_icon_name("feed-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_addButton.get_style_context().remove_class("button");
		m_addButton.get_style_context().add_class("feedlist-symbolic");
		m_addButton.get_image().opacity = 0.8;
		m_addButton.clicked.connect(() => {
			m_addButton.get_style_context().add_class("footer-popover");
			var addPop = new AddPopover(m_addButton);
			addPop.closed.connect(() => {
				m_addButton.get_style_context().remove_class("footer-popover");
			});
			addPop.show();
		});

		m_addSpinner = new Gtk.Spinner();
		m_addSpinner.get_style_context().add_class("feedlist-spinner");
		m_addSpinner.margin = 4;
		m_addSpinner.start();
		m_addStack = new Gtk.Stack();
		m_addStack.add_named(m_addButton, "button");
		m_addStack.add_named(m_addSpinner, "spinner");

		m_removeButton = new Gtk.Button.from_icon_name("feed-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_removeButton.get_style_context().remove_class("button");
		m_removeButton.get_style_context().add_class("feedlist-symbolic");
		m_removeButton.get_image().opacity = 0.8;
		m_removeButton.clicked.connect(() => {
			m_removeButton.get_style_context().add_class("footer-popover");
			var removePop = new RemovePopover(m_removeButton, m_type, m_id);
			removePop.closed.connect(() => {
				m_removeButton.get_style_context().remove_class("footer-popover");
			});
			m_removeButton.show();
		});

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.pack_start(m_addStack);
		var sep1 = new Gtk.Separator(Gtk.Orientation.VERTICAL);
		var sep2 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		sep1.get_style_context().add_class("feedlist-separator");
		sep2.get_style_context().add_class("feedlist-separator");
		m_box.pack_start(sep1, false, false);
		m_box.pack_start(m_removeButton);

		this.pack_start(sep2, false, false);
		this.pack_start(m_box);
	}

	public void setBusy()
	{
		m_addStack.set_visible_child_name("spinner");
		m_addStack.show_all();
	}

	public void setReady()
	{
		m_addStack.set_visible_child_name("button");
		m_addSpinner.start();
		m_addStack.show_all();
	}

	public void setRemoveButtonSensitive(bool sensitive)
	{
		if(m_online)
			m_removeButton.set_sensitive(sensitive);
	}

	public void setSelectedRow(FeedListType type, string id)
	{
		m_type = type;
		m_id = id;
	}

	public void setActive(bool active)
	{
		m_online = active;
		m_addButton.set_sensitive(active);
		m_removeButton.set_sensitive(active);
	}
}
