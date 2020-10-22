# Get PHP versions via Github.com API

Get the latest PHP version tags for each major branch via Github v3 API.

```
./get-php-ver.sh 
7.4.11
7.3.23
7.2.34
7.1.33
7.0.33
5.6.40
5.5.38
```

```
time ./build-fileinfo.sh 7.3.2

----------------------------------------------------------------------
Libraries have been installed in:
   /svr-setup/php-7.3.2/ext/fileinfo/modules

If you ever happen to want to link against installed libraries
in a given directory, LIBDIR, you must either use libtool, and
specify the full pathname of the library, or use the `-LLIBDIR'
flag during linking and do at least one of the following:
   - add LIBDIR to the `LD_LIBRARY_PATH' environment variable
     during execution
   - add LIBDIR to the `LD_RUN_PATH' environment variable
     during linking
   - use the `-Wl,--rpath -Wl,LIBDIR' linker flag
   - have your system administrator add LIBDIR to `/etc/ld.so.conf'

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
----------------------------------------------------------------------

Build complete.
Don't forget to run 'make test'.

success: make ok


-------------------------------------------------
fileinfo extension built
-------------------------------------------------

fileinfo.so belongs in /usr/local/lib/php/extensions/no-debug-non-zts-20180731

ls -lah /svr-setup/php-7.3.2/ext/fileinfo/modules
total 11M
drwxr-xr-x 2 root  root  4.0K Feb 27 23:52 .
drwxr-xr-x 9 nginx nginx 4.0K Feb 27 23:52 ..
-rw-r--r-- 1 root  root   807 Feb 27 23:52 fileinfo.la
-rwxr-xr-x 1 root  root  5.2M Feb 27 23:52 fileinfo.so
-rwxr-xr-x 1 root  root  5.7M Feb 27 23:52 fileinfo.so-b4strip


real    5m31.149s
user    4m51.059s
sys     3m43.460s
```