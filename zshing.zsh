#!/bin/zsh

#---------------#
# SET VARIABLES #
#---------------#
ZDOTDIR="${ZDOTDIR:=$HOME}"
ZSHING_DIR=${ZSHING_DIR:=$HOME/.zshing}
ZSHING_LIST=( $ZSHING_DIR/* )
declare -A SITES=( [github]="https://github.com" [gitlab]="https://gitlab.com" )

#----------------------#
# LOAD STOCK FUNCTIONS #
#----------------------#
autoload -U compaudit compinit

#-------------------------#
# CHECK FOR ZSHING FOLDER #
#-------------------------#
[ -d "$ZSHING_DIR" ] || \mkdir -p "$ZSHING_DIR"

#--------------------#
# ZSHING HELP DIALOF #
#--------------------#
zshing_help(){
while read ; do
    printf "%s \n" "$REPLY"
done <<- HELP
ZSHING: Zsh plugin manager similar to VundleVim
USAGE: [CMDS]

CMDS:
    zshing_install  Install all plugins added to \$ZSHING_PLUGINS
    zshing_remove   Remove all plugins removed from \$ZSHING_PLUGINS
    zshing_update   Update all Plugins is ZShing folder
    zshing_help     Show this help dialog
HELP
}

#---------------#
# ERROR MESSAGE #
#---------------#
_zshing_error(){
	printf "%*s\r" "$COLUMNS"
	printf "[x] %s \n" "$@" >&2
}

#-----------------#
# SUCCESS MESSAGE #
#-----------------#
_zshing_success(){
	printf "%*s\r" "$COLUMNS"
	printf "[*] %s \n" "$@" >&2
}

#---------------------#
# GET PLUGIN SETTINGS #
#---------------------#
_zshing_info(){
local plugin

IFS=":"
read -rA plugin <<< "$1"

	_status=${plugin[1]}
	  _repo=${plugin[2]}
	_bransh=${plugin[3]:=master}

	if [[ "${plugin[4]}" == "git" || "${plugin[4]}" =~ (http|https) || "${plugin[4]}" == "ssh" || "${plugin[4]}" =~ git@* ]]; then
		_site="${plugin[4]}:${plugin[5]}"
		_type="${plugin[6]}"
		[ -n "$_repo" ] && _name="${plugin[7]:=${_repo:t}}" || _name="${plugin[7]:=${_site:t}}"
	else
		_site="${plugin[4]:=github}"
		_type="${plugin[5]}"
		_name="${plugin[6]:=${_repo:t}}"
	fi
}

#------------------#
# CLONE REPOSITORY #
#------------------#
_zshing_clone(){
local bransh="$1"
local site="${SITES[$2]:=$2}"
local repo="$4"
local _site_

[ "$repo" ] && _site_="$site/$repo" || _site_="$site"

[ -d "$ZSHING_DIR/$name" ] && {
	_zshing_success "'$name' Clones Successfuly"
	return 0
}

printf "%s %s \r" "[+]" "'$name' Cloning ..."
git clone -q --depth=1 --recursive -b "$bransh" "$_site_" "$ZSHING_DIR/$name"
[ "$?" -eq 0 ] &> /dev/null && _zshing_success "'$name' Cloned Successfuly" || _zshing_error "Can not clone '$name', please check you network"
}

#----------------#
# ZSHING INSTALL #
#----------------#
zshing_install(){

source "$ZDOTDIR/.zshrc"

[ -z "$ZSHING_PLUGINS" ] && { _zshing_error "No Plugins Found" ; return 0 ;}

local line
while read -r line ; do
	_zshing_info "$line"

	if [ "$_type" = "local" ] ; then
		_zshing_success "'$_name': Local Plugin"
	elif [[ "$_site" =~ (oh-my-zsh|ohmyzsh) ]]; then
		_zshing_clone "master" "github" "oh-my-zsh" "ohmyzsh/ohmyzsh"
	else
		_zshing_clone "$_bransh" "$_site" "$_name" "$_repo"
	fi
done <<< ${(F)ZSHING_PLUGINS[*]}

_zshing_source
}

#---------------#
# ZSHING REMOVE #
#---------------#
zshing_remove(){

source "$ZDOTDIR/.zshrc"

[ -z "$ZSHING_PLUGINS" ] && { _zshing_error "ZSHING: No Plugins Found" ; return 0 ;}

local line
while read -r line; do
	_zshing_info "$line"

	if [ "$_site" = "ohmyzsh" ]; then
		item="ohmyzsh"
	elif [ -z "$_repo" ]; then
		item=${_site:t}
	else
		item=${_repo:t}
	fi

	ZSHING_LIST[${ZSHING_LIST[(i)$ZSHING_DIR/$item]}]=()

done <<< ${(F)ZSHING_PLUGINS[*]}

for i (${ZSHING_LIST[@]}); { rm -rf "$i" ;}

_zshing_source
}

#-------------#
# GIT PULLING #
#-------------#
_zshing_pull(){
local _repo_=${1}
local _name_=${_repo_:t}

if [ -d "$_repo_/.git" ]; then
	printf "%s %s\r" "[^]" "Pulling/updating '$_name_' Repository"
	\git pull -q && git -q submoule update --init --recursive
	[ $? -eq 0 ] && _zshing_success "'$_name_' Pulling/Updating '$_name_' Successfuly" || _zshing_error "Can not clone '$_name_', Please chek your network"
else
	_zshing_error "'$_name_' Is not a Git repository"
fi
}

#---------------#
# ZSHING UPDATE #
#---------------#
zshing_update(){

source "$ZDOTDIR/.zshrc"

[ -z "$ZSHING_PLUGINS" ] && { _zshing_error "No Plugins Found" ; return 0 ;}

local line
while read -r line; do
	\cd -- "$line"
	_zshing_pull "$line"
	\cd -- "$OLDPWD"
done <<< ${(F)ZSHING_LIST[@]}

_zshing_source
}

#--------------------#
# SOURCE OMZ PLUGINS #
#--------------------#
_zshing_omz(){
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
    _zshing_error "Cannot Source Oh-my-zsh '$plug', Wrong type: $type"
fi
[ "$p" = "0" ] && _zshing_error "Cannot source '$plug' $type"
}

#-----------------------#
# SOURCE SIMPLE PLUGINS #
#-----------------------#
_zshing_plug(){
[ "$_local" ] && {
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
    _zshing_error "Cannot Source '$name', Wrong type: $type"
fi
[ "$p" = "0" ] && _zshing_error "Cannot source '$name' $type"
}

#----------------#
# SOURCE PLUGINS #
#----------------#
_zshing_source(){
local line
while read -r line ; do
	_zshing_info "$line"

	[ "$_status" ] || [ "$name" = "zshing" ] && continue

	if [ "$_site" = "oh-my-zsh" ]; then
		_zshing_omz "$_name" "$_type"
	elif [ "$_site" = "local" ]; then
		_local=true
		_zshing_plug "$_name" "$_type"
		unset _local
	else
		_zshing_plug "$_name" "$_type"
	fi
done <<< ${(F)ZSHING_PLUGINS[@]}
}

_zshing_source
