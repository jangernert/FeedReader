
/**
 * Representation model of a category from "/v3/categories"
 */
public class feedlyCategory : Model.Category,Gee.Comparable<feedlyCategory> {
   
    public feedlyCategory(string category_id, string label) {
        base (category_id, label);
    }

    /** Returns the number of unread articles */
    public override unowned int get_number_of_unread_articles () {
        return FeedlyAPI.get_api ().get_count_of_unread_articles (category_id);
    }

    /** Mark this category as read */
    public override void mark_as_read () {
        FeedlyAPI.get_api ().mark_as_read_category (this);
    }

    /** Returns all unread articles of this category */
    public override Gee.ArrayList<Entry> get_entries () {
        return FeedlyAPI.get_api ().get_entries_for_category (this);
    }

    /** Create a new Category from a given JSON object */
    public static feedlyCategory from_json_object (Json.Object object) {
        return new feedlyCategory (object.get_string_member ("id"), object.get_string_member ("label"));
    }

    /** Get the global.all (which contains all articles) category */
    public static feedlyCategory get_global_all_category () {
        return feedlyCategory.get_global_all_category_label (FeedlyAPI.get_api ().get_profile (), "All");
    }

    /** Get the global.all (which contains all articles) category */
    private static feedlyCategory get_global_all_category_label (Profile user_profile, string label) {
        return new feedlyCategory("user/" + user_profile.id + "/category/global.all", label);
    }

    public int compare_to (feedlyCategory other) {
        if (label == other.label) return 0;
        if (label < other.label) return -1;
        else return 1;
    }
}
