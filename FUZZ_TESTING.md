# Fuzz testing

## libvilistextum

Install american fuzzy lop, however you do that on your OS.

Rebuild using `afl-gcc`:

```
rm -rf builddir
CC=afl-gcc meson builddir
ninja -C builddir
```

Now run `afl-fuzz`:

```
afl-fuzz -m 512 -x libraries/libVilistextum/dictionaries/xml.dict -i libraries/libVilistextum/inputs -o output -- ./builddir/libraries/libVilistextum/vilistextum_main
```

This should take the inputs in `libraries/libVilistextum/inputs`, and start making random tests (using a little
help from the XML dictionary). If you get any crashes or hangs, there will be
output in `output/crashes` or `output/hangs`.

For crashes, Valgrind can give you a backtrace:

```
valgrind --track-origins=yes ./builddir/libraries/libVilistextum/vilistextum_main < output/crashes/[failed-test]
```

For hangs, run `gdb` and then cancel it:

```
gdb ./builddir/libraries/libVilistextum/vilistextum_main
(gdb) run < < output/crashes/[failed-test]
# type ctrl+c, then bt, or use other tools like print and up/down
```
