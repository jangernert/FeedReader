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

public class FeedReader.MediaPlayer : Gtk.Box {

	private dynamic Gst.Element m_player;
	private dynamic Gtk.Widget m_videoWidget;
	private Gtk.Stack m_playStack;
	private Gtk.Button m_playButton;
	private Gtk.Spinner m_playSpinner;
	private Gtk.Button m_muteButton;
	private Gtk.Button m_closeButton;
	private Gtk.Scale m_scale;
	private Gtk.Button m_labelButton;
	private Gtk.Label m_bufferLabel;
	private int m_margin = 20;
	private Gtk.Image m_playIcon;
	private Gtk.Image m_pauseIcon;
	private Gtk.Image m_muteIcon;
	private Gtk.Image m_noiseIcon;
	private Gtk.Image m_closeIcon;
	private bool m_muted = false;
	private double m_aspectRatio = 0.0;
	private uint m_seek_source_id = 0;
	private MediaType m_type;
	private string m_URL;
	private DisplayPosition m_display = DisplayPosition.ALL;
	public signal void loaded();

	public MediaPlayer(string url)
	{
		m_type = MediaType.AUDIO;
		m_URL = url;

		inspectMedia.begin((obj, res) => {
			buildUI();
			loaded();
			inspectMedia.end(res);
		});
	}

	private async void inspectMedia()
	{
		SourceFunc callback = inspectMedia.callback;

		ThreadFunc<void*> run = () => {
			try
		    {
		        var discoverer = new Gst.PbUtils.Discoverer((Gst.ClockTime)(10*Gst.SECOND));
		        var info = discoverer.discover_uri(m_URL);

		        foreach(Gst.PbUtils.DiscovererStreamInfo i in info.get_stream_list())
				{
					if(i is Gst.PbUtils.DiscovererVideoInfo)
					{
						var v = (Gst.PbUtils.DiscovererVideoInfo)i;
						m_aspectRatio = ((double)v.get_width())/((double)v.get_height());
						m_type = MediaType.VIDEO;
					}
				}
		    }
		    catch (Error e)
		    {
				Logger.error("Unable discover_uri: " + e.message);
			}
			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		};

		new GLib.Thread<void*>("inspectMedia", run);
		yield;
	}

	private void buildUI()
	{
		var gtksink = Gst.ElementFactory.make("gtksink", "sink");
		gtksink.get("widget", out m_videoWidget);
		m_videoWidget.margin_start = m_margin;
		m_videoWidget.margin_end = m_margin;
		m_videoWidget.margin_top = m_margin;
		m_videoWidget.size_allocate.connect(onAllocation);

		m_player = Gst.ElementFactory.make("playbin", "player");
		m_player["video_sink"] = gtksink;
		m_player["volume"] = 1.0;
		m_player["uri"] = m_URL;

		Gst.Bus bus = m_player.get_bus();
		bus.add_watch(GLib.Priority.LOW, busCallback);

		GLib.Timeout.add(500, () => {
			Gst.State state;
			Gst.State pending;
			m_player.get_state(out state, out pending, 1000);
			if(state == Gst.State.PLAYING)
			{
				int64 pos;
				int64 dur;
				m_player.query_position(Gst.Format.TIME, out pos);
				m_player.query_duration(Gst.Format.TIME, out dur);
				double position = (double)pos/1000000000;
				double duration = (double)dur/1000000000;
				double percent = position*100.0/duration;
				if(m_seek_source_id == 0)
					m_scale.set_value(percent);
				calcTime();
			}
			return true;
		}, GLib.Priority.LOW);

		m_playIcon = new Gtk.Image.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		m_pauseIcon = new Gtk.Image.from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		m_muteIcon = new Gtk.Image.from_icon_name("audio-volume-muted-symbolic", Gtk.IconSize.DND);
		m_noiseIcon = new Gtk.Image.from_icon_name("audio-volume-high-symbolic", Gtk.IconSize.DND);
		m_closeIcon = new Gtk.Image.from_icon_name("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

		m_playButton = new Gtk.Button();
		m_playButton.set_image(m_playIcon);
		m_playButton.clicked.connect(togglePause);
		m_playButton.set_tooltip_text(MediaButton.PLAY);
		m_playButton.valign = Gtk.Align.CENTER;
		m_playButton.halign = Gtk.Align.CENTER;
		m_playButton.set_size_request(48, 48);

		m_playSpinner = new Gtk.Spinner();
		m_playStack = new Gtk.Stack();
		m_playStack.add_named(m_playButton, "button");
		m_playStack.add_named(m_playSpinner, "spinner");
		m_playStack.set_visible_child_name("button");

		m_muteButton = new Gtk.Button();
		m_muteButton.set_image(m_noiseIcon);
		m_muteButton.set_tooltip_text(MediaButton.MUTE);
		m_muteButton.clicked.connect(toggleMute);
		m_muteButton.valign = Gtk.Align.CENTER;
		m_muteButton.halign = Gtk.Align.CENTER;
		m_muteButton.set_size_request(48, 48);

		m_closeButton = new Gtk.Button();
		m_closeButton.set_image(m_closeIcon);
		m_closeButton.clicked.connect(() => {
			kill();
		});
		m_closeButton.set_tooltip_text(MediaButton.CLOSE);
		m_closeButton.valign = Gtk.Align.CENTER;
		m_closeButton.halign = Gtk.Align.CENTER;
		m_closeButton.set_size_request(48, 48);

		m_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 100.0, 5.0);
		m_scale.draw_value = false;
		m_scale.set_size_request(200, 48);
		m_scale.change_value.connect(valueChanged);

		m_labelButton = new Gtk.Button.with_label("00:00");
		m_labelButton.set_relief(Gtk.ReliefStyle.NONE);
		m_labelButton.get_style_context().add_class("h3");
		m_labelButton.clicked.connect(switchDisplay);
		m_labelButton.valign = Gtk.Align.CENTER;
		m_labelButton.halign = Gtk.Align.CENTER;
		m_labelButton.set_size_request(48, 48);

		var hBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		hBox.margin = m_margin;
		hBox.pack_start(m_playStack, false, false);
		hBox.pack_start(m_muteButton, false, false);
		hBox.pack_start(m_scale);
		hBox.pack_start(m_labelButton, false, false);
		hBox.pack_start(m_closeButton, false, false);

		m_bufferLabel = new Gtk.Label("0%");
		m_bufferLabel.valign = Gtk.Align.CENTER;
		m_bufferLabel.halign = Gtk.Align.CENTER;
		m_bufferLabel.set_size_request(48, 48);
		m_bufferLabel.no_show_all = true;

		var bufferOverlay = new Gtk.Overlay();
		bufferOverlay.add(m_videoWidget);
		bufferOverlay.add_overlay(m_bufferLabel);

		this.orientation = Gtk.Orientation.VERTICAL;
		this.get_style_context().add_class("osd");
		this.margin = 40;
		if(m_type == MediaType.VIDEO)
			this.pack_start(bufferOverlay, true, true);
		this.pack_start(hBox, false, false);
		this.valign = Gtk.Align.END;
		this.show_all();
	}

