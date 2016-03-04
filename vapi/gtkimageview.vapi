

namespace Gtk {
  [CCode (cheader_filename = "gtkimageview.h")]
  public class ImageView : Gtk.Widget {
    public ImageView ();

    public bool fit_allocation { get; set; }
    public bool scale_set { get; }
    public bool transitions_enabled { get; set; }
    public bool zoomable { get; set; }
    public bool rotatable { get; set; }
    public bool snap_angle { get; set; }
    public double angle { get; set; }
    public double scale { get; set; }


    public async void load_from_stream_async (GLib.InputStream input_stream,
                                              int scale_factor,
                                              GLib.Cancellable? cancellable = null);

    public async void load_from_file_async (GLib.File file,
                                            int scale_factor,
                                            GLib.Cancellable? cancellable = null) throws GLib.Error;

    public void set_animation (Gdk.PixbufAnimation animation);
    public void set_pixbuf (Gdk.Pixbuf pixbuf);
    public void set_surface (Cairo.Surface? surface);
  }
}
