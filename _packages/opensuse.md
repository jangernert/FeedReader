---
distro: openSUSE
data-content: opensuse
---
<h3><small>Available for 42.1, 42.2 and Tumbleweed in <a href='http://download.opensuse.org/repositories/home:/scujas/'>Jason Scurtu's repository</a>.</small></h3>
Add the repository to your sources (replace $VERSION with actual version of openSUSE)
<pre>sudo zypper ar -r http://download.opensuse.org/repositories/home:/scujas/$VERSION/home:scujas.repo</pre>
Refresh package sources
<pre>sudo zypper refresh</pre>
And install the package
<pre>sudo zypper install feedreader</pre>
<h3>1-Click-Install</h3>
<ul> 
    <li><a href="http://software.opensuse.org/ymp/home:scujas:feedreader/openSUSE_Tumbleweed/feedreader.ymp">openSUSE Tumbleweed</a></li>
    <li><a href="http://software.opensuse.org/ymp/home:scujas:feedreader/openSUSE_Leap_42.1/feedreader.ymp">openSUSE Leap 42.1</a></li>
    <li><a href="http://software.opensuse.org/ymp/home:scujas:feedreader/openSUSE_Leap_42.2/feedreader.ymp">openSUSE Leap 42.2</a></li>
</ul>