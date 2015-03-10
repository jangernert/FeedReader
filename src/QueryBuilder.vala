public class FeedReader.QueryBuilder : GLib.Object {

    private GLib.StringBuilder m_query;
    private QueryType m_type;
    private string m_table;
    private bool m_noError;
    private GLib.List<string> m_fields;
    private GLib.List<string> m_values;
    private GLib.List<string> m_conditions;
    private GLib.StringBuilder m_insert_fields;
    private GLib.StringBuilder m_insert_values;
    private string m_orderBy;
    private string m_limit;
    private string m_offset;

    public QueryBuilder(QueryType type, string table)
    {
        m_query = new GLib.StringBuilder();
        m_fields = new GLib.List<string>();
        m_values = new GLib.List<string>();
        m_conditions = new GLib.List<string>();
        m_type = type;
        m_table = table;
        m_noError = true;
        m_orderBy = "";
        m_limit = "";
        m_offset = "";
        m_insert_fields = new GLib.StringBuilder();
        m_insert_values = new GLib.StringBuilder();
    }

    public bool insertValuePair(string field, string value)
    {
        switch(m_type)
        {
            case QueryType.INSERT:
            case QueryType.INSERT_OR_IGNORE:
            case QueryType.INSERT_OR_REPLACE:
                m_fields.append(field);
                m_values.append(value);
                return true;
        }
        logger.print(LogMessage.ERROR, "insertValuePair");
        m_noError = false;
        return m_noError;
    }

    public bool selectField(string field)
    {
        if(m_type == QueryType.SELECT)
        {
            m_fields.append(field);
            return true;
        }
        logger.print(LogMessage.ERROR, "selectField");
        m_noError = false;
        return m_noError;
    }

    public bool updateValuePair(string field, string value)
    {
        if(m_type == QueryType.UPDATE)
        {
            m_fields.append(field);
            m_values.append(value);
            return true;
        }
        logger.print(LogMessage.ERROR, "updateValuePair");
        m_noError = false;
        return m_noError;
    }

    public bool addEqualsCondition(string field, string value)
    {
        if(m_type == QueryType.UPDATE
        || m_type == QueryType.SELECT)
        {
            m_conditions.append("%s = %s".printf(field, value));
            return true;
        }
        logger.print(LogMessage.ERROR, "addEqualsConditionString");
        m_noError = false;
        return m_noError;
    }

    public bool addCustomCondition(string condition)
    {
        if(m_type == QueryType.UPDATE
        || m_type == QueryType.SELECT)
        {
            m_conditions.append(condition);
            return true;
        }
        logger.print(LogMessage.ERROR, "addCustomCondition");
        m_noError = false;
        return m_noError;
    }

    public bool addRangeConditionString(string field, GLib.List<string> values)
    {
        if(m_type == QueryType.UPDATE
        || m_type == QueryType.SELECT)
        {
            var compound_values = new GLib.StringBuilder();
            foreach(string value in values)
            {
                compound_values.append("\"");
                compound_values.append(value);
                compound_values.append("\",");
            }
            compound_values.erase(compound_values.len-1);
            m_conditions.append("%s IN (%s)".printf(field, compound_values.str));
            return true;
        }
        logger.print(LogMessage.ERROR, "addRangeConditionString");
        m_noError = false;
        return m_noError;
    }

    public bool addRangeConditionInt(string field, GLib.List<int> values)
    {
        if(m_type == QueryType.UPDATE
        || m_type == QueryType.SELECT)
        {
            var compound_values = new GLib.StringBuilder();
            foreach(int value in values)
            {
                compound_values.append(value.to_string());
                compound_values.append(",");
            }
            compound_values.erase(compound_values.len-1);
            m_conditions.append("%s IN (%s)".printf(field, compound_values.str));
            return true;
        }
        logger.print(LogMessage.ERROR, "addRangeConditionInt");
        m_noError = false;
        return m_noError;
    }

    public bool orderBy(string field, bool desc)
    {
        if(m_type == QueryType.SELECT)
        {
            m_orderBy = " ORDER BY ";
            m_orderBy += field;

            if(desc)
                m_orderBy += " DESC";
            else
                m_orderBy += " ASC";

            return true;
        }
        logger.print(LogMessage.ERROR, "orderBy");
        m_noError = false;
        return m_noError;
    }

    public bool limit(uint limit)
    {
        if(m_type == QueryType.SELECT && limit > 0)
        {
            m_limit = " LIMIT %u".printf(limit);
            return true;
        }
        logger.print(LogMessage.ERROR, "limit");
        m_noError = false;
        return m_noError;
    }

    public bool offset(uint offset)
    {
        if(m_type == QueryType.SELECT)
        {
            m_offset = " OFFSET %u".printf(offset);
            return true;
        }
        logger.print(LogMessage.ERROR, "offset");
        m_noError = false;
        return m_noError;
    }

    public string build()
    {
        if(!m_noError)
        {
            logger.print(LogMessage.ERROR, "build query");
            return "error setting up the query";
        }

        switch(m_type)
        {
            case QueryType.INSERT:
            case QueryType.INSERT_OR_IGNORE:
            case QueryType.INSERT_OR_REPLACE:
                m_query.append("INSERT ");

                if(m_type == QueryType.INSERT_OR_IGNORE)
                    m_query.append("OR IGNORE ");
                else if(m_type == QueryType.INSERT_OR_IGNORE)
                    m_query.append("OR REPLACE ");

                m_query.append("INTO ");
                m_query.append(m_table);
                m_query.append(" ");

                foreach(string field in m_fields)
                {
                    m_insert_fields.append(",");
                    m_insert_fields.append(field);
                }
                m_insert_fields.overwrite(0, "(").append(")");
                m_query.append(m_insert_fields.str);

                m_query.append(" VALUES ");

                foreach(string value in m_values)
                {
                    m_insert_values.append(",");
                    m_insert_values.append(value);
                }
                m_insert_values.overwrite(0, "(").append(")");
                m_query.append(m_insert_values.str);
                break;


            case QueryType.UPDATE:
                m_query.append("UPDATE ");
                m_query.append(m_table);
                m_query.append(" SET ");

                for(int i = 0; i < m_fields.length(); i++)
                {
                    m_query.append(m_fields.nth_data(i));
                    m_query.append(" = ");
                    m_query.append(m_values.nth_data(i));
                    m_query.append(", ");
                }

                m_query.erase(m_query.len-2);
                m_query.append(buildConditions());
                break;


            case QueryType.SELECT:
                m_query.append("SELECT ");
                foreach(string field in m_fields)
                {
                    m_query.append(field);
                    m_query.append(", ");
                }
                m_query.erase(m_query.len-2);
                m_query.append(" FROM ");
                m_query.append(m_table);
                m_query.append(buildConditions());
                m_query.append(m_orderBy);
                m_query.append(m_limit);
                m_query.append(m_offset);
                break;
        }

        print();
        return m_query.str;
    }

    private string buildConditions()
    {
        if(m_conditions.length() == 0)
            return "";

        var conditions = new GLib.StringBuilder();
        conditions.append(" WHERE ");

        foreach(string condition in m_conditions)
        {
            conditions.append(condition);
            conditions.append(" AND ");
        }
        conditions.erase(conditions.len-4);
        return conditions.str;
    }

    public string get()
    {
        return m_query.str;
    }

    public void reset()
    {
        m_query.str = "";
    }

    public void print()
    {
        logger.print(LogMessage.DEBUG, m_query.str);
    }
}
