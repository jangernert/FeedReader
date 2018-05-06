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
	private Gtk.Stack m_stack;
	public signal void startShare();
	public signal void shareDone();

	public SharePopover(Gtk.Widget widget)
	{
		m_list = new Gtk.ListBox();
		m_list.margin = 10;
		m_list.set_selection_mode(Gtk.SelectionMode.NONE);
		m_list.row_activated.connect(clicked);
		refreshList();
		m_stack = new Gtk.Stack();
		m_stack.set_transition_duration(150);
		m_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
		m_stack.add_named(m_list, "list");

		this.add(m_stack);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
		this.show_all();
	}

	public void refreshList()
	{
		var children = m_list.get_children();
		foreach(Gtk.Widget row in children)
		{
			m_list.remove(row);
			row.destroy();
		}

		var list = Share.get_default().getAccounts();

		foreach(var account in list)
		{
			m_list.add(new ShareRow(account.getType(), account.getID(), account.getUsername(), account.getIconName()));
		}

		var addRow = new Gtk.ListBoxRow();
		addRow.margin = 2;

		var addIcon = new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.DND);
		var addLabel = new Gtk.Label(_("Add accounts"));
		addLabel.set_line_wrap_mode(Pango.WrapMode.WORD);
		addLabel.set_ellipsize(Pango.EllipsizeMode.END);
		addLabel.set_alignment(0.0f, 0.5f);
		addLabel.get_style_context().add_class("h4");

		var addBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		addBox.margin = 3;
		addBox.pack_start(addIcon, false, false, 8);
		addBox.pack_start(addLabel, true, true, 0);

		if(list.size > 0)
		{
			var seperatorBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
			seperatorBox.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 0);
			seperatorBox.pack_start(addBox, true, true, 0);
			addRow.add(seperatorBox);
		}
		else
		{
			addRow.add(addBox);
		}

		addRow.show_all();
		m_list.add(addRow);
	}

	private void clicked(Gtk.ListBoxRow row)
	{
		ShareRow? shareRow = row as ShareRow;

		if(shareRow == null)
		{
			this.hide();
			SettingsDialog.get_default().showDialog("service");
			Logger.debug("SharePopover: open Settings");
			return;
		}

		string id = shareRow.getID();
		Article? selectedArticle = ColumnView.get_default().getSelectedArticle();

		if(selectedArticle != null)
		{
			var widget = Share.get_default().shareWidget(shareRow.getType(), selectedArticle.getURL());
			if(widget == null)
				shareURL(id, selectedArticle.getURL());
			else
			{
				m_stack.add_named(widget, "form");
				m_stack.set_visible_child_name("form");
				widget.share.connect_after(() => {
					shareURL(id, selectedArticle.getURL());
				});
				widget.goBack.connect(() => {
					m_stack.set_visible_child_full("list", Gtk.StackTransitionType.SLIDE_RIGHT);
					m_stack.remove(widget);
				});
			}
		}

	}

	private async void shareAsync(string id, string url)
	{
		SourceFunc callback = shareAsync.callback;
		new GLib.Thread<void*>(null, () => {
			Share.get_default().addBookmark(id, url);
			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		});
		yield;
	}

	private void shareURL(string id, string url)
	{
		this.hide();
		startShare();
		shareAsync.begin(id, url, (obj, res) => {
			shareAsync.end(res);
			shareDone();
		});
		string idString = (id == null || id == "") ? "" : @" to $id";
		Logger.debug(@"bookmark: $url$idString");
	}
}

public class FeedReader.ShareForm : Gtk.Box {

	public signal void share();
	public signal void goBack();

	public ShareForm()
	{

	}

}