	private void togglePause()
	{
		Gst.State state;
		Gst.State pending;
		m_player.get_state(out state, out pending, 1000);

		switch(state)
		{
			case Gst.State.PLAYING:
				m_playButton.set_image(m_playIcon);
				m_playButton.set_tooltip_text(MediaButton.PLAY);
				m_player.set_state(Gst.State.PAUSED);
				break;

			case Gst.State.PAUSED:
			case Gst.State.READY:
			default:
				m_playButton.set_image(m_pauseIcon);
				m_playButton.set_tooltip_text(MediaButton.PAUSE);
				m_player.set_state(Gst.State.PLAYING);
				break;
		}

		if(m_muted)
			m_player["volume"] = 0.0;
		else
			m_player["volume"] = 1.0;
	}

	private void switchDisplay()
	{
		switch(m_display)
		{
			case DisplayPosition.ALL:
				m_display = DisplayPosition.POS;
				break;

			case DisplayPosition.POS:
				m_display = DisplayPosition.LEFT;
				break;

			case DisplayPosition.LEFT:
				m_display = DisplayPosition.ALL;
				break;
		}
		calcTime();
	}

	private void calcTime()
	{
		int64 pos;
		int64 dur;
		m_player.query_position(Gst.Format.TIME, out pos);
		m_player.query_duration(Gst.Format.TIME, out dur);
		double position = (int)((double)pos/1000000000);
		double duration = (int)((double)dur/1000000000);



		double? sd = duration;
		double? md = null;
		double? hd = null;

		if( ((int)sd) >= 60)
		{
			md = (int)(sd/60);
			sd = sd - (md*60);

			if( ((int)md) >= 60)
			{
				hd = (int)(md/60);
				md = md - (hd*60);
			}
		}

		double? sp = position;
		double? mp = null;
		double? hp = null;

		if( ((int)sp) >= 60)
		{
			mp = (int)(sp/60);
			sp = sp - (mp*60);

			if( ((int)mp) >= 60)
			{
				hp = (int)(mp/60);
				mp = mp - (hp*60);
			}
		}

		double? sr = duration - position;
		double? mr = null;
		double? hr = null;

		if( ((int)sr) >= 60)
		{
			mr = (int)(sr/60);
			sr = sr - (mr*60);

			if( ((int)mr) >= 60)
			{
				hr = (int)(mr/60);
				mr = mr - (hr*60);
			}
		}

		var pLabel = "";
		(hp != null) ? pLabel += "%02.0f:".printf(hp) : null;
		(mp != null) ? pLabel += "%02.0f".printf(mp) : null;
		(mp != null) ? pLabel += ":" : pLabel += "0:";
		pLabel += "%02.0f".printf(sp);

		var dLabel = "";
		(hd != null) ? dLabel += "%02.0f:".printf(hd) : null;
		(md != null) ? dLabel += "%02.0f".printf(md) : null;
		(md != null) ? dLabel += ":" : dLabel += "0:";
		dLabel += "%02.0f".printf(sd);

		var rLabel = "-";
		(hr != null) ? rLabel += "%02.0f:".printf(hr) : null;
		(mr != null) ? rLabel += "%02.0f".printf(mr) : null;
		(mr != null) ? rLabel += ":" : rLabel += "0:";
		rLabel += "%02.0f".printf(sr);

		if(dur == -1)
		{
			m_labelButton.set_label(pLabel);
			return;
		}


		switch(m_display)
		{
			case DisplayPosition.ALL:
				m_labelButton.set_label(pLabel + " / " + dLabel);
				break;

			case DisplayPosition.POS:
				m_labelButton.set_label(pLabel);
				break;

			case DisplayPosition.LEFT:
				m_labelButton.set_label(rLabel);
				break;
		}
	}

