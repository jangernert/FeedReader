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

public class FeedReader.InAppNotification : Gd.Notification {

	private Gtk.Box m_box;
	private Gtk.Button m_revertButton;
	public signal void revert();

	public InAppNotification(string message, int timeout = 5)
	{
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		m_revertButton = new Gtk.Button.with_label(_("undo"));
		m_box.pack_start(new Gtk.Label(message));
		m_box.pack_start(m_revertButton);
		this.set_timeout(5);
		this.add(m_box);

		m_revertButton.clicked.connect(() => {
			revert();
		});
	}

}
