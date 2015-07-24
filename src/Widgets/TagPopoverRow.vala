public class FeedReader.TagPopoverRow : Gtk.ListBoxRow {

    private Gtk.Box m_box;
    private string m_tagID;

    public TagPopoverRow(tag Tag)
    {
        m_tagID = Tag.getTagID();
        m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var circle = new ColorCircle(Tag.getColor(), false);
        circle.margin_start = 2;
        var label = new Gtk.Label(Tag.getTitle());
        label.set_alignment(0, 0.5f);
        var clear = new Gtk.Image.from_icon_name("edit-clear-symbolic", Gtk.IconSize.MENU);
        m_box.pack_start(circle, false, false, 0);
        m_box.pack_start(label, true, true, 0);
        m_box.pack_end(clear, false, false, 0);

        this.add(m_box);
        this.margin_top = 1;
        this.margin_bottom = 1;
    }
}
