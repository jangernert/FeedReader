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

public errordomain SQLiteError
{
	FAIL
}

/* A wrapper around the low-level SQLite API */
public class FeedReader.SQLite : GLib.Object {
	private Sqlite.Database m_db;

	public SQLite(string db_path, int busy_timeout = 1000)
	{
		if(!db_path.contains(":memory:"))
		{
			var path = GLib.File.new_for_path(db_path);
			var parent = path.get_parent();
			if(!parent.query_exists())
			{
				try
				{
					parent.make_directory_with_parents();
				}
				catch(IOError.EXISTS e)
				{
				}
				catch(GLib.Error e)
				{
					Logger.error("SQLite: " + e.message);
				}
			}
		}

		int rc = Sqlite.Database.open_v2(db_path, out m_db);
		if(rc != Sqlite.OK)
			throw new SQLiteError.FAIL("Can't open database: %d: %s".printf(m_db.errcode(), m_db.errmsg()));

		m_db.busy_timeout(busy_timeout);
	}

	// Backwards compatibility interface
	public Sqlite.Statement prepare(string query)
	{
		Sqlite.Statement stmt;
		int rc = m_db.prepare_v2(query, query.length, out stmt);
		if(rc != Sqlite.OK)
			throw new SQLiteError.FAIL("Can't prepare statement: %d: %s\nSQL is %s".printf(m_db.errcode(), m_db.errmsg(), query));
		return stmt;
	}

	public string errmsg()
	{
		return m_db.errmsg();
	}

	public void checkpoint()
	{
		m_db.wal_checkpoint("");
	}

	public void simple_query(string query)
	{
		string errmsg;
		int ec = m_db.exec(query, null, out errmsg);
		if (ec != Sqlite.OK)
		{
			throw new SQLiteError.FAIL("Failed to execute simple query: %d: %s\nSQL is: %s".printf(ec, errmsg, query));
		}
	}

	public Gee.List<Gee.List<Sqlite.Value?>> execute(string query, Value?[]? params = null)
	{
		Sqlite.Statement stmt;
		int rc = m_db.prepare_v2(query, query.length, out stmt);
		if (rc != Sqlite.OK)
		{
			throw new SQLiteError.FAIL("Can't prepare statement: %d: %s\nSQL is: %s".printf(m_db.errcode(), m_db.errmsg(), query));
		}

		if(params != null)
		{
			int i = 1;
			foreach(var param in params)
			{
				if(param == null)
					stmt.bind_null(i);
				else
				{
					// The order of operations matters here because floats and doubles
					// are transformable to int, and anything is transformable to
					// string
					if(param.holds(typeof(float)) || param.holds(typeof(double)))
					{
						var as_double = Value(typeof(double));
						param.transform(ref as_double);
						stmt.bind_double(i, (double)as_double);
					}
					else if(Value.type_transformable(param.type(), typeof(int64)))
					{
						var as_int = Value(typeof(int64));
						param.transform(ref as_int);
						stmt.bind_int64(i, (int64)as_int);
					}
					else
					{
						var as_string = Value(typeof(string));
						param.transform(ref as_string);
						stmt.bind_text(i, (string)as_string);
					}
				}
				++i;
			}
		}

		var rows = new Gee.ArrayList<Gee.List<Sqlite.Value?>>();
		while(stmt.step() == Sqlite.ROW)
		{
			var row = new Gee.ArrayList<Sqlite.Value?>();
			for(int i = 0; i < stmt.column_count(); ++i)
			{
				row.add(stmt.column_value(i).copy());
			}
			rows.add(row);
		}
		stmt.reset ();

		return rows;
	}
}
