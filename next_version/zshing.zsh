#!/bin/env zsh

# example on a plugin "#:zakariagatter/markedit:branch:(github|gitlab|https://**|local):(plugin|theme|completion):name"
#--------------#
# SCRIPT NAME  #
#--------------#

#------------------#
# SCRIPT VARIABLES #
#------------------#
: ${ZDOTDIR:-$HOME}
ZSHING_DIR="${ZSHING_DIR:-$HOME/.zshing}"
ZSHING_LIST=( $ZSHING_DIR/* )
declare -A SITES=( [github]="https://github.com" [gitlab]="https://gitlab.com" )

#----------------------#
# LOAD STOCK FUNCTIONS #
#----------------------#
autoload -U compaudit compinit colors
compinit
colors

#---------------------------------#
# CHECK FOR ZSHING MAIN DIRECTORY #
#---------------------------------#
[ -d "$ZSHING_DIR" ] && mkdir -p "$ZSHING_DIR"

#------------#
# FAILED MSG #
#------------#
_failed_(){ printf "%*s\r" "$COLUMNS" && printf "[%s] %s\n" "$fg[red]✘$reset_color" "$@" >&2 ;}

#-------------#
# SUCCESS MSG #
#-------------#
_success_(){ printf "%*s\r" "$COLUMNS" && printf "[%s] %s\n" "$fg[green]✔ $reset_color" "$@" >&2 ;}

#--------------------#
# ZSHING HELP DIALOG #
#--------------------#
zshing_help(){
local name="zshing"
local version="0.3"
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

    [[ ${_plug_[4]}  =~ ((ssh|http(s)?)|(git@[\w\.]+)) ]] && {
        _site_="${_plug_[4]}:${_plug_[5]}"
        _type_="${_plug_[6]}"
        _name_="${_plug_[7]:-${_site_:t}}"
        _full_=true
    }||{
        _site_="${_plug_[4]}:-github"
        _type_="${_plug_[5]}"
        _name_="${_plug_[6]:-${_repo_:t}}"
        unset _full_
    }
done <<< "$1"
}

#-------------------#
# GIT CLONE PLUGINS #
#-------------------#
_clone_(){
local _repo_=${1}
local _branch_=${2}
local _site_=${SITES[$3]:-$3}
local _name_=${4}

[ -d "$ZSHING_DIR/$_name_" ] && { _success_ "'$_name' Cloned Seccussfuly" && return ;}

[ "$_full_" ] && local _clone_="$_site_" || local _clone_="$_site_/$_repo_"

printf "[%s] %s\r" "$fg[yellow]*$reset_color" "Cloning '$_name_' $_type_"
git clone -q --depth=1 --recursive -b "$_branch_" "$_clone_" "$ZSHING_DIR/$_name_"
[ $? -eq 0 ] && _success_ "'$_name_' Cloned Seccussfuly" || _failed_ "Cannot clone '$_name', Please check your network"
}

#----------------#
# PULL REOSITORY #
#----------------#
_pull_(){
local _repo_=${1}
local _name_=${_repo_:t}

[ -d "$_repo_/.git" ] && {
    printf "[%s] %s\r" "$fg[yellow]*$reset_color" "Pulling/Updating '$_name_' Reposiroty"
    git pull -q && git -q submoule update --init --recursive
    [ $? -eq 0 ] && _success_ "'$_name_' Cloned Seccussfuly" || _failed_ "Cannot clone '$_name', Please check your network"
} || {
    _failed_ "'$_name_' Is not a Git Reposiroty "
}
}

#----------------#
# ZSHING INSTALL #
#----------------#
zshing_install(){
source "$ZDOTDIR/.zshrc"

local _line_
while read -r _line_; do

    _get_ "$_line_"

    if [ "$_site_" = "local" ]; then
        _success_ "'$_name_' Installed locally "
    elif [ "$_site_" = "oh-my-zsh" ]; then
        _clone_ "ohmyzsh/ohmyzsh" "$_branch_" "github" "oh-my-zsh"
    else
        _clone_ "$_repo_" "$_branch_" "$_site_" "$_name_"
    fi
done <<< ${(F)ZSHING_PLUGINS[*]}

_source_
}

#---------------#
# ZSHING REMOVE #
#---------------#
zshing_remove(){
source "$ZDOTDIR/.zshrc"

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

    ZSHING_LIST[${ZSHING_LIST[(i)$ZSHING_DIR/$_item_]}]=()
done <<< ${(F)ZSHING_PLUGINS[*]}

for i ( ${ZSHING_LIST[@]} ); { echo $i ;}
#    { rm -rf "$i" && _success_ "'${i:t}' Removed Successfully" ;}

_source_
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

_source_
}

#------------------#
# OH-MY-ZSH SOURCE #
#------------------#
_source_omz_(){
local plug="$1"
local type="$2"
local _omz_="$ZSHING_DIR/oh-my-zsh"
local p=0

if [ "$type" = "plugin" ];then
    if [ -f "$_omz_/plugins/$plug/$plug.plugin.zsh" ];then
        source "$_omz_/plugins/$plug/$plug.plugin.zsh"
        ((p++))
    elif [ -f "$_omz_/plugins/$plug/_$plug" ];then
        fpath=($_omz_/plugins/$plug $fpath)
        ((p++))
    fi
elif [ "$type" = "theme" ];then
    [ -f "$_omz_/themes/$plug.zsh-theme" ] && { source "$_omz_/themes/$plug.zsh-theme" && ((p++)) }
elif [ "$type" = "lib" ];then
    [ -f "$_omz_/lib/$plug.zsh" ] && { source "$_omz_/lib/$plug.zsh" && ((p++)) }
else
    _failed_ "Cannot Source Oh-my-zsh '$plug', Wrong type: $type"
fi
[ "$p" = "0" ] && _failed_ "Cannot source '$plug' $type"

}

#----------------------#
# SIMPLE PLUGIN SOURCE #
#----------------------#
_source_plug_(){
[ "$_local_" ] && {
    local dir=${1}
    local name=${dir:t}
    local type=${2}
    [ -d "$dir" ] && {_failed_ "'$name' No File or Directory" && return ;}
} || {
    local name=${1}
    local dir="${ZSHING_DIR}/$name"
    local type=${2}
}
local p=0

if [ "$type" = "plugin" ]; then
    for i ( $dir/{$name.{zsh,plugin.zsh,zt.zsh,zsh.plugin,zshplugin},init.zsh} ); {
        [ -f "$i" ] && { source "$i" && ((p++)) ;}
    }
elif [ "$type" = "theme" ]; then
    for i ($dir/{$name.{zsh-theme,zsh},init.zsh} ) ; do
        [ -f "$i" ] && { source "$i" && ((p++)) }
    done
elif [ "$type" = "completion" ]; then
    [ -f "$dir/_$name" ] && { fpath=($dir $fpath) && ((p++)) }
else
    _failed_ "Cannot Source '$name', Wrong type: $type"
fi
[ "$p" = "0" ] && _failed_ "Cannot source '$name' $type"
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
        _local_=true
        _source_plug_ "$_repo_" "$_type_"
        unset _local_
    else
        _source_plug_ "$_name_" "$_type_"
    fi
done <<< ${(F)ZSHING_PLUGINS[@]}
}

_source_

# vim: ft=zsh
