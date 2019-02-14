#!/bin/zsh

#---------------#
# ZASHING FILES #
#---------------#
ZSHING_DIR="$HOME/.zshing"
ZSHING_LIST="$(dirname $0)/.list"

#---------------#
# Enable option #
#---------------#
setopt nonomatch # enable return null if command not working

#-------------#
# Help Dialog #
#-------------#
zshing_help () {
echo "
    ZSHING ( 0.2 )
    Write by Zakaria Gatter (zakaria.gatter@gmail.com)

    Zsh Plugin to manage Plugin similar to VundleVim

    OPTS : 
        zshing_install  [Install Plugin direct from Local or Online git Repos]
        zshing_update   [Update existing Plugins in your system]
        zshing_clean    [Clean and Remove unwanted Plugins]
        zshing_search   [Search for Plugins Themes and Completions]
        zshing_help     [Show this help Dialog]
"
return 0
}

#------------------#
# Install Function #
#------------------#
_GIT_INSTALL_ () {
echo -en "[?] -: $1 :- Is Installing ... \r"

if git clone https://github.com/$1 &> /dev/null;then 
    echo -e "[+] -: $1 :- Install Successfully "
else
    echo -e "[X] -: $1 :- There is Unknown Error it maybe connection or reponame "
fi
}

#-----------------#
# Update Function #
#-----------------#
_GIT_UPDATE_ () {
echo -en "[?] -: $1 :- Is Updating ... \r"

if git pull &> /dev/null;then
    echo -e "[^] -: $1 :- Update Successfully "
else
    echo -e "[X] -: $1 :- There is Unknown Error it maybe connection or reponame "
fi
}

#-----------------#
# Remove Function #
#-----------------#
_GIT_REMOVED_ () {
echo -en "[?] -: $1 :- Is Removing ... \r"

# Remove the repo with out show output
rm -rf "$ZSHING_DIR/$1" &> /dev/null

# show msg if the command is success or not 
[ "$?" = 0 ] && {
    echo -e "[-] -: $1 :- Removed Successfully "
} || {
    echo -e "[X] -: $1 :- There is Unknown Error "
}
}

#------------------------#
# ZShing Install Command #
#------------------------#
zshing_install () {

_CD_I_="$PWD"

for ZI in ${ZSHING_PLUGINS[@]} ; do 
if [ ! -d "$ZI" ];then
    ZI_NAME=$(basename "$ZI")
    [ -d "$ZSHING_DIR/$ZI_NAME" ] || {
	cd "$ZSHING_DIR"
        _GIT_INSTALL_ "$ZI"
    }
fi
done 

cd "$_CD_I_"

source ~/.zshrc

unset ZI ZI_NAME _CD_I_
}

#-----------------------#
# Zshing Update Command #
#-----------------------#
zshing_update () {

# get current directory 
CD="$PWD"

for ZU in ${ZSHING_PLUGINS[@]} ; do 
if [ ! -d "$ZU" ];then
    ZU_NAME=$(basename "$ZU")
    cd "$ZSHING_DIR/$ZU_NAME"
    _GIT_UPDATE_ "$ZU"
fi
done 

cd $CD

source ~/.zshrc

unset ZU CD ZU_NAME
}

#----------------------#
# Zshing Clean Command #
#----------------------#
zshing_clean () {
LIST_PLUGINS=$(ls $ZSHING_DIR/)

for ZC in ${ZSHING_PLUGINS[@]}; do 
    ZC_NAME=$(basename "$ZC")
    LIST_PLUGINS=$(echo "$LIST_PLUGINS" | sed "s:$ZC_NAME::")
done 

for DZC in $(echo $LIST_PLUGINS) ; do 
    _GIT_REMOVED_ "$DZC"
done 

source ~/.zshrc

unset DZC LIST_PLUGINS ZC_NAME 
}

#-----------------------#
# Zshing search Command #
#-----------------------#
zshing_search () {
[ "$CURL_ZSHING" != "true" ] && {
    echo -en "[?] : Download Plugins List From Network \r"
    curl -o $ZSHING_LIST https://raw.githubusercontent.com/zakariaGatter/zshing/master/.list &> /dev/null
    CURL_ZSHING="true"
    echo -e "[@] : Plugins List Downloaded Successfully"
}
grep -i --color=auto "$1" $ZSHING_LIST
}

#--------------------#
# SOURCE GIT PLUGINS #
#--------------------#
_SOURCE_GIT_ZSHING_(){ #{{{
if [ "$1" != "zshing" ];then 
    [ -d "$ZSHING_DIR/$1" ] && {
	if [ -f $ZSHING_DIR/$1/*.zsh ];then 
	    source $ZSHING_DIR/$1/*.zsh
	elif [ -f $ZSHING_DIR/$1/*.sh ];then 
	    source $ZSHING_DIR/$1/*.sh
	else
	    echo -e "[X] -: $1 :- Zshing can't source This Plugin there is no [zsh/sh] extantion "
	    N_SZ=$(($N_SZ+1))
	fi
    }
fi
} #}}}

#-----------------------#
# SOURCE LOCAL PLUGINS  #
#-----------------------#
_SOURCE_LOCAL_ZSHING(){ #{{{
if [ -f $1/*.zsh ];then 
    source $1/*.zsh
elif [ -f $1/*.sh ];then 
    source $1/*.sh
else
    echo -e "[X] -: $1 :- Zshing can't source This Plugin there is no [zsh/sh] extantion "
    N_SZ=$(($N_SZ+1))
fi
} #}}}

#------------------------------#
# Source All Plugins u Install #
#------------------------------#
N_SZ=0

for SZ in ${ZSHING_PLUGINS[@]}; do 
if [ -d "$SZ" ];then 
    _SOURCE_LOCAL_ZSHING "$SZ"
else
    SZ_NAME=$(echo $SZ | cut -d / -f2-)
    _SOURCE_GIT_ZSHING_ "$SZ_NAME"
fi
done 

[ "$N_SZ" -eq 0 ] || return 1

unset SZ N_SZ

# vim: ft=zsh
