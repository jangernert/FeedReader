
/**
 * Representation model of the "/v3/profile"
 */
public class Profile : Model.Profile {

    public Profile(string id, string fullName,
                   string locale, string wave, string picture) {
        base(id, fullName, locale, wave, picture);
    }
    /** Create a new profile from an existing JSON object */
    public static Profile from_json_object (Json.Object object) {
        return new Profile (object.get_string_member ("id"), object.get_string_member ("fullName"), object.get_string_member ("locale"),
                object.get_string_member ("wave"),object.get_string_member ("picture"));
    }
}