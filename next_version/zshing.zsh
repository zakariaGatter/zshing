#!/bin/env zsh

# example on a plugin "#:zakariagatter/markedit:branch:(github|gitlab|https://**|local):(plugin|theme|completion):name"
#--------------#
# SCRIPT NAME  #
#--------------#
name="zshing"
version="0.3"

#------------------#
# SCRIPT VARIABLES #
#------------------#
ZSHING_DIR="${ZSHING_DIR:-$HOME/.zshing}"
ZSHING_LIST=( $ZSHING_DIR/* )
declare -A ZSHING_SITES=( [github]="https://github.com" [gitlab]="https://gitlab.com" )

#----------------------#
# LOAD STOCK FUNCTIONS #
#----------------------#
autoload -U compaudit compinit colors
compinit
colors
setopt ignore_close_braces

#---------------------------------#
# CHECK FOR ZSHING MAIN DIRECTORY #
#---------------------------------#
[ -d "$ZSHING_DIR" ] && mkdir -p "$ZSHING_DIR"

#------------#
# FAILED MSG #
#------------#
_failed_(){ printf "%*s\r" "$COLUMNS" && printf "  %s\n" "$fg[red]✘$reset_color $@" >&2 }

#-------------#
# SUCCESS MSG #
#-------------#
_success_(){ printf "%*s\r" "$COLUMNS" && printf "  %s\n" "$fg[green]✔ $reset_color $@" >&2 }

#--------------------#
# ZSHING HELP DIALOG #
#--------------------#
zshing_help(){
cat <<- HELP
$name($version) Zsh Plugin manager Similair to VundleVim

COMMANDS:
    zshing_install  Install Giving plugins
    zshing_remove   Remove unwanted Plugins
    zshing_update   Pull/Update All Plugins
    zshing_help     Display this help dialog and exit

NOTE:
    * For more information please visit <https://github.com/zakariagatter/zshing>
HELP
}
#-----------------------#
#  GET PLUGINS SETTINGS #
#-----------------------#
_get_(){
local _plug_
while IFS=":" read -rA _plug_ ; do
      _stat_="${_plug_[1]}"
      _repo_="${_plug_[2]}"
    _bransh_="${_plug_[3]:-master}"

    [[ ${_plug_[4]}  =~ ((git|ssh|http(s)?)|(git@[\w\.]+)) ]] && {
        _site_="${_plug_[4]}:${_plug_[5]}"
        _type_="${_plug_[6]}"
        _name_="${_plug_[7]:-${_site_:t}}"
        _full_=true
    }||{
        _site_="${_plug_[4]}:-github"
        _type_="${_plug_[5]}"
        _name_="${_plug_[6]:-${_repo_:t}}"
    }
done <<< "$1"
}

#-------------------#
# GIT CLONE PLUGINS #
#-------------------#
_clone_(){
local     _repo_=${1}
local   _branch_=${2}
local     _site_=${ZSHING_SITES[$3]:-$3}
local     _name_=${4}
local     _type_=${5}
local _progress_=( "-" "\\" "|" "/" )

[ -d "$ZSHING_DIR/$_name_" ] && { _success_ "'$_name' Cloned Seccussfuly" && return }

[ "$_full_" ] && local _clone_="$_site_" || local _clone_="$_site_/$_repo_"

until (git clone -q --depth=1 --recursive -b "$_branch_" "$_clone_" "$ZSHING_DIR/$_name_"); do
    (S=s++%4)
    printf "[%s] %s\r" "$fg[yellow]${_progress_[$S]}$reset_color" "Cloning '$_name_' $_type_"
done

[ $? -eq 0 ] && _success_ "'$_name_' Cloned Seccussfuly" || _failed_ "Cannot clone '$_name', Please check your network"
}

#----------------#
# PULL REOSITORY #
#----------------#
_pull_(){
local     _repo_=${1}
local     _name_=${_repo_:t}
local _progress_=( "-" "\\" "|" "/" )

[ -d "$_repo_/.git" ] && {
    until (git pull -q && git -q submoule update --init --recursive) ; do
        (S=s++%4)
        printf "[%s] %s\r" "$fg[yellow]${_progress_[$S]}$reset_color" "Pulling/Updating '$_name_' Reposiroty"
    done
} || {
    _failed_ "'$_name_' Is not a Git Reposiroty "
}
}

#----------------#
# ZSHING INSTALL #
#----------------#
zshing_install(){
local _line_
while read -r _line_; do

    _get_ "$_line_"

    if [ "$_site_" = "local" ]; then
        _success_ "'$_name_' $_type_ Install locally "
    elif [ "$_site_" = "oh-my-zsh" ]; then
        _clone_ "ohmyzsh/ohmyzsh" "$_branch_" "github" "oh-my-zsh" "Framework"
    else
        _clone_ "$_repo_" "$_branch_" "$_site_" "$_type_" "$_name_"
    fi
done <<< ${(F)ZSHING_PLUGINS[*]}
}

#---------------#
# ZSHING REMOVE #
#---------------#
zshing_remove(){
local _line_
while read -r _line_ ; do

    _get_ "$_line_"

    if [ "$_site_" = "oh-my-zsh" ];then
        local _item_="oh-my-zsh"
    elif [ "$_full_" ]; then
        local _item_=${_name_:-${_site_:t}}
    else
        local _item_=${_name_:-${_repo_:t}}
    fi

    : ${ZSHING_LIST[(i)$ZSHING_DIR/$_item_]}
done <<< ${(F)ZSHING_PLUGINS[*]}

for i ( ${ZSHING_LIST[@]} ); { rm -rf "$i" && _success_ "'${i:t}' Removed Successfully" }
}

#----------------------#
# ZSHING PULL / UPDATE #
#----------------------#
zshing_update(){
local _dir_
for _dir_ ( $ZSHING_LIST[@] ); {
    builtin cd -- "$_dir_"
    _pull_ "$_dir_"
    builtin cd -- "$OLDPWD"
}
}

#------------------#
# OH-MY-ZSH SOURCE #
#------------------#
_source_omz_(){
local _omz_="$ZSHING_DIR/oh-my-zsh"
local plug="$1"
local type="$2"

}

#----------------------#
# SIMPLE PLUGIN SOURCE #
#----------------------#
_source_plug_(){
local plug="$1"
local type="$2"

}

#--------------------#
# SOURCE ALL PLUGINS #
#--------------------#
_source_(){
local _plug_
while read -r _plug_ ; do

    _get_ "$_plug_"

    if [ "$_site_" = "oh-my-zsh" ]; then
        _source_omz_ "$_name_" "$_type_"
    elif [ "$_site_" = "local" ]; then
        [ -d "$ZSHING_DIR/$_name_" ] && _source_plug_ "$_name_" "$_type_" || _failed_ "'$_name_' No File or Directory"
    else
        _source_plug_ "$_name_" "$_type_"
    fi
done <<< ${(F)ZSHING_PLUGINS[@]}
}

# vim: ft=zsh
