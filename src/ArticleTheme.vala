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
using Gee;

public struct ThemeInfo {
    string name;
    string author;
    string path;
}

public class  FeedReader.ArticleTheme {
    private static HashMap<string, ThemeInfo?> ? themes = null;


    public static HashMap<string, ThemeInfo?> getThemes(){
        if(themes == null){
            // Local themes
            themes = new HashMap<string, ThemeInfo?> ();
            string local_dir = GLib.Environment.get_user_data_dir() + "/feedreader/themes/";
            grabThemes(local_dir);
            // Global themes
            string global_dir = Constants.INSTALL_PREFIX + "/share/FeedReader/ArticleView/";
            grabThemes(global_dir);
        }
        return themes;
    }

    private static ThemeInfo? getTheme (string theme_path) {
      var themeInfo = ThemeInfo ();
      bool corrupted_theme = false;
      try {
        string path = Path.build_filename(theme_path, "theme.json");
        Json.Parser parser = new Json.Parser();
        parser.load_from_file(path);
        Json.Object obj = parser.get_root().get_object();

        Value val;
        foreach (unowned string node_name in obj.get_members()){
          val = obj.get_member(node_name).get_value();
          switch(node_name) {
            case "author":
              themeInfo.author = (string) val;
            break;
            case "name":
              themeInfo.name = (string) val;
            break;
          }
        }
        themeInfo.path = theme_path;

      } catch(GLib.FileError err){
        Logger.error("A theme must be corrupted :" + theme_path);
        corrupted_theme = true;
      }

      if (corrupted_theme)
        return null;

      return themeInfo;
    }

    public static void grabThemes(string location) {
      try{
          Dir dir = Dir.open(location, 0);
          string ? name = null;
          while ((name = dir.read_name()) != null){
            string path = Path.build_filename(location, name);
            if(FileUtils.test(path, FileTest.IS_DIR)){
              var themeInfo = getTheme(path);
              if(themeInfo != null)
                themes.set(name, themeInfo);
            }
          }
      } catch (GLib.FileError err){
        Logger.debug("Couldn't reach the location of themes : " + location);
      }
    }

    public static bool exists(string theme_location){
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
