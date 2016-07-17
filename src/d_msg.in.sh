#\\rem we use kdialog as default if DE is generic unless DMSG_wDETECT_GENERIC_XMESSAGE
#\\if ! defined DMSG_WDETECT_GENERIC_ZENITY
#\\define DMSG_WDETECT_GENERIC_KDIALOG
#\\endif
detectDE()
{
    # daken from xdg-open
    # see https://bugs.freedesktop.org/show_bug.cgi?id=34164
    unset GREP_OPTIONS

    if [ -n "${XDG_CURRENT_DESKTOP}" ]; then
      case "${XDG_CURRENT_DESKTOP}" in
         ENLIGHTENMENT)
           __DE=enlightenment;
           ;;
         GNOME)
           __DE=gnome;
           ;;
         KDE)
           __DE=kde;
           ;;
         LXDE)
           __DE=lxde;
           ;;
         MATE)
           __DE=mate;
           ;;
         XFCE)
           __DE=xfce
           ;;
      esac
    fi

    if [ x"$__DE" = x"" ]; then
      # classic fallbacks
      if [ x"$KDE_FULL_SESSION" != x"" ]; then __DE=kde;
      elif [ x"$GNOME_DESKTOP_SESSION_ID" != x"" ]; then __DE=gnome;
      elif [ x"$MATE_DESKTOP_SESSION_ID" != x"" ]; then __DE=mate;
      elif $(dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.GetNameOwner string:org.gnome.SessionManager > /dev/null 2>&1) ; then __DE=gnome;
      elif xprop -root _DT_SAVE_MODE 2> /dev/null | grep ' = \"xfce4\"$' >/dev/null 2>&1; then __DE=xfce;
      elif xprop -root 2> /dev/null | grep -i '^xfce_desktop_window' >/dev/null 2>&1; then __DE=xfce
      elif echo $DESKTOP | grep -q '^Enlightenment'; then __DE=enlightenment;
      fi
    fi

    if [ x"$DE" = x"" ]; then
      # fallback to checking $DESKTOP_SESSION
      case "$DESKTOP_SESSION" in
         gnome)
           __DE=gnome;
           ;;
         LXDE|Lubuntu)
           __DE=lxde; 
           ;;
         MATE)
           __DE=mate;
           ;;
         xfce|xfce4|'Xfce Session')
           __DE=xfce;
           ;;
      esac
    fi

    if [ x"$DE" = x"" ]; then
      # fallback to uname output for other platforms
      case "$(uname 2>/dev/null)" in 
        Darwin)
          __DE=darwin;
          ;;
      esac
    fi

    if [ x"$DE" = x"gnome" ]; then
      # gnome-default-applications-properties is only available in GNOME 2.x
      # but not in GNOME 3.x
        which gnome-default-applications-properties > /dev/null 2>&1  || __DE="gnome3"
    fi

    echo $__DE
    unset __DE
}

d_msg() # display msgs and get input 
#################################################################################################
# NOTE: needs kdialog ( or zenity ) to display graphical messages and get input in gui		#
#################################################################################################
# usage:											#	       
#  d_msg [modifer] topic msg									#
#  modifers:											#	       
#  ! msg is an error/faile message								#	
#  i msg is an msg/input ( work's not properly in cgi and with xmessage : terminal)		#
#  f msg is an yes/no msg/test									#	       
#  l msg is an list of items ( nyi in cgi: terminal)                                            #
#  m normal message                                                                             #
#    no modifer is m modifer								        #
#################################################################################################
#												#
# vars:											        #
# DMSG_DE     =`detectDE` (default)  	# d_msg detects wich DE is installed and                #
#                                       # uses the coresponding dialog app                      #
# DMSG_GUI_APP=kdialog|zenity|xmessage  # tell d_msg which tool it has to use for gui output    #
#  					# either zenity, kdialog or xmessage(not recommend)     #
# 				                                                                #
#											        #
# DMSG_GUI                      	# if not zero use graphical dialog, else cfg gui        #
# DMSG_ICON				# icon that d_msg uses when is runned in gui mode       #
#                                       # if not set icon xorg is used 	                        #
#											        #
#											        #
# DMSG_APP 				# say DMSG to use $DMSG_APP in cli                      #
#                                       # ( dialog or cgi_dialog )	                        #  
#												#
# DMSG_APPNAME			        # set appname for d_msg default is $appname             #
# DMSG_ERR_STATUS = 1                   # return value that is returned when modifer is !       # 
# DMSG_XBUTTONS	= 'not:1,set:2'		# -buttons parameter for xmessage when modifer is i     #
#################################################################################################
{
    if [ ! $# -lt 2 ] ; then
	unset dmsg_return_status
	if [  "${DMSG_GUI}" = true ] || [ ! $DMSG_GUI = 0 ] ; then
	    if [  -z "$DMSG_GUI_APP" ] ; then
		DMSG_DE=$(detectDE)
	    fi
	    case $DMSG_DE in
		kde) DMSG_GUI_APP=kdialog ;; 
		gnome|xfce|mate|lxde) DMSG_GUI_APP=zenity ;;
