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

public class FeedReader.SimpleHeader : Gtk.HeaderBar
{
	private Gtk.Button m_backButton;
	
	public signal void back();
	
	public SimpleHeader()
	{
		m_backButton = new Gtk.Button.from_icon_name("go-previous-symbolic");
		m_backButton.no_show_all = true;
		m_backButton.clicked.connect(() => {
			back();
		});
		
		this.pack_start(m_backButton);
		this.show_close_button = true;
		this.set_title("FeedReader");
	}
	
	public void showBackButton(bool show)
	{
		m_backButton.visible = show;
	}
	
}
