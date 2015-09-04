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

public class FeedReader.InitSyncPage : Gtk.Bin {

	private Gtk.Spinner m_spinner;
	private Gtk.Box m_spinnerBox;
	private Gtk.Box m_layout;
	private Gtk.Label m_label;
	private Gtk.ProgressBar m_progress;
	public signal void finished();

	public InitSyncPage() {
		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(40, 40);
		m_spinner.start();

		var label = new Gtk.Label(_("FeedReader is now getting the first batch of articles.\nDepending on your connection and settings this can take some time."));
		label.get_style_context().add_class("h2");
		label.set_alignment(0, 0.5f);
		label.set_ellipsize (Pango.EllipsizeMode.END);
		label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		label.set_line_wrap(true);
		label.set_lines(2);

		m_spinnerBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
		m_spinnerBox.pack_start(m_spinner, false, true, 0);
		m_spinnerBox.pack_start(label, false, true, 0);

		m_progress = new Gtk.ProgressBar();
		m_progress.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
		m_progress.set_text("");
		m_progress.set_show_text(true);
		m_progress.set_fraction(0);

		m_label = new Gtk.Label("");
		m_label.get_style_context().add_class("h4");
		m_label.set_alignment(0.5f, 0.5f);
		m_label.set_ellipsize (Pango.EllipsizeMode.MIDDLE);

		m_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 20);
		m_layout.pack_start(m_spinnerBox, false, true, 0);
		m_layout.pack_start(m_progress, false, true, 0);
		m_layout.pack_start(m_label, false, true, 0);

		this.set_halign(Gtk.Align.CENTER);
		this.set_valign(Gtk.Align.CENTER);
		this.margin = 20;
		this.add(m_layout);


		feedDaemon_interface.initSyncStage.connect((stage) => {
			logger.print(LogMessage.DEBUG, "InitSyncPage: stage %i".printf(stage));
			setStage(stage);
		});

		feedDaemon_interface.initSyncTag.connect((tagName) => {
			setCurrentTag(tagName);
		});

		feedDaemon_interface.initSyncFeed.connect((feedName) => {
			setCurrentFeed(feedName);
		});

		if(settings_state.get_int("initial-sync-level") != 0)
		{
			setStage(settings_state.get_int("initial-sync-level")-1);
		}
	}


	public void start(bool useGrabber)
	{
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 2, () => {
			try{
				feedDaemon_interface.startInitSync(useGrabber);
			}catch (IOError e) {
				logger.print(LogMessage.ERROR, e.message);
			}
			return false;
		});
	}

	private void setCurrentTag(string tag)
	{
		if(tag == "")
		{
			m_label.set_text("");
			return;
		}

		m_label.set_text("(Getting articles for: %s)".printf(tag));
	}

	private void setCurrentFeed(string feed)
	{
		if(feed == "")
		{
			m_label.set_text("");
			return;
		}

		m_label.set_text("(Getting articles for: %s)".printf(feed));
	}

	private void setStage(int stage)
	{
		settings_state.set_int("initial-sync-level", stage);
		double progress = m_progress.get_fraction ();
		progress = progress + 0.1;
		if(progress < 1.0)
			m_progress.set_fraction(progress);
	}
}
