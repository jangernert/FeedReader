// TT-RSS doesn't guarantee any particular types in their API, so we need to
// dynamically cast everything to the type we expect
namespace FeedReader.UntypedJson
{

namespace Object
{

public Value? get_value_member(Json.Object obj, string key)
{
	var member = obj.get_member(key);
	if(member == null)
		return null;

	return member.get_value();
}

public int? get_int_member(Json.Object obj, string key)
{
	var value = get_value_member(obj, key);
	if (value == null)
		return null;

	var result = new Value(Type.INT);
	value.transform(ref result);
	return result.get_int();
}

public string? get_string_member(Json.Object obj, string key)
{
	var value = get_value_member(obj, key);
	if (value == null)
		return null;

	var result = new Value(Type.STRING);
	value.transform(ref result);
	return result.get_string();
}

}
}
