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

public class FeedReader.imagePopup : Gtk.Window {

	private Gtk.ScrolledWindow m_scroll;
	private Gtk.ImageView m_image;
	private Gtk.Scale m_scale;
	private Gtk.Revealer m_scaleRevealer;
	private Gtk.EventBox m_eventBox;
	private Gtk.Overlay m_overlay;
	private Gtk.Revealer m_revealer;
	private Gtk.ToggleButton m_zoomButton;
	private double m_dndX;
	private double m_dndY;
	private double m_adjX;
	private double m_adjY;
	private double m_dragBufferX[10];
	private double m_dragBufferY[10];
	private double m_momentumX = 0;
	private double m_momentumY = 0;
	private double m_posX = 0;
	private double m_posY = 0;
	private bool m_hoverHeader = false;
	private bool m_hoverImage = false;
	private bool m_dragWindow = false;
	private bool m_inDrag = false;
	private uint m_OngoingScrollID = 0;
	private double m_maxZoom = 5.0;
	private double m_minZoom = 0.2;
	private double m_initZoom = 1.0;

	public imagePopup(string imagePath, string? url, Gtk.Window parent, double img_height, double img_width)
	{
		this.title = "";
		this.decorated = false;
		this.can_focus = false;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		this.transient_for = parent;
		this.modal = true;
		this.button_press_event.connect((evt) => {
			if(!m_hoverImage && !m_hoverHeader)
			{
				closeWindow();
				return true;
			}
			return false;
		});

		var file = GLib.File.new_for_path(imagePath);
		m_image = new Gtk.ImageView();
		m_image.zoomable = true;
		m_image.load_from_file_async.begin (file, 0);

		m_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, m_minZoom, m_maxZoom, 0.2);
		m_scale.set_size_request(200, 0);
		m_scale.value_changed.connect (() => {
			m_image.scale = m_scale.get_value();
		});

