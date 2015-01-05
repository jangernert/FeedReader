/**
 * Representation model of the "/v3/profile"
 */
public abstract class Model.Profile {
    public string id {get; private set; }
    public string name {get; private set; }
    public string locale {get; private set; }
    public string wave {get; private set; }
	public string picture {get; private set; }

    public Profile(string id, string givenName,
                   string locale, string wave, string picture) {
        this.id = id;
        this.name = givenName;
        this.locale = locale;
        this.wave = wave;
        this.picture=picture;
    }
}