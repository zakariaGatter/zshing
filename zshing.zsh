#!/bin/zsh

# notes
# 1 : add # to disable this plugin, the plugin keep update ting and will not remove but wont load with zsh
# 2 : repo name u can set local or from a site ; in local u can set a dir or a file
# 3 : use any branch you like
# 4 : support many git sites
# 5 : what the type of this i a plugin , theme , completion, rc
# 6 : add name option to add the same plugin or theme many time with different names if u want to make any changes or fwark it
# 					  "stat:repo:branch:site:type:name
# 					  "1: 2                    : 3    : 4                              : 5                       : 6  "
# example on a plugin "#:zakariagatter/markedit:branch:(github|gitlab|https://**|local):(plugin|theme|completion|rc):name"

# special example for oh-my-zsh "#::branch:oh-my-zsh:(plugin|theme|lib):name"

#------------------#
# SCRIPT VARIABLES #
#------------------#{{{
ZSHING_DIR=${ZSHING_DIR:-$HOME/.zshing}
ZSHING_LIST=( $ZSHING_DIR/* )
declare -A _SITES_=( ["github"]="https://github.com" ["gitlab"]="https://gitlab.com" ["bitbucket"]="https://bitbucket.org" )
#}}}

#------------------------------#
# MAKE ZSHING DIR IF NOT EXIST #
#------------------------------#{{{
test -d "$ZSHING_DIR" || \mkdir -p "$ZSHING_DIR"
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
local _name_=${6:-${_repo_:t}}
local _o_site_=$_site_

# if the site is a https link
[[ "$_site_" =~ ^https://* ]] && _site_=${_site_} || _site_=${_SITES_[$_site_]}

# if you put a wrong site name
test -z "$_site_" && { echo -e "[X] $_name_ : $_o_site_ None Valide Site "; return ;}

echo -en "[?] $_name_ : Is Cloning ... \r"

if (\git clone --depth=1 --recursive -b "$_branch_" "${_site_}/${_repo_}" "${ZSHING_DIR}/${_name_}" &> /dev/null ); then
	echo -e "[+] $_name_ : Cloned Successfully "
else
	echo -e "[X] $_name_ : Can't see what is the Problem, please check your connection"
fi
}
#}}}

#--------------------------------#
# GIT PULL USE IN ZSHING UPDATE  #
#--------------------------------#{{{
_git_pull_(){
local _name_=${1}

echo -en "[?] $_name_ : Updating ..."

if (\git status &> /dev/null); then
	if (\git pull &> /dev/null); then
		echo -e "[^] $_name_ : Updated Successfully"
	else
		echo -e "[X] $_name_ : Can't see what is the Problem, please check your connection"
	fi
else
	echo -e "[X] $_name_ : Is not a Git repo Please set it to local"
fi
}
#}}}

#--------------------------#
# ZSHING INSTALL FUNCTION  #
#--------------------------#{{{
zshing_install(){
local i P

# Plugin list empty
test -z "${ZSHING_PLUGINS[*]}" && { echo -e "[X] Zshing : No Plugins Giving"; return ;}

# start install plugins
for i (${ZSHING_PLUGINS[@]}); do
	while IFS=":" read -A P ; do
		local _repo_=${P[2]}
		local _branch_=${P[3]:-master} # if branch empty take master
		local _site_=${P[4]:-github}
		local _name_=${P[6]}

		# if name empty take plugin name
		_name_=${_name_:-${_repo_:t}}

		# if local, do nothing
		if [ "$_site_" = "local" ]; then
			echo -e "[+] $_name_ : Local Plugin"
		elif [ "$_site_" = "oh-my-zsh" ]; then
			test -d "$ZSHING_DIR/oh-my-zsh" && {
				# SHow MSG only one time
				test -z "$_OMZ_INS_" && {
					echo -e "[+] Oh-My-Zsh : Install Successfully"
					_OMZ_INS_="true"
				}
			} || {
				_site_="github"
				_repo_="robbyrussell/oh-my-zsh"
				_git_clone_ "$_repo_" "$_branch_" "$_site_"
			}
		else
			test -d "$ZSHING_DIR/$_name_" && echo -e "[+] $_name_ : Install Successfully" || _git_clone_ "$_repo_" "$_branch_" "$_site_" "$_name_"
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
for i (${ZSHING_DIR_LIST[@]}); do
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
		local _name_=${p[6]}

		# if name empty use repo name
		[ -z "$_name_" ] && _name_=${_repo_:t}

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
	\rm -rf "$i"
	echo -e "[-] ${i:t} : Removed Successfully"
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

CMDS :
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
	echo "[oh-my-zsh] $name : plugin not found"
fi
}

# main oh-my-zsh source
_oh_my_zsh_(){
local _name=${1}
local _type=${2}
local _OMZ_DIR_="$ZSHING_DIR/oh-my-zsh"

test -z "$_name" && { echo -e "[X] Oh-my-zsh : No Name Giving"; return ;}

# Oh-my-zsh plugin
if [ "$_type" = "plugin" ]; then
	_oh_my_zsh_plugin "$_OMZ_DIR_" "$_name"
# OH-my-zsh Theme
elif [ "$_type" = "theme" ]; then #  THEME
	test -f $_OMZ_DIR_/themes/$_name.zsh-theme && source "$_OMZ_DIR_/themes/$_name.zsh-theme" || echo -e "[X] Oh-my-zsh : $_name No Theme Found"
# Oh-my-zsh Libs
elif [ "$_type" = "lib" ]; then
	test -f "$_OMZ_DIR_/lib/$_name.zsh" && source "$_OMZ_DIR_/lib/$_name.zsh" || echo -e "[X] Oh-my-zsh : $_name No Lib Found"
# Oh-my-zsh else
else
	echo -e "[X] Oh-my-zsh : $_type Wrong type please see help for more information"
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
# simple Rc
elif [ "$_type" = "rc" ]; then
	for i ($ZSHING_DIR/$_name/{.zshrc,zshrc,.zshrc.local,init.zsh,rc.zsh}) ; do
		test -f "$i" && { source "$i"; ((_s_++)) ;}
	done
# simple else
else
	echo -e "[X] $_name : $_type Wrong type please see help for more information"
	break
fi

[ "$_s_" -eq 0 ] &&  echo -e "[X] $_name : Can't Source this $_type "
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

		# dont load the comment one
		# and dont source zshing plugin to prevent a stupid loop
		[ "$_stat_" = "#" -o "${_repo_:t}" = "zshing" ] && continue

		# oh-my-zsh plugins
		[ "$_site_" = "oh-my-zsh" ] && {
			_oh_my_zsh_ "$_name_" "$_type_"
			continue
		}

		# if the name empty use the repo name
		_name_=${_name_:-${_repo_:t}}

		# simple plugins
		_simple_plugins_ "$_type_" "$_name_"

	done < <(echo $i)
done


# AUTO REMOVE DUPLICATES FROM THESE ARRAYS
typeset -U fpath

# AUTOLOAD ALL ZSH FUNCTIONS
for func in $^fpath/*(N-.x:t); autoload $func

}
#}}}

#----------------------------#
# SOURCE ALL INSTALL PLUGINS #
#----------------------------#
_source_all_

# vim: ft=sh
