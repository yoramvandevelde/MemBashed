#!/bin/bash
#
# A very crude interface to MemCached from the commandline.
# 
# Made with a great deal of inspiration from the following sources:
#   - https://gist.github.com/ri0day/1538831 
#   - https://gist.github.com/goodevilgenius/11375877 
#   - cheatsheet http://lzone.de/cheat-sheet/memcached
# 
# The first one gave me a way to use break after the server has answered.
# The version from goodevilgenius helpen in making an abstraction MC.
# The third really is what I needed after reading the docs at
# https://github.com/memcached/memcached/blob/master/doc/protocol.txt

# Check if the environment variable's have been set
# if not use the following defaults
if [ -z $TTL  ]; then TTL=3600; fi
if [ -z $PORT ]; then PORT=11211; fi
if [ -z $HOST ]; then HOST="127.0.0.1"; fi

#
#  STORE functions
#
    
    function m_send {
        # MemBashed m_send: makes file descriptor with connection to 
        #                  Memcached and sends command through it
        # Arguments :: 
        #   1: Message to send to MemCached
        exec 3<>/dev/tcp/$HOST/$PORT 

        echo -en "$1\r\n">&3
       
        # The incr and decr functions don't return anything 
        if [[ "$1" =~ ^(incr|decr).* ]]; then return; fi

        # Read from file descriptor 3 until we see \r. We pass the
        # line before that into the loop. If it matches we have a 
        # MemCached status otherwise just print the line and move
        # on to the next.
        while read -u 3 -d $'\r' lastline
        do
            # break on MemCached status to get controlflow back
            if [ "$lastline" == "DELETED" -o \
                 "$lastline" == "END" -o \
                 "$lastline" == "OK" -o \
                 "$lastline" == "EXISTS" -o \
                 "$lastline" == "STORED" ]; then
                break;
            elif [ "$lastline" == "ERROR" -o \
                   "$lastline" == "NOT_STORED" -o \
                   "$lastline" == "NOT_FOUND" ]; then 
                echo $lastline 1>&2;
                break;
            elif [[ "$lastline" == VERSION* ]]; then 
                echo $lastline
                break; 
            fi
            echo $lastline
        done
    }

    function m_set {
        # MemBashed set; "set" means "store this data"
        # Arguments :: 
        #   1: Key
        #   2: 16 or 32 bit flags
        #   3: TTL
        #   4: Lenght in bytes
        #   5: Data
        KEY=$1
        DATA=$2 
        CHR=$(echo -n $DATA|wc -c)

        m_send "set ${KEY} 0 ${TTL} ${CHR}\r\n${DATA}"
    }

    function m_add {
        # MemBashed add;  "add" means "store this data, but only if the server *doesn't* already
        #                 hold data for this key".
        KEY=$1
        DATA=$2
        CHR=$(echo -n $DATA|wc -c) 
        
        m_send "add ${KEY} 0 ${TTL} ${CHR}\r\n${DATA}"
    }

    function m_replace {
        # MemBashed replace: "replace" means "store this data, but only if the server *does*
        #                    already hold data for this key".
        KEY=$1
        DATA=$2
        CHR=$(echo -n $DATA|wc -c) 
        
        m_send "replace ${KEY} 0 ${TTL} ${CHR}\r\n${DATA}"
    }

    function m_append {
        # MemBashed append: "append" means "add this data to an existing key after existing data".
        #
        KEY=$1
        DATA=$2
        CHR=$(echo -n $DATA|wc -c) 
        
        m_send "append ${KEY} 0 ${TTL} ${CHR}\r\n${DATA}"
    }
        
    function m_prepend {
        # MemBashed prepend: "prepend" means "add this data to an existing key before existing data".
        #
        KEY=$1
        DATA=$2
        CHR=$(echo -n $DATA| wc -c) 
        
        m_send "prepend ${KEY} 0 ${TTL} ${CHR}\r\n${DATA}"
    }

    function m_cas {
        # MemBashed cas: "cas" is a check and set operation which means "store this data but
        #                only if no one else has updated since I last fetched it."
        echo Not yet implemented.;
    }

#
#  RETRIEVE 
#
    function m_get {
        # MemBashed get; gets value from the store
        # Argument :: 
        #   1: Key
        m_send "get ${@}" | sed -n '1d;p;n'
        m_send "quit"
    }

    function m_gets { 
        # MemBashed get; gets value from the store
        # Argument :: 
        #   *: Key
        m_send "gets ${@}"
    }

#
#  UPDATE 
#
    function m_decr { 
        # MemBashed decr: "decr" is used to change data for some item
        #                 in-place, decrementing it.
        KEY=$1
        INT=$2
        m_send "decr ${KEY} ${INT}"
    }
    
    function m_incr { 
        # MemBashed incr: "incr" is used to change data for some item
        #                 in-place, increasing it.
        KEY=$1
        INT=$2
        m_send "incr ${KEY} ${INT} noreply"
        m_send "quit"
    }
    
    function m_touch { 
        # MemBashed touch: The "touch" command is used to update the expiration 
        #                  time of an existing item without fetching it.
        KEY=$1
        EXP=$2 
        m_send "touch ${KEY} ${EXP}"
    }

#
#  DELETION
#
    function m_delete { 
        # MemBashed delete; deletes am item from the store
        # Argument :: 
        #   *: Key
        KEY=$1
        m_send "delete ${KEY}"
    }
    
    function m_flush_all { 
        # MemBashed delete; deletes am item from the store
        m_send "flush_all"
    }

#
#  SERVER
#
    # MemBashed version: returns server version
    function m_version { 
        m_send "version";
    }

    
    # MemBashed stats; return stats from MemCached
    function m_stats { m_send "stats"; }
    function m_stats_items { m_send "stats items"; }
    function m_stats_slabs { m_send "stats slabs"; }
    function m_stats_malloc { m_send "stats malloc"; }

    function m_custom_cmd {
        # MemBashed mcustom_cmd: send raw message to Memcached
        # Arguments ::
        #   1: Raw message to send
        m_send "$@"
    }


