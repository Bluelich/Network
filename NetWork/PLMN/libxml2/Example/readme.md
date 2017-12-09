Getting the compilation options and libraries dependancies needed to generate binaries from the examples is best done on Linux/Unix by using the xml2-config script which should have been installed as part of make install step or when installing the libxml2 development package:


```
gcc -o example `xml2-config --cflags` example.c `xml2-config --libs`

```


