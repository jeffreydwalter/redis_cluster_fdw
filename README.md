Redis Cluster FDW for PostgreSQL 14
==============================

This PostgreSQL extension implements a Foreign Data Wrapper (FDW) for
the Redis key/value database: http://redis.io/

This code was originally experimental, and largely intended as a pet project
for Dave to experiment with and learn about FDWs in PostgreSQL. It has now been
extended for production use by Andrew and subsequently forked by Jeffrey Walter
to add support for clustered Redis.

By all means use it, but do so entirely at your own risk! You have been
warned!

Building
--------
To build the code, you will need the hiredis_cluster C interface to Redis installed
on your system. You can checkout the hiredis_clsuter from
https://github.com/Nordix/hiredis-cluster

You will also need the hiredis C interface to Redis installed
on your system. You can checkout the hiredis from
https://github.com/redis/hiredis
or it might be available for your OS as it is for Fedora, for example.

Once that's done, the extension can be built with:

    PATH=/usr/lib/postgresql/13/bin/:$PATH make USE_PGXS=1
    sudo PATH=/usr/lib/postgresql/13/bin/:$PATH make USE_PGXS=1 install

(assuming you have PostgreSQL 13 in /usr/lib/postgresql/13/bin).

Dave has tested the original on Mac OS X 10.6 only, and Andrew on Fedora and
Suse. Other *nix's should also work.
Neither of us have tested on Windows, but the code should be good on MinGW.

Limitations
-----------

- There's no such thing as a cursor in Redis in the SQL sense,
  nor MVCC, which leaves us
  with no way to atomically query the database for the available keys
  and then fetch each value. So, we get a list of keys to begin with,
  and then fetch whatever records still exist as we build the tuples.

- We can only push down a single qual to Redis, which must use the
  TEXTEQ operator, and must be on the 'key' column.

- Redis cursors have some significant limitations. The Redis docs say:

    A given element may be returned multiple times. It is up to the
    application to handle the case of duplicated elements, for example only
    using the returned elements in order to perform operations that are safe
    when re-applied multiple times.

  The FDW makes no attempt to detect this situation. Users should be aware of
  the possibility.

Usage
-----

The following parameters can be set on a Redis foreign server:

nodes:	A comma separated list addresses or hostnames of the Redis cluster servers.
	 	Default: 127.0.0.1:6379

The following parameters can be set on a Redis foreign table:

tabletype: can be 'hash', 'list', 'set' or 'zset'
	    Default: none, meaning only look at scalar values.

tablekeyprefix: only get items whose names start with the prefix
        Default: none

tablekeyset: fetch item names from the named set
        Default: none

singleton_key: get all the values in the table from a single
named object.
	    Default: none, meaning don't just use a single object.

You can only have one of tablekeyset and tablekeyprefix, and if you use
singleton_key you can't have either.

Structured items are returned as array text, or, if the value column is a
text array as an array of values. In the case of hash objects this array is
an array of key, value, key, value ...

Singleton key tables are returned as rows with a single column of text
in the case of lists sets and scalars, rows with key and value text columns
for hashes, and rows with a value text columns and an optional numeric score
column for zsets.

The following parameter can be set on a user mapping for a Redis
foreign server:

password:	The password to authenticate to the Redis server with.
     Default: <none>

Insert, Update and Delete
-------------------------

PostgreSQL acquired support for modifying foreign tables in release 9.3,
the Redis Cluster Foreign Data Wrapper supports these too, for 9.3 and later
PostgreSQL releases. There are a few restriction on this:

- only INSERT works for singleton key list tables, due to limitations
  in the Redis API for lists.
- INSERT and UPDATE only work for singleton key ZSET tables if they have the
  priority column
- non-singleton non-scalar tables must have an array type for the second column

Example
-------

	CREATE EXTENSION redis_cluster_fdw;

	CREATE SERVER redis_cluster
		FOREIGN DATA WRAPPER redis_cluster_fdw
		OPTIONS (addresses '127.0.0.1:6379,127.0.0.2:6379,127.0.0.3:6379');

	CREATE FOREIGN TABLE redis_db0 (key text, val text)
		SERVER redis_cluster;

	CREATE USER MAPPING FOR PUBLIC
		SERVER redis_cluster
		OPTIONS (password 'secret');

	CREATE FOREIGN TABLE myredishash (key text, val text[])
		SERVER redis_cluster
		OPTIONS (tabletype 'hash', tablekeyprefix 'mytable:');

    INSERT INTO myredishash (key, val)
       VALUES ('mytable:r1','{prop1,val1,prop2,val2}');

    UPDATE myredishash
        SET val = '{prop3,val3,prop4,val4}'
        WHERE key = 'mytable:r1';

    DELETE from myredishash
        WHERE key = 'mytable:r1';

	CREATE FOREIGN TABLE myredis_s_hash (key text, val text)
		SERVER redis_cluster
		OPTIONS (tabletype 'hash',  singleton_key 'mytable');

    INSERT INTO myredis_s_hash (key, val)
       VALUES ('prop1','val1'),('prop2','val2');

    UPDATE myredis_s_hash
        SET val = 'val23'
        WHERE key = 'prop1';

    DELETE from myredis_s_hash
        WHERE key = 'prop2';

Testing
-------

The tests assume that you have access to a redis cluster server
on the localmachine with no password,
and that the redis-cli program is in the PATH when it is run.
The test script checks that the database is empty before it tries to
populate it, and it cleans up afterwards.


Authors
-------

Dave Page
dpage@pgadmin.org

Andrew Dunstan
andrew@dunslane.net
	
Jeffrey Walter
jeffreydwalter@gmail.com
