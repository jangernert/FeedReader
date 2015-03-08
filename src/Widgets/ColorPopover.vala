
public class FeedReader.ColorPopover : Gtk.Popover {
	private Gtk.Grid m_grid;
	public signal void newColorSelected(int color);


	public ColorPopover(Gtk.Widget widget)
	{
		m_grid = new Gtk.Grid();
		m_grid.set_column_spacing(5);
		m_grid.set_row_spacing(5);
		m_grid.set_column_homogeneous(true);
		m_grid.set_row_homogeneous(true);
		m_grid.set_halign(Gtk.Align.CENTER);
		m_grid.set_valign(Gtk.Align.CENTER);
		m_grid.margin = 5;
		int columns = 4;
		int rows = COLORS.length/4;
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

		m_grid.show_all();
		this.add(m_grid);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
	}
}
