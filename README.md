

_Legacy OS X Dashboard widget to access Java documentation_

JavaDoc is a Mac OS X Dashboard widget to quickly access the local Java API.

JavaDoc is Snow Leopard ready!

Local Java API documentation must be installed. You can do this from the XTools installer options, on the Mac OS X DVD, or from http://connect.apple.com/.

![JavaDoc](javadoc_widget.png "JavaDoc")

**History**

    0.1
    first alpha release
    
    0.2
    design change, security fix
    
    0.3
    use a compiled plugin instead of a script
    searches the whole API
    
    0.4
    searches in every standard package
    you can add your own search paths
    the search is now case insensitive
    
    0.5
    can search Java 1.5 documentation
    
    0.6
    you can choose your favorite browser
    sleeker design
    persistent focus
    file paths can have spaces
    
    0.7
    fixed bug with Java 1.5
    fixed bug that prevented custom API search if official documentation was not installed
    allow tilde use in the custom paths
    universal binary compilation
    
    0.8
    leopard update
    
    0.9
    searches latest java doc path
    remove java doc files quarantine

**Todo**

    - enable autocompletion
    - add a popup menu to choose the package
    - How can I add my own search paths ?

Open the file `~/Library/Preferences/ch.seriot.widget.JavaDoc.plist` and add your paths as below :

    <dict>
       <key>searchPaths</key>
       <array>
          <string>...</string>
          <string>/Users/nst/my_doc_path/</string>
       </array>
    </dict>

How can I use JavaDoc with my favorite browser ?

Open the file `~/Library/Preferences/ch.seriot.widget.JavaDoc.plist` and type your browser identifier as below :
    
    <dict>
       <key>browser</key>
       <string>org.mozilla.firefox</string>
    </dict>
