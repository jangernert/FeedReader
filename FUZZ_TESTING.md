# Fuzz testing

## htmlclean

Install american fuzzy lop, however you do that on your OS.

### Gumbo

Most of the work is done by Gumbo, so you may want to compile it from source
with `afl-gcc`:

```
sudo dnf remove gumbo-parser-devel # or however you remove the packaged library
git clone https://github.com/google/gumbo-parser.git
cd gumbo-parser
./autogen.sh
CC=afl-gcc ./configure --prefix /usr
make -j8
sudo make install
```

### FeedReader

Rebuild FeedReader using `afl-gcc`:

```
rm -rf builddir
CC=afl-gcc meson builddir
ninja -C builddir
```

Now run `afl-fuzz`:

```
afl-fuzz -m 512 -x libraries/htmlclean/dictionaries/xml.dict -i libraries/htmlclean/inputs -o output -- ./builddir/libraries/htmlclean/htmlclean_main
```

This should take the inputs in `libraries/htmlclean/inputs`, and start making random tests (using a little
help from the XML dictionary). If you get any crashes or hangs, there will be
output in `output/crashes` or `output/hangs`.

For crashes, Valgrind can give you a backtrace:

```
valgrind --track-origins=yes ./builddir/libraries/htmlclean/htmlclean_main < output/crashes/[failed-test]
```

For hangs, run `gdb` and then cancel it:

```
gdb ./builddir/libraries/htmlclean/htmlclean_main
(gdb) run < < output/crashes/[failed-test]
# type ctrl+c, then bt, or use other tools like print and up/down
```

### Cleanup

You probably want to switch back to a normal version of Gumbo:

```
cd path/to/gumbo-parser
sudo make uninstall
sudo dnf install gumbo-parser-devel # or whatever
```
