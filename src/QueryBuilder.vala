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

public enum FeedReader.QueryType {
	INSERT,
	INSERT_OR_IGNORE,
	INSERT_OR_REPLACE,
	UPDATE,
	SELECT,
	DELETE
}

public class FeedReader.QueryBuilder : GLib.Object {
	private QueryType m_type;
	private string m_table;
	private Gee.List<string> m_fields = new Gee.ArrayList<string>();
	private Gee.List<string> m_values = new Gee.ArrayList<string>();
	private Gee.List<string> m_conditions = new Gee.ArrayList<string>();
	private string? m_order_by_column = null;
	private bool m_order_descending = false;
	private uint? m_limit = null;
	private uint? m_offset = null;

	public QueryBuilder(QueryType type, string table)
	{
		m_type = type;
		m_table = table;
	}

	private void insert_value_pair(string field, string value)
	requires (m_type == QueryType.INSERT
		|| m_type == QueryType.INSERT_OR_IGNORE
	|| m_type == QueryType.INSERT_OR_REPLACE)
	{
		m_fields.add(field);
		m_values.add(value);
	}

	public void insert_param(string field, string value)
	requires (value.has_prefix("$") && !value.contains("'"))
	{
		insert_value_pair(field, value);
	}

	public void insert_int(string field, int64 value)
	{
		insert_value_pair(field, value.to_string());
	}

	public void select_field(string field)
	requires (m_type == QueryType.SELECT)
	{
		m_fields.add(field);
	}

	private void update(string field, string value)
	requires (m_type == QueryType.UPDATE)
	{
		m_fields.add(field);
		m_values.add(value);
	}

	public void update_param(string field, string value)
	requires (value.has_prefix("$") && !value.contains("'"))
	{
		update(field, value);
	}

	public void update_string(string field, string value)
	{
		update(field, SQLite.quote_string(value));
	}

	public void update_int(string field, int64 value)
	{
		update(field, value.to_string());
	}

	private void where_equal(string field, string safe_value)
	requires (m_type == QueryType.UPDATE
		|| m_type == QueryType.SELECT
	|| m_type == QueryType.DELETE)
	{

		m_conditions.add("%s = %s".printf(field, safe_value));
	}

	public void where_equal_param(string field, string value)
	requires (value.has_prefix("$") && !value.contains("'"))
	{
		where_equal(field, value);
	}

	public void where_equal_int(string field, int64 value)
	{
		where_equal(field, value.to_string());
	}

	public void where_equal_string(string field, string value)
	{
		where_equal(field, SQLite.quote_string(value));
	}

	public void where(string condition)
	requires (m_type == QueryType.UPDATE
		|| m_type == QueryType.SELECT
	|| m_type == QueryType.DELETE)
	{
		m_conditions.add(condition);
	}

	public void where_in_strings(string field, Gee.List<string> values)
	requires (m_type == QueryType.UPDATE
		|| m_type == QueryType.SELECT
	|| m_type == QueryType.DELETE)
	{
		if (values.size == 0)
		{
			m_conditions.add("1 <> 1");
		}
		else
		{
			var compound_values = new GLib.StringBuilder();
			foreach(string value in values)
			{
				compound_values.append(SQLite.quote_string(value));
				compound_values.append(", ");
			}
			compound_values.erase(compound_values.len - 2);
			m_conditions.add("%s IN (%s)".printf(field, compound_values.str));
		}
	}

	public void order_by(string field, bool desc)
	requires (m_type == QueryType.SELECT)
	{
		m_order_by_column = field;
		m_order_descending = desc;
	}

	public void limit(uint limit)
	requires (m_type == QueryType.SELECT)
	{
		m_limit = limit;
	}

	public void offset(uint offset)
	requires (m_type == QueryType.SELECT)
	{
		m_offset = offset;
	}

	public string to_string()
	{
		var query = new GLib.StringBuilder();
		switch(m_type)
		{
			case QueryType.INSERT:
			case QueryType.INSERT_OR_IGNORE:
			case QueryType.INSERT_OR_REPLACE:
			query.append("INSERT ");

			if(m_type == QueryType.INSERT_OR_IGNORE)
			{
				query.append("OR IGNORE ");
			}
			else if(m_type == QueryType.INSERT_OR_REPLACE)
			{
				query.append("OR REPLACE ");
			}

			query.append_printf("INTO %s (", m_table);
				StringUtils.stringbuilder_append_join(query, m_fields, ", ");
				query.append(") VALUES (");
				StringUtils.stringbuilder_append_join(query, m_values, ", ");
			query.append_c(')');
			break;

			case QueryType.UPDATE:
			query.append_printf("UPDATE %s SET ", m_table);

			assert(m_fields.size > 0);
			for(int i = 0; i < m_fields.size; i++)
			{
				if (i > 0)
				{
					query.append(", ");
				}

				query.append(m_fields.get(i));
				query.append(" = ");
				query.append(m_values.get(i));
			}

			append_conditions(query);
			break;


			case QueryType.DELETE:
			query.append("DELETE FROM ");
			query.append(m_table);
			append_conditions(query);
			break;


			case QueryType.SELECT:
			query.append("SELECT ");
			StringUtils.stringbuilder_append_join(query, m_fields, ", ");
			query.append_printf(" FROM %s", m_table);

			append_conditions(query);

			if (m_order_by_column != null)
			{
				query.append_printf(
					" ORDER BY %s COLLATE NOCASE %s",
					m_order_by_column,
				m_order_descending ? "DESC" : "ASC");
			}

			if (m_limit != null)
			{
				query.append_printf(" LIMIT %u", m_limit);
			}

			if (m_offset != null)
			{
				query.append_printf(" OFFSET %u", m_offset);
			}
			break;
		}

		return query.str;
	}

	private void append_conditions(StringBuilder query)
	{
		if(m_conditions.size == 0)
		{
			return;
		}

		query.append(" WHERE ");
		StringUtils.stringbuilder_append_join(query, m_conditions, " AND ");
	}

	public void print()
	{
		Logger.debug(to_string());
	}
}