	private bool valueChanged(Gtk.ScrollType scroll, double new_value)
	{
		m_scale.set_value(new_value);

		if (m_seek_source_id == 0)
		{
			double startValue = new_value;

			m_seek_source_id = GLib.Timeout.add_full(GLib.Priority.DEFAULT, 500, () => {
				if(m_scale.get_value() != startValue)
				{
					startValue = m_scale.get_value();
					return true;
				}
				else
				{
					m_seek_source_id = 0;
					seek(startValue);
					return false;
				}
			});
		}
		return true;
	}

	private void seek(double new_value)
	{
		int64 dur;
		double percent = new_value/100.0;
		m_player.query_duration(Gst.Format.TIME, out dur);
		int64 pos = (int64)(percent * (double)dur);
		m_player.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT,  pos);
		//m_player.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH,  pos);
		m_playButton.set_image(m_pauseIcon);
		m_player.set_state(Gst.State.PLAYING);
	}

	private void toggleMute()
	{
		if(m_muted)
		{
			m_muteButton.set_image(m_noiseIcon);
			m_muteButton.set_tooltip_text(MediaButton.MUTE);
			m_player["volume"] = 1.0;
			m_muted = false;
		}
		else
		{
			m_muteButton.set_image(m_muteIcon);
			m_muteButton.set_tooltip_text(MediaButton.UNMUTE);
			m_player["volume"] = 0.0;
			m_muted = true;
		}
	}

	private bool busCallback(Gst.Bus bus, Gst.Message message)
	{
		switch (message.type)
		{
			case Gst.MessageType.ERROR:
				GLib.Error err;
				string debug;
				message.parse_error(out err, out debug);
				Logger.error("MediaPlayer: " + err.message);
				m_player.set_state(Gst.State.NULL);
				break;

			case Gst.MessageType.EOS:
				m_player.set_state(Gst.State.READY);
				m_playButton.set_image(m_playIcon);
				break;

			case Gst.MessageType.BUFFERING:
				int percent = 0;
				message.parse_buffering(out percent);
				if(percent < 100)
				{
					m_player.set_state(Gst.State.PAUSED);

					if(m_type == MediaType.VIDEO)
					{
						m_bufferLabel.set_text(percent.to_string() + "%");
						m_bufferLabel.show();
					}
					else
					{
						m_playStack.set_visible_child_name("spinner");
						m_playSpinner.start();
					}
				}
				else
				{
					m_player.set_state(Gst.State.PLAYING);
					if(m_type == MediaType.VIDEO)
						m_bufferLabel.hide();
					else
						m_playStack.set_visible_child_name("button");
				}
				break;

			case Gst.MessageType.STATE_CHANGED:
				Gst.State oldstate;
				Gst.State newstate;
				Gst.State pending;
				message.parse_state_changed(out oldstate, out newstate, out pending);
		        break;
		}
		return true;
	}

	private void onAllocation(Gtk.Allocation allocation)
	{
		if(m_aspectRatio != 0)
		{
			double width = (double)allocation.width;
			int height = (int)(width/m_aspectRatio);
			m_videoWidget.set_size_request(-1, height);
		}
	}

	public void kill()
	{
		m_player.set_state(Gst.State.NULL);
		this.destroy();
	}

}
