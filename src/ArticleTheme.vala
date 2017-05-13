using Gee;

public class  FeedReader.ArticleTheme {
    static Array<HashMap> ? themes = null;

    static Array<HashMap> getThemes(){
        if(!ArticleTheme.themes){
            // Local themes
            string theme_dir = GLib.Environment.get_home_dir() + "/.feedreader/themes/";
            ArticleTheme.themes += grabThemes(theme_dir);
            // Global themes
            string global_dir = Constants.INSTALL_PREFIX + "/share/ArticleView/";
            ArticleTheme.themes += grabThemes(theme_dir);
        }
        return ArticleTheme.themes;
    }

    private HashMap<string, string> getThemeInfo (string theme_path) {
      """
        Parse a theme directory, and check if it's a valid theme
      """
      var themeInfo = new HashMap<string, string> ();
      bool corrupted_theme = true;
      string theme_name = "";
      string author = "";
      try {
        Dir theme_dir = Dir.open(theme_path, 0);
        string ? name = null;
        while ((name = theme_dir.read_name()) != null){
          if (name == "theme.json"){
              corrupted_theme = false;
              string path = Path.build_filename(theme_path, name);
              Json.Parser parser = new Json.Parser();
              try {
                parser.load_from_file(path);
                Json.Object obj = parser.get_root().get_object();

                Value val;
                foreach (unowned string nname in obj.get_members()){
                  val = obj.get_member(nname).get_value();
                  switch(nname) {
                    case "author":
                      author = (string) val;
                    break;
                    case "name":
                      theme_name = (string) val;
                    break;
                  }
                }
              }catch(Error err){
                corrupted_theme = true;
              }
          }
        }
      }catch(GLib.FileError err){

      }
      if (!corrupted_theme){
        themeInfo.set("name", theme_name);
        themeInfo.set("author", author);
        themeInfo.set("path", theme_path);
      } else {
        themeInfo.set("corrupted", "true");
      }
      return themeInfo;
    }

    private Array<HashMap> grabThemes(string location) {
      """
        Return a list of themes on a specific location (global/local)
      """
      Array<HashMap> themes = new Array<HashMap> ();
      try{
          Dir dir = Dir.open(location, 0);
          string ? name = null;
          while ((name = dir.read_name()) != null){
            string path = Path.build_filename(location, name);
            if(FileUtils.test(path, FileTest.IS_DIR)){
              var themeInfo = getThemeInfo(path);
              if (!"corrupted" in themeInfo.keys){
                themes.append_val(themeInfo);
              }
            }
          }
      } catch (GLib.FileError err){

      }
      return themes;
    }
}