#\\ifndef DMSG_wDETECT_GENERIC_XMESSAGE
#\\!DMSG_WDETECT_GENERIC_KDIALOG generic) DMSG_GUI_APP=kdialog ;;
#\\!DMSG_WDETECT_GENERIC_ZENITY generic) DMSG_GUI_APP=zenity ;;
#\\else
#\\warning  "xmesssage functionality is too limeted"	   
		generic) DMSG_GUI_APP=xmessage ;;
#\\endif
	    esac	
	    # FIXME or remove me
	    if  ! which $DMSG_GUI_APP > /dev/null; then
		for dmsg_gdialog_app in kdialog zenity xmessage ; do
		    if  which $dmsg_gdialog_app > /dev/null; then
			DMSG_GUI_APP=$dmsg_gdialog_app
                        break
		    else
			dmsg_gdialog_app=false
		    fi
		done
		if [ $dmsg_gdialog_app = false ] ; then
		    DMSG_GUI=0 
		    d_msg ! 'Warning' "No gui dialog tool found"
		fi
	    fi

            command=$1
            title=$2
            case $command in
                !|i|l|f|m) shift ;;
                *) command=m ;;
            esac
            shift
            
	    case $DMSG_GUI_APP in 
		kdialog)
		    case $command in 
			!)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}" --title "$title" --error "$@" 
			    dmsg_return_status=${DMSG_ERR_STAUS:=1}  
			    ;;
			i) kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}" --title "$title" --inputbox "$@" 
			    dmsg_return_status=$?
			;;
			l)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}"
			    --title "$title" --menu \
			    "$@"
			    dmsg_return_status=$? ;;
			f)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}"  --title "$title" --yesno "$@" 
			    dmsg_return_status=$? ;;
			m|*)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}" --title "$title" --msgbox "$@" 
			    dmsg_return_status=$? ;;
		    esac
		    ;;
		zenity) 
		    case $command in 
			!) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$title - ${DMSG_APPNAME:=$appname}" \
			    --error --text="$@"
			    dmsg_return_status=${DMSG_ERR_STAUS:=1}   
			    ;;
			i) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$title - ${DMSG_APPNAME:=$appname}" \
			    --entry --text="$@"
			    dmsg_return_status=$? 
			    ;;
			l) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$title- ${DMSG_APPNAME:=$appname}" \
			    --column='' --text="$@"\
                        --list 
			    dmsg_return_status=$? 
			    ;;
			f) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$title - ${DMSG_APPNAME:=$appname}" \
			    --question --text="$@" 
			    dmsg_return_status=$? 
			    ;;
			m|*) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$title - ${DMSG_APPNAME:=$appname}" \
			    --info --text="$@" 
			    dmsg_return_status=$? ;;
		    esac
		    ;;
		xmessage)
		    case $command in
			!) xmessage -center -title "$title - ${DMSG_APPNAME:=$appname}" "err: "$@"" ;
			    dmsg_return_status=${DMSG_ERR_STAUS:=1} 
			    ;;
			f) xmessage -center -title "$title  -${DMSG_APPNAME:=$appname}" -buttons no:1,yes:0 "$@" 
			    dmsg_return_status=$? 
			    ;;	
			i) 
			    if [ -z $DMSG_XBUTTONS ] ; then
				DMSG_XBUTTONS='not:1,set:2'
			    fi
			    xmessage -center -title "$appname - "$title"" -print -buttons $DMSG_XBUTTONS "$@"
			    dmsg_return_status=$?
			    ;;
			l) xmessage -center -title "$title - ${DMSG_APPNAME:=$appname}" -print \
			    -buttons "$@" ; dmsg_return_status=$? ;;
			m|*) xmessage -center -title "$title - ${DMSG_APPNAME:=$appname}" "$@" ; dmsg_return_status=$? ;;
		    esac
		    ;;
	    esac
	else
	    case ${DMSG_APP:-native} in
		dialog)
		    case $command in 
			!) dialog --title "$title -${DMSG_APPNAME:=$appname}" --infobox "error: $@" 0 0 ; dmsg_return_status=${DMSG_ERR_STAUS:=1};;
			#!) cgi_dialog ! "$3" ; dmsg_return_status=${DMG_ERR_STAUS:=1}  ;;
			f) dialog --title "$title - ${DMSG_APPNAME:=$appname}" --yesno "$@"   0 0 
			    dmsg_return_status=$?
			    ;;
			i) dialog --title "$title - ${DMSG_APPNAME:=$appname}" --inputbox "$@" 0 0
			    dmsg_return_status=$?		 
			    ;;
			m|*) dialog --title "$tile -${DMSG_APPNAME:=$appname}" --infobox "$@" 0 0  ;;
			#*) cgi_dialog "$2" ; dmsg_return_status=$? ;;
		    esac
		    ;;
		native)
		    case $command in
			!) echo  "$@" >&2; dmsg_return_status=${DMSG_ERR_STAUS:=1} ;;
			f)  echo ""$@" y|n"
			    read a 
			    if [ ! $a = y ] ; then
				dmsg_return_status=1;
			    fi
			    ;;
			i) 
			    echo "$@" >&2
			    read  a 
			    if [ -z "$a" ] ; then
				dmsg_return_status=1;
			    else
				echo $a
			    fi
			    ;;
			*|m)  echo "$@"   ; dmsg_return_status=$? ;;
		    esac
		    ;;
	    esac
	    
	fi
    fi
    return $dmsg_return_status
}

