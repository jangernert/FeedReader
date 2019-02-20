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
private AddButton m_addButton;
private RemoveButton m_removeButton;

public FeedListFooter()
{
	this.orientation = Gtk.Orientation.VERTICAL;
	this.spacing = 0;
	this.set_size_request(0, 40);
	this.valign = Gtk.Align.END;
	this.get_style_context().add_class("footer");
	m_addButton = new AddButton();
	m_removeButton = new RemoveButton();
	m_addSpinner = new Gtk.Spinner();
	m_addSpinner.get_style_context().add_class("feedlist-spinner");
	m_addSpinner.margin = 4;
	m_addSpinner.start();
	m_addStack = new Gtk.Stack();
	m_addStack.add_named(m_addButton, "button");
	m_addStack.add_named(m_addSpinner, "spinner");
	m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
	m_box.pack_start(m_addStack);
	var sep1 = new Gtk.Separator(Gtk.Orientation.VERTICAL);
	var sep2 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
	sep1.get_style_context().add_class("fr-sidebar-separator");
	sep2.get_style_context().add_class("fr-sidebar-separator");
	m_box.pack_start(sep1, false, false);
	m_box.pack_start(m_removeButton);
	this.pack_start(sep2, false, false);
	this.pack_start(m_box);

	if(!FeedReaderBackend.get_default().supportFeedManipulation())
	{
		m_addButton.set_sensitive(false);
		m_removeButton.set_sensitive(false);
	}
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
	if(FeedReaderApp.get_default().isOnline() && FeedReaderBackend.get_default().supportFeedManipulation())
	{
		m_removeButton.set_sensitive(sensitive);
	}
}

public void setSelectedRow(FeedListType type, string id)
{
	m_removeButton.setSelectedRow(type, id);
}

public void setAddButtonSensitive(bool active)
{
	if(FeedReaderBackend.get_default().supportFeedManipulation())
	{
		m_addButton.set_sensitive(active);
		m_removeButton.set_sensitive(active);
	}
}

public void showError(string errmsg)
{
	var label = new Gtk.Label(errmsg);
	label.margin = 20;

	var pop = new Gtk.Popover(m_addStack);
	pop.add(label);
	pop.show_all();
}
}


public class FeedReader.AddButton : Gtk.Button {
public AddButton()
{
	var image = new Gtk.Image.from_icon_name("feed-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
	this.image = image;
	this.get_style_context().remove_class("button");
	this.get_style_context().add_class("fr-sidebar-symbolic");
	this.image.opacity = 0.8;
	this.clicked.connect(onClick);
	this.relief = Gtk.ReliefStyle.NONE;
	this.set_tooltip_text(_("Add feed"));
}

public void onClick()
{
	this.get_style_context().add_class("footer-popover");
	var pop = new AddPopover(this);
	pop.closed.connect(() => {
			this.get_style_context().remove_class("footer-popover");
			this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
		});
	pop.show();
	this.set_state_flags(Gtk.StateFlags.PRELIGHT, false);
}
}

public class FeedReader.RemoveButton : Gtk.Button {
private FeedListType m_type;
private string m_id;

public RemoveButton()
{
	var image = new Gtk.Image.from_icon_name("feed-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
	this.image = image;
	this.get_style_context().remove_class("button");
	this.get_style_context().add_class("fr-sidebar-symbolic");
	this.image.opacity = 0.8;
	this.clicked.connect(onClick);
	this.relief = Gtk.ReliefStyle.NONE;
	this.set_tooltip_text(_("Remove feed"));
}

public void onClick()
{
	this.get_style_context().add_class("footer-popover");
	var pop = new RemovePopover(this, m_type, m_id);
	pop.closed.connect(() => {
			this.get_style_context().remove_class("footer-popover");
		});
	pop.show();
}
public void setSelectedRow(FeedListType type, string id)
{
	m_type = type;
	m_id = id;
}
}
