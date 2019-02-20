/**
 * libdecsync-vala - Utils.vala
 *
 * Copyright (C) 2018 Aldo Gunsing
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

public Gee.List<string> toList(string[] input)
{
	return new Gee.ArrayList<string>.wrap(input);
}

public Gee.Predicate<Json.Node> stringEquals(string input)
{
	return json => {
		       return json.get_string() == input;
	};
}

public Json.Node boolToNode(bool input)
{
	var node = new Json.Node(Json.NodeType.VALUE);
	node.set_boolean(input);
	return node;
}

public Json.Node stringToNode(string? input)
{
	Json.Node node;
	if (input == null)
	{
		node = new Json.Node(Json.NodeType.NULL);
	}
	else
	{
		node = new Json.Node(Json.NodeType.VALUE);
		node.set_string(input);
	}
	return node;
}

public Json.Node objectToNode(Json.Object input)
{
	var node = new Json.Node(Json.NodeType.OBJECT);
	node.set_object(input);
	return node;
}

public Gee.MultiMap<K, V> groupBy<T, K, V>(Gee.Collection<T> inputs, Gee.MapFunc<K, T> k, Gee.MapFunc<V, T>? f = null)
{
	var resultsMap = new Gee.HashMultiMap<K, V>();
	foreach (var input in inputs)
	{
		var key = k(input);
		var value = f == null ? input : f(input);
		resultsMap.@set(key, value);
	}

	return resultsMap;
}
