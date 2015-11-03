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

public class FeedReader.GrabberConfig : GLib.Object {

    private Gee.ArrayList<string> m_xpath_title;
    private Gee.ArrayList<string> m_xpath_author;
    private Gee.ArrayList<string> m_xpath_date;
    private Gee.ArrayList<string> m_xpath_body;
    private Gee.ArrayList<string> m_xpath_strip;
    private Gee.ArrayList<string> m_xpath_stripIDorClass;
    private Gee.ArrayList<string> m_xpath_stripImgSrc;
    private bool m_tidy;
    private bool m_prune;
    private bool m_autodetectOnFailure;
    private string m_singlePageLink;
    private string m_nextPageLink;
    private Gee.ArrayList<StringPair> m_replace;
    private string m_testURL;

    public GrabberConfig(string filename)
    {
        // init defaults:
        m_tidy = true;
        m_prune = true;
        m_autodetectOnFailure = true;

        var file = File.new_for_path(filename);

        if(!file.query_exists())
        {
            stderr.printf ("File '%s' doesn't exist.\n", file.get_path());
            return;
        }

        try
        {
            var dis = new DataInputStream(file.read ());
            string line;

            while((line = dis.read_line()) != null)
            {
                line = line.chug();
                if(!line.has_prefix("#") && line != "")
                {
                    if(line.has_prefix("title:"))
                    {
                        splitValues(ref m_xpath_title, extractValue("title:", line));
                    }
                    else if(line.has_prefix("body:"))
                    {
                        splitValues(ref m_xpath_body, extractValue("body:", line));
                    }
                    else if(line.has_prefix("date:"))
                    {
                        splitValues(ref m_xpath_date, extractValue("date:", line));
                    }
                    else if(line.has_prefix("author:"))
                    {
                        splitValues(ref m_xpath_author, extractValue("author:", line));
                    }
                    else if(line.has_prefix("strip:"))
                    {
                        m_xpath_strip.add(extractValue("strip:", line));
                    }
                    else if(line.has_prefix("strip_id_or_class:"))
                    {
                        m_xpath_stripIDorClass.add(extractValue("strip_id_or_class:", line));
                    }
                    else if(line.has_prefix("strip_image_src:"))
                    {
                        m_xpath_stripImgSrc.add(extractValue("strip_image_src:", line));
                    }
                    else if(line.has_prefix("tidy:"))
                    {
                        if(extractValue("tidy:", line) == "no")
                            m_tidy = false;
                    }
                    else if(line.has_prefix("prune:"))
                    {
                        if(extractValue("prune:", line) == "no")
                            m_prune = false;
                    }
                    else if(line.has_prefix("autodetect_on_failure:"))
                    {
                        if(extractValue("autodetect_on_failure:", line) == "no")
                            m_autodetectOnFailure = false;
                    }
                    else if(line.has_prefix("single_page_link:"))
                    {
                        m_singlePageLink = extractValue("single_page_link:", line);
                    }
                    else if(line.has_prefix("next_page_link:"))
                    {
                        m_nextPageLink = extractValue("next_page_link:", line);
                    }
                    else if(line.has_prefix("find_string:"))
                    {
                        string toReplace = extractValue("find_string:", line);
                        line = dis.read_line();
                        string replaceWith = extractValue("replace_string:", line);
                        m_replace.add(new StringPair(toReplace, replaceWith));
                    }
                    else if(line.has_prefix("replace_string("))
                    {
                        string tmp = extractValue("replace_string(", line);
                        var values = tmp.split("): ");
                        m_replace.add(new StringPair(values[0], values[1]));
                    }
                    else if(line.has_prefix("test_url:"))
                    {
                        m_testURL = extractValue("test_url:", line);
                    }
                }
            }
        }
        catch(Error e)
        {
            error("%s", e.message);
        }
    }

    private string extractValue(string identifier, string line)
    {
        string res = line.splice(0, identifier.length);

        int index = res.index_of("#");
        if(index != -1)
        {
            res = res.splice(index, res.length);
        }

        return res.chug().chomp();
    }