		m_scaleRevealer = new Gtk.Revealer();
		m_scaleRevealer.valign = Gtk.Align.START;
		m_scaleRevealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_RIGHT);
		m_scaleRevealer.add(m_scale);

		double win_width  = (int)(Gdk.Screen.width()*0.8);
		double win_height = (int)(Gdk.Screen.height()*0.8);
		double min_height = 300;
		double min_widht = 500;

		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.add(m_image);



		if(img_width <= win_width)
		{
			if(img_width < min_widht)
			{
				win_width = min_widht;
			}
			else
			{
				win_width = img_width;
			}
		}
		else if(img_width > win_width)
		{
			m_initZoom = win_width/img_width;
			m_image.scale = m_initZoom;
		}

		if(img_height * m_initZoom <= win_height) {
			if(img_height < min_height)
			{
				win_height = min_height;
			}
			else
			{
				win_height = img_height * m_initZoom;
			}
		}

		m_image.notify["scale"].connect(onImageScrolled);
		m_zoomButton = new Gtk.ToggleButton();
		m_zoomButton.add(new Gtk.Image.from_icon_name("zoom-in-symbolic", Gtk.IconSize.BUTTON));
		m_zoomButton.get_style_context().add_class("headerbutton");
		m_zoomButton.toggled.connect(() => {
			if(!m_zoomButton.get_active())
				m_image.notify["scale"].disconnect(onImageScrolled);
			if(m_zoomButton.get_active())
			{
				m_scale.set_value(m_image.scale);
				m_scaleRevealer.set_reveal_child(true);
			}
			else
			{
				m_image.scale = m_initZoom;
				m_scaleRevealer.set_reveal_child(false);
			}

			if(!m_zoomButton.get_active())
			{
				GLib.Timeout.add(150, () => {
				    m_image.notify["scale"].connect(onImageScrolled);
					return false;
				});
			}
		});

		var header = new Gtk.HeaderBar ();
		header.show_close_button = true;
		header.set_size_request(0, 30);
		header.get_style_context().add_class("imageOverlay");
		header.pack_start(m_zoomButton);
		header.pack_start(m_scaleRevealer);
		var headerEvents = new Gtk.EventBox();
		headerEvents.button_press_event.connect(headerButtonPressed);
		headerEvents.enter_notify_event.connect(() => {
			m_hoverHeader = true;
			m_dragWindow = false;
			return false;
		});
		headerEvents.leave_notify_event.connect((event) => {
			if(event.detail != Gdk.NotifyType.VIRTUAL && event.mode != Gdk.CrossingMode.NORMAL)
				return false;

			m_hoverHeader = false;
			return false;
		});
		headerEvents.add(header);

		if(url != null)
		{
			var urlButton = new Gtk.Button.with_label("Open URL");
			urlButton.set_tooltip_text(url);
			urlButton.get_style_context().add_class("headerbutton");
			urlButton.clicked.connect(() => {
				try{
					Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
				}
				catch(GLib.Error e){
					logger.print(LogMessage.DEBUG, "could not open the link in an external browser: %s".printf(e.message));
				}
			});
			header.pack_start(urlButton);
		}

		m_revealer = new Gtk.Revealer();
		m_revealer.valign = Gtk.Align.START;
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(headerEvents);

		m_overlay = new Gtk.Overlay();
		m_overlay.add(m_scroll);
		m_overlay.add_overlay(m_revealer);


		m_eventBox = new Gtk.EventBox();
		m_eventBox.button_press_event.connect(eventButtonPressed);
		m_eventBox.button_release_event.connect(eventButtonReleased);
		m_eventBox.enter_notify_event.connect(onEnter);
		m_eventBox.leave_notify_event.connect(onLeave);
		m_eventBox.key_press_event.connect(keyPressed);
		m_eventBox.add(m_overlay);

		this.add(m_eventBox);
		this.set_size_request((int)win_width, (int)win_height);
		this.show_all();
	}

	public void onImageScrolled()
	{
		if(m_image.scale > m_maxZoom)
		{
			m_image.scale = m_maxZoom;
			return;
		}

		if(m_image.scale < m_minZoom)
		{
			m_image.scale = m_minZoom;
			return;
		}

		m_zoomButton.set_active(true);
		m_scaleRevealer.set_reveal_child(true);
		m_scale.set_value(m_image.scale);
	}

	private bool headerButtonPressed(Gdk.EventButton evt)
	{
		if(evt.button == MouseButton.LEFT)
		{
			m_dragWindow = true;
			this.get_window().begin_move_drag(MouseButton.LEFT, (int)evt.x_root, (int)evt.y_root, Gdk.CURRENT_TIME);
			return true;
		}
		return false;
	}

	private bool motionNotify(Gdk.EventMotion evt)
	{
		if((evt.state & Gdk.ModifierType.MODIFIER_MASK) >= Gdk.ModifierType.BUTTON2_MASK)
		{
			m_posX = evt.x;
			m_posY = evt.y;
			double diff_x = m_dndX - evt.x;
			double diff_y = m_dndY - evt.y;
			m_scroll.vadjustment.value = m_adjY + diff_y;
			m_scroll.hadjustment.value = m_adjX + diff_x;
			return true;
		}
		return false;
	}

	private bool eventButtonPressed(Gdk.EventButton evt)
	{
		if(!m_hoverHeader)
		{
			if(evt.button == MouseButton.MIDDLE)
			{
				if(m_OngoingScrollID > 0)
				{
		            GLib.Source.remove(m_OngoingScrollID);
		            m_OngoingScrollID = 0;
		        }
				m_posX = evt.x;
				m_posY = evt.y;
				for(int i = 0; i < 10; ++i)
				{
					m_dragBufferX[i] = m_posX;
					m_dragBufferY[i] = m_posY;
				}
				m_inDrag = true;
				var display = Gdk.Display.get_default();
				var pointer = display.get_device_manager().get_client_pointer();
				var cursor = new Gdk.Cursor.for_display(display, Gdk.CursorType.FLEUR);

				pointer.grab(
					this.get_window(),
					Gdk.GrabOwnership.NONE,
					false,
					Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK,
					cursor,
					Gdk.CURRENT_TIME
				);

				// Gtk+ 3.20
				/*var seats = display.get_default_seat();
				seat.grab(
					this.get_window(),
					Gdk.SeatCapabilities.POINTER,
					false,
					cursor,
					null, //Event? event
					null //SeatGrabPrepareFunc? prepare_func
				);*/

				Gtk.device_grab_add(m_eventBox, pointer, false);

				m_dndX = evt.x;
				m_dndY = evt.y;
				m_adjX = m_scroll.hadjustment.value;
				m_adjY = m_scroll.vadjustment.value;
				GLib.Timeout.add(10, updateDragMomentum);
				m_eventBox.motion_notify_event.connect(motionNotify);
				return true;
			}
			else if(evt.button == MouseButton.LEFT)
			{
				closeWindow();
			}
		}
		return false;
	}

	private bool eventButtonReleased(Gdk.EventButton evt)
	{
		if(evt.button == MouseButton.MIDDLE)
		{
			m_posX = 0;
			m_posY = 0;
			m_inDrag = false;
			var pointer = Gdk.Display.get_default().get_device_manager().get_client_pointer();
			Gtk.device_grab_remove(m_eventBox, pointer);
			pointer.ungrab(Gdk.CURRENT_TIME);
			m_eventBox.motion_notify_event.disconnect(motionNotify);
			m_OngoingScrollID = GLib.Timeout.add(20, ScrollDragRelease);
			return true;
		}
		return false;
	}


	private bool keyPressed(Gdk.EventKey evt)
	{
		if(evt.keyval == Gdk.Key.Escape)
		{
			closeWindow();
		}
		return false;
	}

	private bool onEnter(Gdk.EventCrossing event)
	{
		m_hoverImage = true;
		m_revealer.set_reveal_child(true);
		m_revealer.show();
		return true;
	}

	private bool onLeave(Gdk.EventCrossing event)
	{
		if(event.detail != Gdk.NotifyType.VIRTUAL && event.mode != Gdk.CrossingMode.NORMAL)
			return false;

		if(m_dragWindow)
			return false;

		m_hoverImage = false;
		m_revealer.set_reveal_child(false);
		return true;
	}

	private bool updateDragMomentum()
	{
		if(!m_inDrag)
			return false;

		for(int i = 9; i > 0; --i)
		{
			m_dragBufferX[i] = m_dragBufferX[i-1];
			m_dragBufferY[i] = m_dragBufferY[i-1];
		}

		m_dragBufferX[0] = m_posX;
		m_dragBufferY[0] = m_posY;
		m_momentumX = (m_dragBufferX[9] - m_dragBufferX[0])/2;
		m_momentumY = (m_dragBufferY[9] - m_dragBufferY[0])/2;

		return true;
	}

	private bool ScrollDragRelease()
	{
		if(m_inDrag)
			return true;

		Gtk.Allocation allocation;
		this.get_allocation(out allocation);

		if(m_momentumX != 0)
		{
			m_momentumX /= 1.2;
			double pageWidth = this.get_allocated_width();
			double adjhValue = pageWidth * m_momentumX / allocation.width;
			double oldhAdj = m_scroll.hadjustment.value;
			double upperH = m_scroll.hadjustment.upper;
			if ((oldhAdj + adjhValue) > (upperH - pageWidth)
			|| (oldhAdj + adjhValue) < 0)
			{
				m_momentumX = 0;
			}
			double newXScrollPos = double.min(oldhAdj + adjhValue, upperH - pageWidth);
			m_scroll.hadjustment.value = (int)newXScrollPos;
		}

		if(m_momentumY != 0)
		{
			m_momentumY /= 1.2;
			double pageHeight = this.get_allocated_height();
			double adjvValue = pageHeight * m_momentumY / allocation.height;
			double oldvAdj = m_scroll.vadjustment.value;
			double upperV = m_scroll.vadjustment.upper;
			if ((oldvAdj + adjvValue) > (upperV - pageHeight)
			|| (oldvAdj + adjvValue) < 0)
			{
				m_momentumY = 0;
			}
			double newYScrollPos = double.min(oldvAdj + adjvValue, upperV - pageHeight);
			m_scroll.vadjustment.value = (int)newYScrollPos;
		}

		if((m_momentumX < 1 && m_momentumX > -1) && (m_momentumY < 1 && m_momentumY > -1))
		{
			m_OngoingScrollID = 0;
			return false;
		}
		else
			return true;
	}

	private void closeWindow()
	{
		if(m_OngoingScrollID != 0)
		{
			GLib.Source.remove(m_OngoingScrollID);
			m_OngoingScrollID = 0;
		}
		this.destroy();
	}
}
