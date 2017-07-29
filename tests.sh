#!/bin/bash
#
# TESTS
#

source ./MemBashed.bash

    # connection + version
    echo -en "[+] Checking version of MemCached on ${HOST}:${PORT}... " 
    VERSION=$(m_version|cut -d' ' -f2)
    echo "done"
    echo -e "[+] Server has version ${VERSION}." 

    echo -en "[+] Let's raise an error... " 
    m_touch NOVAR 1

    # send raw commands
    echo "[+] Send raw command: TEST with TTL of 3 with DATA ABCD."
    m_custom_cmd "set TEST 0 3 4\r\nABCD" 

    # wait for TEST to expire
    echo "[+] Get TEST the following 4 seconds."
    for t in $(seq 0 3); 
    do
        echo -n "  RETRIEVED: "
        m_get TEST
        sleep 1
    done

    # Try to add to non existing key
    RES=$(m_set var6 abcd)
    printf "\n[+] Add var6 abcd : %s\n" $RES
    
    # Let's play with prepend and append 
    echo "[+] Set key EXPANDABLE with value 456."
    m_set EXPENDABLE 456
    echo "[+] Prepend 123 to EXPANDABLE." 
    m_prepend EXPENDABLE 123
    echo "[+] Append 7890 to EXPANDABLE." 
    m_append EXPENDABLE 7890
    # and show the result
    m_get EXPENDABLE
   
    m_set COUNTER 0

    # and lets count
    for i in $(seq 1 5);
    do
        m_incr COUNTER $i;
        m_get COUNTER
    done

    for i in $(seq 1 6);
    do
        m_decr COUNTER $i;
        m_get COUNTER
    done
    
    m_delete COUNTER
    m_decr COUNTER 1
