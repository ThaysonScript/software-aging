#!/usr/bin/env bash

Modules() {
    local selectPackage=$1

    if [[ "$selectPackage" == "systemtap" ]]; then
        printf "\n%s\n" "---------- Testing systemtap hello world ----------"
        stap -v -e 'probe oneshot { println("hello world") }'

        printf "\n%s\n" "---------- List the probe points matching a certain pattern ----------"
        stap -L 'process("/bin/ls").function("*user*")'

        printf "\n%s\n" "---------- See when a given function gets called ----------"
        stap -e 'probe process("/bin/ls").function("format_user") { printf("format_user(uid=%d)\n", $u) }'

        printf "\n%s\n" "---------- You can instrument kernel functions, for example ----------"
        stap -ve 'probe kernel.function("icmp_reply") { println("icmp reply") }'

    elif [[ "$selectPackage" == "git" ]]; then
        printf "\n%s\n" "---------- TESTING PACKAGE INTALL GIT ----------"
        if ! which git; then
            echo "git not installed"
        fi

    fi
}

TestingPackags() {
    Modules "systemtap"
    Modules "git"
}

TestingPackags