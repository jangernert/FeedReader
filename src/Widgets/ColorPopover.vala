
public class ColorPopover : Gtk.Popover {
	private Gtk.Grid m_grid;
	private Gtk.Alignment m_align;
	public signal void newColorSelected(int color);
	
	
	public ColorPopover(Gtk.Widget widget)
	{
		m_align = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
		m_align.set_padding(5, 5, 5, 5);
		m_grid = new Gtk.Grid();
		m_grid.set_column_spacing(5);
		m_grid.set_row_spacing(5);
		m_grid.set_column_homogeneous(true);
		m_grid.set_row_homogeneous(true);
		int columns = 4;
		int rows = COLORS.length/4;
		Gdk.Pixbuf tmpIcon;
		int color = 0;
		ColorCircle tmpCircle;
		
		for(int i = 0; i < rows; ++i)
		{
			for(int j = 0; j < columns; ++j)
			{
				tmpCircle = new ColorCircle(color);
				tmpCircle.clicked.connect((color) => {
					newColorSelected(color);
					this.hide();
				});
				m_grid.attach(tmpCircle, j, i, 1, 1);
				++color;
			}
		}
		
		m_align.add(m_grid);
		m_align.show_all();
		this.add(m_align);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
	}
}
