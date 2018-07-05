# zshing

## Table of Contents

- [About](#about)
- [Quick Start](#quick-start)
- [People Using Zshing](#people-using-zshing)
- [TODO](#todo)

## About

[Zshing] Zsh plugin manager similaire to VundleVim

[Zshing] allows you to...

* keep track of and [configure] your plugins right in the `.zshrc`
* [install] configured plugins (a.k.a. scripts/bundle)
* [update] configured plugins
* [search] by name all available [Zsh Plugins]
* [clean] unused plugins up
* run the above actions in a *single keypress*

[Zshing] automatically...

* manages the [Source Plugins] of your installed Plugins

[Zshing] is undergoing an [interface change], please stay up to date to get latest changes.

![Vundle-installer](http://i.imgur.com/Rueh7Cc.png)

## Quick Start

1. Introduction:

   Installation requires [Git] and triggers [`git clone`] for each configured repository to `~/.vim/bundle/` by default.
   Curl is required for search.

   Using non-POSIX shells, such as the popular Fish shell, requires additional setup. Please check the [FAQ].

2. Set up [Zshing]:

   ` git clone https://github.com/zakariaGatter/zshing.git ~/.zshing/zshing`

3. Configure Plugins:

   Put this at the top of your `.zshing` to use Zshing. Remove plugins you don't need, they are for illustration purposes.

   ```zsh
    #{{{
    # Set Plugin configuration Before ZSHING_PLUGINS

    #}}}
    
    ZSHING_PLUGINS=(
        "zakariaGatter/zshing"
        "zakariaGatter/MarkEdit"
        "zakariaGatter/MarkGate"
    )
   ```

4. Install Plugins:

   run from commmand line `zshing_install`

## People Using Zshing

```
    ZSHING ( 0.1 )
    Write by Zakaria Gatter (zakaria.gatter@gmail.com)

    Zsh Plugin to manage Plugin semiler to VundleVim

    OPTS : 
        zshing_install  [Install Plugin direct from source]
        zshing_update   [Update exist Plugins in youe system]
        zshing_clean    [Clean and Remove unwanted Plugins]
        zshing_search   [Search for Plugins Themes and Completions]
        zshing_help     [Show this help Dialog]
```

## TODO
[Zshing] is a work in progress, so any ideas and patches are appreciated.

* [X] Install Plugins 
* [X] Search for Plugins
* [X] Update Plugins 
* [X] Clean Unwanted Plugins
* [ ] Update Plugins List everytime you run `zshing_search`
* [ ] install Plugins From Other websites


[Zshing]:http://github.com/zakariaGatter/zshing.vim
