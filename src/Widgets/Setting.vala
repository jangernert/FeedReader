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
using Gee;

public class FeedReader.Setting : Gtk.Box {

	public signal void changed();
	private Gtk.Label m_label;


	public Setting(string name, string? tooltip = null)
	{
		this.orientation = Gtk.Orientation.HORIZONTAL;
		this.spacing = 0;

		m_label = new Gtk.Label(name);
		m_label.set_alignment(0, 0.5f);
		m_label.margin_start = 15;
		m_label.set_tooltip_text(tooltip);

		this.pack_start(m_label, true, true, 0);
	}


}


public class FeedReader.SettingFont : FeedReader.Setting {

	public SettingFont(string name, GLib.Settings settings, string key){
		base(name, null);
		var font_button = new Gtk.FontButton.with_font(settings.get_string(key));
		font_button.set_use_size(false);
		font_button.set_show_size(true);
		font_button.font_set.connect(() => {
			settings.set_string(key, font_button.get_font_name());
			changed();
		});

		this.pack_end(font_button, false, false, 0);
	}

}

public class FeedReader.ArticleThemeSetting : FeedReader.Setting {

  public ArticleThemeSetting (string name, GLib.Settings settings, string key, HashMap<string, ThemeInfo?> ? themes = null, string ? tooltip = null){
      base (name, tooltip);
      if (themes != null) {
        var liststore = new Gtk.ListStore(2, typeof(string), typeof(string));
        int active = 0;
        bool was_found = false;
        string current_theme = settings.get_string(key);

        foreach(ThemeInfo theme in themes.values) {
          Gtk.TreeIter iter;

          if (current_theme == theme.path){
            was_found = true;
          }
          liststore.append(out iter);
          liststore.set(iter, 0, theme.name);
          liststore.set(iter, 1, theme.path);
          if(!was_found){
            active += 1;
          }
        }

        var dropbox = new Gtk.ComboBox.with_model(liststore);
        var renderer = new Gtk.CellRendererText();
        dropbox.pack_start(renderer, false);
        dropbox.add_attribute(renderer, "text", 0);
        dropbox.set_active(active);
        dropbox.changed.connect(() => {
          Value selected_theme;
          Gtk.TreeIter iter;
          dropbox.get_active_iter(out iter);
          liststore.get_value(iter, 1, out selected_theme);
          settings.set_string(key, (string)selected_theme);
          changed();
        });

        this.pack_end(dropbox, false, false, 0);
      } else {
        var theme_label = new Gtk.Label(_("Default"));

        this.pack_end(theme_label, false, false, 0);
      }
  }

}


public class FeedReader.SettingDropbox : FeedReader.Setting {

	public SettingDropbox(string name, GLib.Settings settings, string key, string[] values, string? tooltip = null)
	{
		base(name, tooltip);
		var liststore = new Gtk.ListStore(1, typeof(string));

		foreach(string val in values)
		{
			Gtk.TreeIter iter;
			liststore.append(out iter);
			liststore.set(iter, 0, val);
		}

		var dropbox = new Gtk.ComboBox.with_model(liststore);
		var renderer = new Gtk.CellRendererText();
		dropbox.pack_start(renderer, false);
		dropbox.add_attribute(renderer, "text", 0);
		dropbox.set_active(settings.get_enum(key));
		dropbox.changed.connect(() => {
			settings.set_enum(key, dropbox.get_active());
			changed();
		});

		this.pack_end(dropbox, false, false, 0);
	}
}


public class FeedReader.SettingSwitch : FeedReader.Setting {

	public SettingSwitch(string name, GLib.Settings settings, string key, string? tooltip = null)
	{
		base(name, tooltip);

		var Switch = new Gtk.Switch();
		Switch.active = settings.get_boolean(key);

		Switch.notify["active"].connect(() => {
			settings.set_boolean(key, Switch.active);
			changed();
		});

		this.pack_end(Switch, false, false, 0);
	}
}


public class FeedReader.SettingSpin : FeedReader.Setting {

	public SettingSpin(string name, GLib.Settings settings, string key, int min, int max, int step, string? tooltip = null)
	{
		base(name, tooltip);

		var spin = new Gtk.SpinButton.with_range(min, max, step);
		spin.set_value(settings.get_int(key));

		spin.value_changed.connect(() => {
			settings.set_int(key, spin.get_value_as_int());
			changed();
		});

		this.pack_end(spin, false, false, 0);
	}
}
