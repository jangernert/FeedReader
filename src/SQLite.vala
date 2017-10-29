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
public class SQLite : GLib.Object {
	private Sqlite.Database m_db;

	public SQLite(string db_path, int busy_timeout = 1000)
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

	public Gee.List<Gee.List<Value?>> execute(string query, string?[]? params = null)
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
					stmt.bind_text(i, param);
				++i;
			}
		}

		var rows = new Gee.ArrayList<Gee.List<Value?>>();
		while(stmt.step() == Sqlite.ROW)
		{
			var row = new Gee.ArrayList<Value?>();
			for(int i = 0; i < stmt.column_count(); ++i)
			{
				Value? value;
				switch(stmt.column_type(i))
				{
				case Sqlite.INTEGER:
					value = Value(typeof(int));
					value.set_int(stmt.column_int(i));
					break;
				case Sqlite.FLOAT:
					value = Value(typeof(double));
					value.set_double(stmt.column_double(i));
					break;
				case Sqlite.BLOB:
					value = Value(typeof(void*));
					value.set_pointer(stmt.column_blob(i));
					break;
				case Sqlite.NULL:
					value = null;
					break;
				case Sqlite.TEXT:
					value = Value(typeof(string));
					value.take_string(stmt.column_text(i));
					break;
				default:
					throw new SQLiteError.FAIL("Unknown column return type: %d".printf(stmt.column_type(i)));
				}
				row.add(value);
			}
			rows.add(row);
		}
		stmt.reset ();

		return rows;
	}
}
