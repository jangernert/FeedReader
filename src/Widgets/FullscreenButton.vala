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

public class FeedReader.fullscreenButton : Gtk.Revealer {
	
	private Gtk.Button m_button;
	public signal void click();
	
	public fullscreenButton(string iconName, Gtk.Align align)
	{
		this.valign = Gtk.Align.CENTER;
		this.halign = align;
		this.get_style_context().add_class("osd");
		this.margin = 40;
		this.no_show_all = true;
		this.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE);
		this.set_transition_duration(300);
		
		m_button = new Gtk.Button.from_icon_name(iconName, Gtk.IconSize.DIALOG);
		m_button.clicked.connect(() => {
			click();
		});
		m_button.margin = 20;
		this.add(m_button);
	}
	
	public void reveal(bool show)
	{
		if(show)
		{
			this.visible = true;
			m_button.show();
		}
		
		this.set_reveal_child(show);
	}
	
}
