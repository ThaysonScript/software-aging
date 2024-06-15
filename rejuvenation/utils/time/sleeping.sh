#!/usr/bin/env bash

SLEEPING() {
    local dormir=$1
    local tipo_dormir=$2

    case "$tipo_dormir" in
        "s")
            echo "dormindo por $dormir segundo(s)"
            ;;
        "m")
            echo "dormindo por $dormir minuto(s)"
            ;;
        "h")
            echo "dormindo por $dormir hora(s)"
            ;;
        "d")
            echo "dormindo por $dormir dia(s)"
            ;;
        *)
            echo -e "forneça unidade de tempo válida!\n"
            echo -e "s - segundo\nm - minuto\nh - hora\nd - dia\n"
            exit 1
            ;;
    esac

    sleep "$dormir""$tipo_dormir"
}