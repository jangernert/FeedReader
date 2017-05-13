using Gee;

public class  FeedReader.ArticleTheme {
    public static ArrayList<HashMap<string, string>> ? themes = null;

    public static ArrayList<HashMap> getThemes(){
        if(ArticleTheme.themes == null){
            // Local themes
            string local_dir = GLib.Environment.get_user_data_dir() + "/feedreader/themes/";
            ArticleTheme.grabThemes(local_dir);
            // Global themes
            string global_dir = Constants.INSTALL_PREFIX + "/share/FeedReader/ArticleView/";
            ArticleTheme.grabThemes(global_dir);
        }
        return ArticleTheme.themes;
    }

    public static HashMap<string, string> getThemeInfo (string theme_path) {
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

    public static void grabThemes(string location) {
      try{
          Dir dir = Dir.open(location, 0);
          string ? name = null;
          while ((name = dir.read_name()) != null){
            string path = Path.build_filename(location, name);
            if(FileUtils.test(path, FileTest.IS_DIR)){
              var themeInfo = ArticleTheme.getThemeInfo(path);
              if (("corrupted" in themeInfo.keys) == false){
                ArticleTheme.themes.add(themeInfo);
              }
            }
          }
      } catch (GLib.FileError err){

      }
    }

    public static bool isExists(string theme_location){
      // Check wether a theme exists or not
      bool exists = true;
      try {
        Dir.open(theme_location, 0);
      } catch(GLib.FileError err) {
        exists = false;
      }
      return exists;
    }
}
