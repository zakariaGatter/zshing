#!/bin/env zsh

# notes
# 1 : add # to disable this plugin, the plugin keep update ting and will not remove but wont load with zsh
# 2 : repo name u can set local or from a site ; in local u can set a dir or a file
# 3 : use any branch you like
# 4 : support many git sites
# 5 : what the type of this i a plugin , theme , completion, rc
# 6 : add name option to add the same plugin or theme many time with different names if u want to make any changes or fwark it
# 					  "stat:repo:branch:site:type:name
# 					  "1: 2                    : 3    : 4                              : 5                       : 6  "
# example on a plugin "#:zakariagatter/markedit:branch:(github|gitlab|https://**|local):(plugin|theme|completion):name"

# special example for oh-my-zsh "#::branch:oh-my-zsh:(plugin|theme|lib):name"

#------------------#
# SCRIPT VARIABLES #
#------------------#{{{
ZSHING_DIR=${ZSHING_DIR:-$HOME/.zshing}
ZSHING_LIST=( $ZSHING_DIR/* )
declare -A _SITES_=( ["github"]="https://github.com" ["gitlab"]="https://gitlab.com" )
#}}}

#------------------------------#
# MAKE ZSHING DIR IF NOT EXIST #
#------------------------------#{{{
[ -d "$ZSHING_DIR" ] || mkdir -p "$ZSHING_DIR"
#}}}

#----------------------#
# LOAD STOCK FUNCTIONS #
#----------------------#{{{
autoload -U compaudit compinit
#}}}

#---------------------------------#
# GIT CLONE USE IN ZSHING INSTALL #
#---------------------------------#{{{
_git_clone_(){
local _repo_=${1}
local _branch_=${2}
local _site_=${3}
local _name_=${4:-${_repo_:t}}
local __site_=$_site_

[ "$_FULL_" ] && {
   local _clone_="$_site_"
} || {
    _site_=${_SITES_[$_site_]}
    [ "$_site_" ] || { echo -e "[X] $_name_: $__site_ None Valide Site "; return ;}
    local _clone_="$_site_/$_repo_"
}

echo -en "[?] $_name_: Is Cloning ... \r"

if (git clone -q --depth=1 --recursive -b "$_branch_" "$_clone_" "${ZSHING_DIR}/${_name_}"); then
	echo -e "[+] $_name_: Install Successfully "
else
	echo -e "[X] $_name_: Can't see what is the Problem, please check your connection"
fi
}
#}}}

#--------------------------------#
# GIT PULL USE IN ZSHING UPDATE  #
#--------------------------------#{{{
_git_pull_(){
local _name_=${1}

echo -en "[?] $_name_: Updating ...\r"

if (git status &> /dev/null); then
    if (git pull  && git submoule update --init --recursive) &> /dev/null; then
		echo -e "[^] $_name_: Updated Successfully"
	else
		echo -e "[X] $_name_: Can't see what is the Problem, please check your connection"
	fi
else
	echo -e "[X] $_name_: Is not a Git repo Please set it to local"
fi
}
#}}}

#--------------------------#
# ZSHING INSTALL FUNCTION  #
#--------------------------#{{{
zshing_install(){
local i P

# Plugin list empty
[ "${ZSHING_PLUGINS[*]}" ] || { echo -e "[X] Zshing: No Plugins Giving"; return ;}

# start install plugins
for i (${ZSHING_PLUGINS[@]}); do
	while IFS=":" read -A P ; do
		local _repo_=${P[2]}
		local _branch_=${P[3]:-master} # if branch empty take master

        if [[ ${P[4]} == git || ${P[4]} == https || ${P[4]} == http || ${P[4]} == ssh || ${P[4]} =~ git@* ]] ; then
            _FULL_=true
            local _site_="${P[4]}:${P[5]}"
            local _name_="${P[7]:-${_site_:t}}"
        else
            unset _FULL_
            local _site_=${P[4]:-github}
            local _name_=${P[6]:-${_repo_:t}}
        fi

		# if local, do nothing
		if [ "$_site_" = "local" ]; then
			echo -e "[+] $_name_: Local Plugin"
		elif [ "$_site_" = "oh-my-zsh" ]; then
			[ -d "$ZSHING_DIR/oh-my-zsh" ] && {
				# SHow MSG only one time
				[ "$_OMZ_INS_" ] || {
					echo -e "[+] Oh-My-Zsh: Install Successfully"
					_OMZ_INS_="true"
				}
			} || {
				_site_="github"
				_repo_="robbyrussell/oh-my-zsh"
				_git_clone_ "$_repo_" "$_branch_" "$_site_"
			}
		else
			[ -d "$ZSHING_DIR/$_name_" ] && {
                echo -e "[+] $_name_: Install Successfully"
            } || {
                _git_clone_ "$_repo_" "$_branch_" "$_site_" "$_name_"
            }
		fi
	done < <(echo $i)
done

_source_all_
}
#}}}

#------------------------#
# ZSHING UPDATE FUNCTION #
#------------------------#{{{
zshing_update(){
for i (${ZSHING_LIST[@]}); do
	local _name_=${i:t}

	cd -- "$i"

	_git_pull_ "$_name_"

	cd -- "$OLDPWD"
done

_source_all_
}
#}}}

#------------------------#
# ZSHING REMOVE FUNCTION #
#------------------------#{{{
zshing_remove(){
local i j p

for i (${ZSHING_PLUGINS[@]}); do
	while IFS=":" read -A p; do
		local _repo_=${p[2]}
		local _site_=${p[4]}
		local _name_=${p[6]:-${_repo_:t}}

		# if u use oh-my-zsh
		[ "$_site_" = "oh-my-zsh" ] && _name_="oh-my-zsh"

		# loop to all plugins dir
		for j in {1..${#ZSHING_LIST}} ; do
			# if the plugin exist in ZSHING_PLUGINS remove it from ZSHING_LIST
			[ "${ZSHING_LIST[$j]:t}" = "$_name_" ] && ZSHING_LIST[$j]=""
		done

	done< <(echo $i)
done

# all plugins left in ZSHING_LIST are those are not in ZSHING_PLUGINS so lets remove them
for i ( $ZSHING_LIST ); do
	rm -rf "$i" 2> /dev/null && echo -e "[-] ${i:t}: Removed Successfully"
done

_source_all_

}
#}}}

#-------------#
# ZSHING HELP #
#-------------#{{{
zshing_help(){
cat <<- HELP
ZSHING Zsh Plugin to manage Plugin similar to VundleVim

CMDS:
    zshing_install  [Install Plugin direct from Local or Online git Repos]
    zshing_update   [Update existing Plugins in your system]
    zshing_clean    [Clean and Remove unwanted Plugins]
    zshing_help     [Show this help Dialog]
HELP
}
#}}}

#-------------------#
# OH MY ZSH PLUGINS #
#-------------------#{{{
# add functions dirs
_oh_my_zsh_plugin(){
local base_dir=${1}
local name=${2}

if [ -f "$base_dir/plugins/$name/$name.plugin.zsh" ] ; then
	source "$base_dir/plugins/$name/$name.plugin.zsh"
elif [ -f "$base_dir/plugins/$name/_$name" ]; then
	fpath=$($base_dir/plugins/$name $fpath)
else
	echo "[oh-my-zsh] $name: plugin not found"
fi
}

# main oh-my-zsh source
_oh_my_zsh_(){
local _name=${1}
local _type=${2}
local _OMZ_DIR_="$ZSHING_DIR/oh-my-zsh"

[ "$_name" ] || { echo -e "[X] Oh-my-zsh: No Name Giving"; return ;}

# Oh-my-zsh plugin
if [ "$_type" = "plugin" ]; then
	_oh_my_zsh_plugin "$_OMZ_DIR_" "$_name"
# OH-my-zsh Theme
elif [ "$_type" = "theme" ]; then #  THEME
	test -f $_OMZ_DIR_/themes/$_name.zsh-theme && source "$_OMZ_DIR_/themes/$_name.zsh-theme" || echo -e "[X] Oh-my-zsh: $_name No Theme Found"
# Oh-my-zsh Libs
elif [ "$_type" = "lib" ]; then
	test -f "$_OMZ_DIR_/lib/$_name.zsh" && source "$_OMZ_DIR_/lib/$_name.zsh" || echo -e "[X] Oh-my-zsh: $_name No Lib Found"
# Oh-my-zsh else
else
	echo -e "[X] Oh-my-zsh: $_type Wrong type please see help for more information"
fi
}
#}}}

#----------------#
# SIMPLE PLUGINS #
#----------------#{{{
_simple_plugins_(){
local i
local _type=${1}
local _name=${2}
local _s_=0

# simple plugin
if [ "$_type" = "plugin" ]; then
	for i ($ZSHING_DIR/$_name/$_name.{zsh,plugin.zsh,zsh.plugin,zshplugin,zp.zsh} $ZSHING_DIR/$_name/init.zsh) ; do
		test -f "$i" && { source "$i"; ((_s_++)) ;}
	done
# simple theme
elif [ "$_type" = "theme" ]; then
	for i ($ZSHING_DIR/$_name/$_name.{zsh-theme,zsh,zt.zsh} $ZSHING_DIR/$_name/init.zsh) ; do
		test -f "$i" && { source "$i"; ((_s_++)) ;}
	done
# simple completion
elif [ "$_type" = "completion" ]; then
	test -f "$ZSHING_DIR/$_name/_$_name" && { fpath=($ZSHING_DIR/$_name $fpath); ((_s_++)); }
# check for plugin existing
elif [ ! -d "$ZSHING_DIR/$_name" ];then
    echo -e "[X] $_name: $_type None install "
    break
# simple else
else
	echo -e "[X] $_name: $_type Wrong type please see help for more information"
	break
fi

[ "$_s_" -eq 0 ] &&  echo -e "[X] $_name: Can't Source this $_type "
}
#}}}

#--------------#
# LOCAL PLUGIN #
#--------------#{{{
_local_plugin_(){
local _dir_=${1}
local _type=${2}
local _name=${3:-${_dir_:t}}
local l=0

if [ -d "$_dir_" ] ;then
    # simple plugin
    if [ "$_type" = "plugin" ]; then
        for i ($_dir_/$_name.{zsh,plugin.zsh,zsh.plugin,zshplugin,zp.zsh} $_dir_/init.zsh) ; do
            test -f "$i" && { source "$i"; ((l++)) ;}
        done
    # simple theme
    elif [ "$_type" = "theme" ]; then
        for i ($_dir_/$_name.{zsh-theme,zsh,zt.zsh} $_dir_/init.zsh) ; do
            test -f "$i" && { source "$i"; ((l++)) ;}
        done
    # simple completion
    elif [ "$_type" = "completion" ]; then
        test -f "/$_dir_/_$_name" && { fpath=($_dir_ $fpath); ((l++)) ;}
    # simple else
    else
        echo -e "[X] $_name: $_type Wrong type please see help for more information"
        break
    fi
    [ "$l" = "0" ] && echo -e "[X] $_dir_: Can't Source this $_type "
else
	echo -e "[X] $_dir_: No Such Directory"
fi
}
#}}}

#-------------------#
# SOURCING PLUGINS  #
#-------------------#{{{
_source_all_() {
local i p func

for i (${ZSHING_PLUGINS[@]}); do
	while IFS=":" read -A p; do
		local _stat_=${p[1]}
		local _repo_=${p[2]}
		local _site_=${p[4]}
		local _type_=${p[5]}
		local _name_=${p[6]}

        if [[ ${p[4]} == git || ${p[4]} == https || ${p[4]} == http || ${p[4]} == ssh || ${p[4]} =~ git@* ]] ; then
            local _site_="${p[4]}:${p[5]}"
		    local _type_="${p[6]}"
            local _name_="${p[7]:-${_site_##*/}}"
        else
            local _site_="${p[4]}"
		    local _type_="${p[5]}"
            local _name_="${p[6]:-${_repo_##*/}}"
        fi

		# don't load the comment one
		# and don't source zshing plugin to prevent a stupid loop
		[ "$_stat_" = "#" ] || [ "${_repo_:t}" = "zshing" ] && continue

		# oh-my-zsh plugins
		[ "$_site_" = "oh-my-zsh" ] && {
            _oh_my_zsh_ "$_name_" "$_type_"
            continue
        }

        # if local plugin
        [ "$_site_" = "local" ] && {
            _local_plugin_ "$_repo_" "$_type_" "$_name_"
            continue
        }

		# simple plugins
		_simple_plugins_ "$_type_" "$_name_"

	done < <(echo $i)
done


# AUTO REMOVE DUPLICATES FROM THESE ARRAYS
typeset -U fpath

# AUTO LOAD ALL ZSH FUNCTIONS
for func in $^fpath/*(N-.x:t); autoload $func

}
#}}}

#----------------------------#
# SOURCE ALL INSTALL PLUGINS #
#----------------------------#
_source_all_

# vim: ft=sh