    private void splitValues(ref Gee.ArrayList<string> list, string line)
    {
        var array = line.split(" | ");
        foreach(string tmp in array)
        {
            list.add(tmp);
        }
    }

    public void print()
    {
        if(m_xpath_title.size != 0)
        {
            stdout.printf("title:\n");
            foreach(string title in m_xpath_title)
            {
                stdout.printf("     %s\n", title);
            }
        }

        if(m_xpath_author.size != 0)
        {
            stdout.printf("author:\n");
            foreach(string author in m_xpath_author)
            {
                stdout.printf("     %s\n", author);
            }
        }

        if(m_xpath_date.size != 0)
        {
            stdout.printf("date:\n");
            foreach(string date in m_xpath_date)
            {
                stdout.printf("     %s\n", date);
            }
        }

        if(m_xpath_body.size != 0)
        {
            stdout.printf("body:\n");
            foreach(string body in m_xpath_body)
            {
                stdout.printf("     %s\n", body);
            }
        }

        if(m_xpath_strip.size != 0)
        {
            stdout.printf("strip:\n");
            foreach(string strip in m_xpath_strip)
            {
                stdout.printf("     %s\n", strip);
            }
        }

        if(m_xpath_stripIDorClass.size != 0)
        {
            stdout.printf("stripIDorClass:\n");
            foreach(string stripIDorClass in m_xpath_stripIDorClass)
            {
                stdout.printf("     %s\n", stripIDorClass);
            }
        }

        if(m_xpath_stripImgSrc.size != 0)
        {
            stdout.printf("stripImgSrc:\n");
            foreach(string stripImgSrc in m_xpath_stripImgSrc)
            {
                stdout.printf("     %s\n", stripImgSrc);
            }
        }

        stdout.printf("tidy: ");
        if(m_tidy)
            stdout.printf("yes\n");
        else
            stdout.printf("no\n");

        stdout.printf("prune: ");
        if(m_prune)
            stdout.printf("yes\n");
        else
            stdout.printf("no\n");

        stdout.printf("autodetectOnFailure: ");
        if(m_autodetectOnFailure)
            stdout.printf("yes\n");
        else
            stdout.printf("no\n");

        if(m_singlePageLink != null)
            stdout.printf("singlePageLink: %s\n", m_singlePageLink);

        if(m_nextPageLink != null)
            stdout.printf("nextPageLink: %s\n", m_nextPageLink);

        if(m_replace.size != 0)
        {
            stdout.printf("replace:\n");
            foreach(StringPair tmp in m_replace)
            {
                stdout.printf("replace %s with %s\n", tmp.getString1(), tmp.getString2());
            }
        }

        if(m_testURL != null)
            stdout.printf("testURL: %s\n", m_testURL);
    }


    public string getXPathNextPageURL()
    {
        return m_nextPageLink;
    }

    public string getXPathSinglePageURL()
    {
        return m_singlePageLink;
    }

    public unowned Gee.ArrayList<string> getXPathTitle()
    {
        return m_xpath_title;
    }

    public unowned Gee.ArrayList<string> getXPathAuthor()
    {
        return m_xpath_author;
    }

    public unowned Gee.ArrayList<string> getXPathDate()
    {
        return m_xpath_date;
    }

    public unowned Gee.ArrayList<string> getXPathStrip()
    {
        return m_xpath_strip;
    }

    public unowned Gee.ArrayList<string> getXPathStripIDorClass()
    {
        return m_xpath_stripIDorClass;
    }

    public unowned Gee.ArrayList<string> getXPathStripImgSrc()
    {
        return m_xpath_stripImgSrc;
    }

    public unowned Gee.ArrayList<string> getXPathBody()
    {
        return m_xpath_body;
    }

    public unowned Gee.ArrayList<StringPair> getReplace()
    {
        return m_replace;
    }
}
