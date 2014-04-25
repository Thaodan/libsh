#\\rem we use kdialog as default if DE is generic unless DMSG_wDETECT_GENERIC_XMESSAGE
#\\if ! defined DMSG_WDETECT_GENERIC_ZENITY
#\\define DMSG_WDETECT_GENERIC_KDIALOG
#\\endif
detectDE() 
# detect which DE is running
# taken from xdg-email script 
{
    if [ x"$KDE_FULL_SESSION" = x"true" ]; then 
	echo kde
    elif [ x"$GNOME_DESKTOP_SESSION_ID" != x"" ]; then 
       echo gnome
    elif $(dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
	org.freedesktop.DBus.GetNameOwner \
	string:org.gnome.SessionManager > /dev/null 2>&1) ; then 
	echo gnome
    elif xprop -root _DT_SAVE_MODE 2> /dev/null | grep ' = \"xfce4\"$' >/dev/null 2>&1; then 
	echo xfce
    else 
	echo generic
    fi
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
#  l msg is an list of items ( nyi in cgi: terminal)						#
#    no modifer msg is an normal msg								#
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
		gnome|xfce) DMSG_GUI_APP=zenity ;;
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
		    else
			dmsg_gdialog_app=false
		    fi
		done
		if [ $dmsg_gdialog_app = false ] ; then
		    DMSG_GUI=0 
		    d_msg ! 'Warning' "No gui dialog tool found"
		fi
	    fi 
	    case $DMSG_GUI_APP in 
		kdialog)
		    case $1 in 
			!)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}" --title "$2" --error "$3" 
			    dmsg_return_status=${DMSG_ERR_STAUS:=1}  
			    ;;
			i) kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}" -title "$2" --inputbox "$3" 
			    dmsg_return_status=$?
			;;
			l)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}"
			    --title "$2" --menu \
			    "$3" "$4" "$5" "$6" "$7" "$8" "$9" 4
			    shift ; dmsg_return_status=$? ;;
			f)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}"  --title "$2" --yesno "$3" 
			    dmsg_return_status=$? ;;
			*)  kdialog --icon ${DMSG_ICON:=xorg} --caption "${DMSG_APPNAME:=$appname}" -title "$1" --msgbox "$2" 
			    dmsg_return_status=$? ;;
		    esac
		    ;;
		zenity) 
		    case $1 in 
			!) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$2 - ${DMSG_APPNAME:=$appname}" \
			    --error --text="$3"
			    dmsg_return_status=${DMSG_ERR_STAUS:=1}   
			    ;;
			i) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$2 - ${DMSG_APPNAME:=$appname}" \
			    --entry --text="$3"
			    dmsg_return_status=$? 
			    ;;
			l) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$2  -${DMSG_APPNAME:=$appname}" \
			    --column='' --text="$3"\
                        --list 
			    dmsg_return_status=$? 
			    ;;
			f) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$2  -${DMSG_APPNAME:=$appname}" \
			    --question --text="$3" 
			    dmsg_return_status=$? 
			    ;;
			*) zenity --window-icon=${DMSG_ICON:=xorg}  --title="$1  -${DMSG_APPNAME:=$appname}" \
			    --info --text="$2" 
			    dmsg_return_status=$? ;;
		    esac
		    ;;
		xmessage)
		    case $1 in
			!) xmessage -center -title "$2 - ${DMSG_APPNAME:=$appname}" "err: "$3"" ;
			    dmsg_return_status=${DMSG_ERR_STAUS:=1} 
			    ;;
			f) xmessage -center -title "$2  -${DMSG_APPNAME:=$appname}" -buttons no:1,yes:0 "$3" 
			    dmsg_return_status=$? 
			    ;;	
			i) 
			    if [ -z $DMSG_XBUTTONS ] ; then
				DMSG_XBUTTONS='not:1,set:2'
			    fi
			    xmessage -center -title "$appname - "$2"" -print -buttons $DMSG_XBUTTONS "$3"
			    dmsg_return_status=$?
			    ;;
			l) xmessage -center -title "$2 - ${DMSG_APPNAME:=$appname}" -print \
			    -buttons "$3","$4","$5","$6","$7","$8","$9" ; dmsg_return_status=$? ;;
			*) xmessage -center -title "$1 - ${DMSG_APPNAME:=$appname}" "$2" ; dmsg_return_status=$? ;;
		    esac
		    ;;
	    esac
	else
	    case ${DMSG_APP:-native} in
		dialog)
		    case "$1" in 
			!) dialog --title "$2 -${DMSG_APPNAME:=$appname}" --infobox "error:$3" 0 0 ; dmsg_return_status=${DMSG_ERR_STAUS:=1};;
			#!) cgi_dialog ! "$3" ; dmsg_return_status=${DMG_ERR_STAUS:=1}  ;;
			f) dialog --title "$2 - ${DMSG_APPNAME:=$appname}" --yesno "$3"   0 0 
			    dmsg_return_status=$?
			    ;;
			i) dialog --title "$2 - ${DMSG_APPNAME:=$appname}" --inputbox "$3" 0 0
			    dmsg_return_status=$?		 
			    ;;
			*) dialog --title "$1 -${DMSG_APPNAME:=$appname}" --infobox "$2" 0 0  ;;
			#*) cgi_dialog "$2" ; dmsg_return_status=$? ;;
		    esac
		    ;;
		native)
		    case "$1" in
			!) echo  "$3" >&2; dmsg_return_status=${DMSG_ERR_STAUS:=1} ;;
			f)  echo ""$3" y|n"
			    read a 
			    if [ ! $a = y ] ; then
				dmsg_return_status=1;
			    fi
			    ;;
			i) 
			    echo "$3" >&2
			    read  a 
			    if [ -z "$a" ] ; then
				dmsg_return_status=1;
			    else
				echo $a
			    fi
			    ;;
			*)  echo "$2"   ; dmsg_return_status=$? ;;
		    esac
		    ;;
	    esac
	    
	fi
    fi
    return $dmsg_return_status
}

