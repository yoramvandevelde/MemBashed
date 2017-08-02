# MemBashed

* A bash interface to the MemCached memory keystore.

Could be nice for IPC or really fast cross process storing of values.

```
$ source MemBashed.bash 
$ m_stats | egrep "uptime|pid"
STAT pid 4487
STAT uptime 51027
$ m_set MEMCACHED_FOR_ALL yes
$ m_get MEMCACHED_FOR_ALL
yes
```

Or you could just source it in a script, then you do not have to make the file descriptor.
