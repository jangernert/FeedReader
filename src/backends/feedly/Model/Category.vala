/**
 * Representation model of a category from "/v3/categories"
 */
public abstract class Model.Category : Object {
    /** ID of this category */
    public string category_id {get; set; }
    /** label of this category */
    public string label {get; set; }
    public int unread_count {get; set; default = -1; }

    public Category(string category_id, string label) {
        this.category_id = category_id;
        this.label = label;
    }

    public abstract Gee.ArrayList<Entry> get_entries ();
 
    public abstract unowned int get_number_of_unread_articles ();

    public abstract void mark_as_read ();

}