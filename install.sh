##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "          Detach          "
  ui_print " Modded by Rom for Magisk"
  ui_print "    All credits to hinxnz"
  ui_print "*******************************"
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH 1>/dev/null
  unzip -o "$ZIPFILE" sqlite -d $MODPATH 1>/dev/null
  cp -af "$TMPDIR/compatibility.txt" "$MODPATH/compatibility.txt"
  
  #Symbolic link for lowercase/UPPERCASE support in terminal
  [ -d "$MODPATH/system/bin/" ] || mkdir -p "$MODPATH/system/bin/"
  ln -sf Detach "$MODPATH/system/bin/detach"
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $TMPDIR 0 0 0755 0644
  set_perm $MODPATH/system/bin/Detach 0 0 0777
  chmod 0755 $TMPDIR/sqlite
  chgrp 2000 $TMPDIR/sqlite
  
  chmod 0755 $MODPATH/sqlite
  chgrp 2000 $MODPATH/sqlite  

  # Here are some examples:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}

# You can add more functions to assist your custom script code

# ================================================================================================
#!/system/bin/sh

twrp() {
# Check if device is boot in TWRP/classic mode
TWRP=$(ps | grep twrp)

if [ -n "$TWRP" ]; then
	BOOT_TWRP=1
else
	BOOT_TWRP=0
fi

# Initial setup
if [ BOOT_TWRP == 1 ]; then
	PATH=$PATH:/system/xbin/:/data/adb/magisk/
fi
}


pre_request() {
magisk=$(ls /data/adb/magisk/magisk || ls /sbin/magisk) 2>/dev/null;
MAGISK_VER=$($magisk -c | sed 's/-.*//')
case "$MAGISK_VER" in
'15.'[1-9]*) # Version 15.1 - 15.9
    MODS_DIR=/sbin/.core/img
;;
'16.'[1-9]*) # Version 16.1 - 16.9
    MODS_DIR=/sbin/.core/img
;;
'17.'[1-3]*) # Version 17.1 - 17.3
    MODS_DIR=/sbin/.core/img
;;
'17.'[4-9]*) # Version 17.4 - 17.9
    MODS_DIR=/sbin/.magisk/img
;;
'18.'[0-9]*) # Version 18.x
    MODS_DIR=/sbin/.magisk/img
;;
'19.'[0-9a-zA-Z]*) # All versions 19
	MODS_DIR=/data/adb/modules
;;
'20.'[0-9a-zA-Z]*) # Version 20.x
	MODS_DIR=/data/adb/modules
;;
*)
    ui_print "Unknown Magisk version: $1"; sleep 2;
	ui_print "Cancel module setup..."; sleep 1;
	exit	
;;
esac


Detach_version=$(grep 'version=.*' "$TMPDIR/module.prop" | sed 's/version=//')
ui_print " "
ui_print "- Detach $Detach_version ===  "
ui_print "- By Rom @ xda-developers === "
ui_print " "
ui_print "- Checking pre-requests"
sleep 1;


if [[ -e "$BBOX_PATH/disable" || -e "$BBOX_PATH/SKIP_MOUNT" || -e "$BBOX_PATH/update" ]]; then
	ui_print "!- Make sure you have the 'Busybox for Android-NDK' installed on your device,"
	ui_print "!- enabled and up-to-date in your Magisk Manager."
	ui_print "!- It's a pre-request for the module."
fi


sleep 1;
ui_print "- Pre-request checks done"

sleep 1;
ui_print "- Prepare stuff"


# Extract sqlite binary file for execution in Detach works
unzip -o "$ZIPFILE" sqlite -d $TMPDIR 1>/dev/null
chmod 0777 "$TMPDIR/sqlite" && chgrp 2000 "$TMPDIR/sqlite"

if [ ! -e "$TMPDIR/sqlite" ]; then
	ui_print "!- Unable to extract binary file"
	exit 1
fi

SERVICESH=$TMPDIR/service.sh
CONF=$(ls /sdcard/Detach.txt || ls /sdcard/detach.txt || ls /sdcard/DETACH.txt || ls /storage/emulated/0/detach.txt || ls /storage/emulated/0/Detach.txt || ls /storage/emulated/0/DETACH.txt) 2>/dev/null;

if [ "$CONF" != "/sdcard/Detach.txt" -o "$CONF" != "/storage/emulated/0/Detach.txt" ]; then
mv -f "$CONF" /sdcard/Detach.txt
fi

CONF=$(ls /sdcard/Detach.txt || ls /storage/emulated/0/Detach.txt || ls /sdcard/detach.txt || ls /sdcard/DETACH.txt || ls /storage/emulated/0/detach.txt || ls /storage/emulated/0/DETACH.txt) 2>/dev/null;

UP_SERVICESSH=/data/adb/modules_update/Detach/service.sh
if [ -e "$UP_SERVICESSH" ]; then
	CTSERVICESH=$(awk 'END{print NR}' $UP_SERVICESSH)
	if [ "$CTSERVICESH" -gt "32" ]; then
		ui_print "- Cleanup file.."
		sed -i -e '32,$d' "$SERVICESH"
	fi
fi


sleep 1;
ui_print "- Prepare done"
sleep 1;
}



simple_mode_pre_request() {
ui_print "- Welcome in Simple mode :)"
ui_print ""
		
ui_print "- Checking your Detach.txt file"; sleep 1;
CONF_CHECK1=$(cat "$CONF" | grep 'Detach Market Apps Configuration')
CONF_CHECK2=$(cat "$CONF" | grep 'Remove comment (#) to detach an App.')
CONF_CHECK3=$(wc -l "$CONF" | sed "s| $CONF||")

if [ ! "$CONF_CHECK1" -o ! "$CONF_CHECK2" -o "$CONF_CHECK3" -lt "40" ]; then
	ui_print "!- Make sure you have the original 'Detach.txt' file"; sleep 1;
	ui_print "=> Download the original 'Detach.txt' file"
	wget --no-check-certificate -T 5 -q -O /sdcard/Detach.txt https://github.com/xerta555/Detach-Files/raw/master/Detach.txt  --header "header: github.com" 2>/dev/null
	chmod 0644 "/sdcard/Detach.txt"
	ui_print "- Detach.txt file created in your internal storage"; sleep 2;
fi
}



# Check for automatic custom packages names to add
simple_mode_checks() {
ui_print "- Checks beginning"; sleep 1;

# Checks for custom packages names
# Check if line 46 of Detach.txt for custom packages is writed or not
custom_check=$(tail -n +46 "$CONF" | grep '[a-zA-Z]')
# ------------------------------------------------------------------------------------


# Check if there is too much spaces in custom packages from user input
SPACES=$(sed -n '/^# Other applications/,$p' "$CONF" | sed 's/\# Other applications//' | grep '[a-zA-Z]')

if [ $(echo "$SPACES" | grep '[:blanck:]\.') ] || [ $(echo "$SPACES" | grep '. ') ] || [ $(echo "$SPACES" | grep '[[:space:]][[:space:]]')]; then
	sed -i -e 's/ ././' -e 's/. /./' -e 's/ \+//' "$CONF" 2>/dev/null
fi
# ------------------------------------------------------------------------------------


# Check if custom packages names exist on Play Store (WIFI and/or LTE are require)
touch "$TMPDIR/DL_check.txt"
cat "$CONF" | tail -n +5 | sed -n '/# Other applications/q;p' | grep '[a-zA-Z0-9]' > "$TMPDIR/CHECK_BASIC_IN_CUST.txt"

sed -n '/# Other applications/,$p' "$CONF" | sed '1d' >> "$TMPDIR/CHECK_ONLINE.txt"

# Only use wget and extract exact app Name only if custom app exist in the Detach.txt to avoid wrong wget output.
if [ -s "$TMPDIR/CHECK_ONLINE.txt" ]; then
ONLINE=$(awk '{ print }' "$TMPDIR/CHECK_ONLINE.txt")

printf '%s\n' "$ONLINE" | while IFS= read -r line
	do echo "$line | " >> "$TMPDIR/DL_check.txt"
	wget --no-check-certificate -q -O "${TMPDIR}/$line.html" "https://play.google.com/store/apps/details?id=${line}&hl=en" --header "header: play.google.com" 2>&1 >> "$TMPDIR/$line_DL_check.txt"
	cat "$TMPDIR/$line_DL_check.txt" | grep '404' | awk '{ print $1 }' > "$TMPDIR/$line_DL_final_check.txt"
	
	if [ -s "$TMPDIR/$line_DL_final_check.txt" ]; then
		CH_ONLINE=1
	else
		grep 'AHFaub' "$TMPDIR/$line.html" | tail -1 | cut -f1,2,3 -d'<' | sed 's/.*>//' | sed 's/(Trial)//' | sed 's/(Trial version)//' | sed 's/-.*//' | sed 's/:.*//' | sed 's/★.*//' | sed 's/ &amp.*//' | sed 's/\|.*//' | tr -d '\n' >> "$TMPDIR/$line.txt" && cp -f "$TMPDIR/$line.txt" /sdcard
				
		CUST_NAME_var=$(awk '{ print }' "$TMPDIR/$line.txt")
		if grep -qs "$CUST_NAME_var" "$TMPDIR/CHECK_BASIC_IN_CUST.txt"; then
			CUST_BASIC_LINE_NUM=$(grep -n "$CUST_NAME_var" "$TMPDIR/CHECK_BASIC_IN_CUST.txt" | sed 's/:.*//')
			ui_print "- Enable $CUST_NAME_var as basic app"
			sed -i -e "${CUST_BASIC_LINE_NUM}s/#//" "$CONF"
			CUST_2_REM=$(grep -n "$line" "$CONF" | sed 's/:.*//')
			ui_print "- Removing $line from Other applications"
			sed -i -e "${CUST_2_REM}d" "$CONF"
		fi
	fi
done
fi


# Exist in detach.txt or custom packages
# Check if one of custom packages names exist in the detach.txt file (to avoid duplicates)
COMPARE_MAIN=$TMPDIR/COMPARE_MAIN.txt
COMPARE_CUSTOM=$TMPDIR/COMPARE_CUSTOM.txt

for v in "$COMPARE_MAIN" "$COMPARE_CUSTOM"; do touch "$v" && chmod 0644 "$v"; done

cat "$CONF" | tail -n +5 | sed '1,/\# Other applications/!d' | sed 's/# Other applications//' |  grep -v -e "#.*" | grep '[A-Za-z0-9]' > "$COMPARE_MAIN"
sed -n '/# Other applications/,$p' "$CONF" | sed '1d' > "$COMPARE_CUSTOM"

# Check if there is/are duplicate(s) in the Common=Main apps
COMP_WRONG_M=$(awk 'NR==FNR{a[$1]++;next} a[$1] ' "$COMPARE_MAIN" "$COMPARE_CUSTOM")

# If there is an error in the Custom apps
COMP_WRONG_C=$(awk 'NR==FNR{a[$1]++;next} a[$1] ' "$COMPARE_CUSTOM" "$COMPARE_MAIN")
if [ "$COMP_WRONG_M" ]; then
	ui_print "- Be carreful! $line already exist in the common apps list"; sleep 1;
	CH_DUPLICATE=0
fi
if [ "$COMP_WRONG_C" ]; then
	ui_print "- Be carreful! $line already exist in the custom apps list"; sleep 1;
	CH_DUPLICATE=0
fi
# ------------------------------------------------------------------------------------


ui_print "- Custom apps compatibility checks done."
sleep 1;
}



simple_mode_basic() {	
ui_print "- Following basic apps will be hidden:"
sleep 1;
DETACH=$TMPDIR/basic_apps.txt
echo "" >> "$DETACH"
	
if grep -qo '^Gmail' $CONF; then
	ui_print "Gmail"
	echo "  # Gmail" >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.gm\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Google App' $CONF; then
	ui_print "Google App"
	echo '  # Google App' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.googlequicksearchbox\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Google Plus' $CONF; then
	ui_print "Google Plus"
	echo '  # Google Plus' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.plus\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Hangouts' $CONF; then
	ui_print "Hangouts"
	echo '  # Hangouts' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.talk\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^YouTube' $CONF; then
	ui_print "YouTube"
	echo '  # YouTube' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.youtube\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Gboard' $CONF; then
	ui_print "Gboard"
	echo '  # Gboard' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.inputmethod.latin\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Contacts' $CONF; then
	ui_print "Contacts"
	echo '  # Contacts' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.contacts\''";' >> $DETACH
	echo '' >> $DETACH
	fi
if grep -qo '^Phone' $CONF; then
	ui_print "Phone"
	echo '  # Phone' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.dialer\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Photos' $CONF; then
	ui_print "Photos"
	echo '  # Photos' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.photos\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Clock' $CONF; then
	ui_print "Clock"
	echo '  # Clock' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.deskclock\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Camera' $CONF; then
	ui_print "Camera"
	echo '  # Camera' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.GoogleCamera\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Inbox' $CONF; then
	ui_print "Inbox"
	echo '  # Inbox' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.inbox\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Duo' $CONF; then
	ui_print "Duo"
	echo '  # Duo' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.tachyon\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Dropbox' $CONF; then
	ui_print "Dropbox"
	echo '  # Dropbox' >> $DETACH
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.dropbox.android\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^PushBullet' $CONF; then
	ui_print "PushBullet"
	echo '  # PushBullet' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.pushbullet.android\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Calendar' $CONF; then
	ui_print "Calendar"
	echo '  # Calendar' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.calendar\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Keep' $CONF; then
	ui_print "Keep"
	echo '  # Keep' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.keep\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Telegram' $CONF; then
	ui_print "Telegram"
	echo '  # Telegram' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'org.telegram.messenger\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Swiftkey' $CONF; then
	ui_print "Swiftkey"
	echo '  # Swiftkey' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.touchtype.swiftkey\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Translate' $CONF; then
	ui_print "Translate"
	echo '  # Translate' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.translate\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Facebook' $CONF; then
	ui_print "Facebook"
	echo '  # Facebook' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.facebook.katana\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Pandora' $CONF; then
	ui_print "Pandora"
	echo '  # Pandora' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.pandora.android\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Twitter' $CONF; then
	ui_print "Twitter"
	echo '  # Twitter' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.twitter.android\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Slack' $CONF; then
	ui_print "Slack"
	echo '  # Slack' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.Slack\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Mega' $CONF; then
	ui_print "Mega"
	echo '  ' >> $DETACH 
	echo '  # Mega' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'mega.privacy.android.app\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^WhatsApp' $CONF; then
	ui_print "WhatsApp"
	echo '  # WhatsApp' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.whatsapp\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Voice' $CONF; then
	ui_print "Voice"
	echo '  # Voice' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.googlevoice\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Drive' $CONF; then
	ui_print "Drive"
	echo '  # Drive' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.docs\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Netflix' $CONF; then
	ui_print "Netflix"
	echo '  # Netflix' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.netflix.mediaclient\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Pixel Launcher' $CONF; then
	ui_print "Pixel Launcher"
	echo '  # Pixel Launcher' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.nexuslauncher\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Wallpapers' $CONF; then
	ui_print "Wallpapers"
	echo '  # Wallpapers' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.wallpaper\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Capture' $CONF; then
	ui_print "Capture"
	echo '  # Capture' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.gopro.smarty\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Google Connectivity Services' $CONF; then
	ui_print "Google Connectivity Services"
	echo '  # Google Connectivity Services' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.apps.gcs\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Google VR Services' $CONF; then
	ui_print "Google VR Services"
	echo '  # Google VR Services' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.vr.vrcore\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Google Play Services' $CONF; then
	ui_print "Google Play Services"
	echo '  # Google Play Services' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.gms\''";' >> $DETACH
	echo '' >> $DETACH
fi
if grep -qo '^Google Carrier Services' $CONF; then 
	ui_print "Google Carrier Services"
	echo '  # Google Carrier Services' >> $DETACH 
	echo '	./sqlite $PLAY_DB_DIR/library.db "UPDATE ownership SET library_id = '\'u-wl\' where doc_id = \'com.google.android.ims\''";' >> $DETACH
fi
cat "$DETACH" >> "$SERVICESH"
echo " " >> "$SERVICESH"
# rm -f $DETACH
sleep 1;
ui_print "- The hidden of basic applications is done.";sleep 1;
}



nothing_to_add() {
ui_print "- You have not uncommented any basic application"
ui_print "  or"
ui_print "- written any custom application in your /sdcard/Detach.txt file."
ui_print ""
ui_print "- At least uncomment one or write a custom package name..."
ui_print ""
ui_print "- Install exist..."
}



direct_custom_install() {
ui_print ""
ui_print "- Following custom apps will be hidden:"
sleep 1;

FINALCUST=$TMPDIR/FINALCUST.txt
SQSH=$TMPDIR/sqlite.txt
SQSHBAK=$TMPDIR/sqlite.bak

echo -e "# Custom Packages" >> "$FINALCUST"
cp -af "$SQSH" "$SQSHBAK"

echo "$CHECK_PACKAGES" >> "$TMPDIR/CHECK_PACKAGES.txt"

FINAL_PACKS=$(awk '{ print }' "$TMPDIR/CHECK_PACKAGES.txt")

SHOW_PACKS=$(echo "$FINAL_PACKS" | tr -d '\r')
printf '%s\n' "$SHOW_PACKS" | while IFS= read -r line
	do ui_print "- $line"
done

printf '%s\n' "$FINAL_PACKS" | while IFS= read -r line
	do
	var_CUST_NAME=$(cat "$TMPDIR/$line.txt") 
	RIGHT_NAME=$(echo "$line")
	echo -e "	# $var_CUST_NAME\n	./sqlite \$PLAY_DB_DIR/library.db \"UPDATE ownership SET library_id = 'u-wl' where doc_id = '$line'\";\n" >> "$FINALCUST"
done

cat "$FINALCUST" >> "$SERVICESH"
ui_print "- Custom apps has been added successfully"
sleep 1;
}


simple_mode_no_custom() {
	ui_print "=> No custom app added"
	sleep 2;
}




instant_detach() {
ui_print ""
ui_print "=========================="
ui_print "- Detach work in progress"
ui_print "..."; sleep 1;

instant_run=$TMPDIR/instant_run.sh
instant_run_two=$TMPDIR/instant_run_two.sh
test -e "$instant_run" || touch "$instant_run"
chmod 0777 "$instant_run" && chmod +x "$instant_run"
PS_DATA_PATH=/data/data/com.android.vending/databases/library.db
	
# Multiple Play Store accounts compatibility
ps_accounts=$("$TMPDIR/sqlite" $PS_DATA_PATH "SELECT account FROM ownership" | sort -u | wc -l)
	
cat /dev/null > "$instant_run"

echo -e "PLAY_DB_DIR=/data/data/com.android.vending/databases\nSQLITE=${TMPDIR}\n\n\nam force-stop com.android.vending\n\ncd \$SQLITE\n\n" >> "$instant_run"
sed -n '32,$p' "$SERVICESH" | grep sqlite  >> "$instant_run"
	
echo -e "\n" >> "$instant_run"
	
test -e "$TMPDIR/first_detach_result.txt" || touch "$TMPDIR/first_detach_result.txt"
chmod 0777 "$TMPDIR/first_detach_result.txt"
sh "$instant_run" > "$TMPDIR/first_detach_result.txt" 2>&1
	
if [ "$ps_accounts" -gt "1" ]; then
	test -e "$instant_run_two" || touch "$instant_run_two"
	chmod 0777 "$instant_run_two" && chmod +x "$instant_run_two"
	echo -e "PLAY_DB_DIR=/data/data/com.android.vending/databases\nSQLITE=$TMPDIR\n\n\nam force-stop com.android.vending\n\ncd \$SQLITE\n\n" > "$instant_run_two"
	am force-stop com.android.vending
	for i in {1..${ps_accounts_final}}; do grep sqlite "$instant_run" >> "$instant_run_two"; done
	sed -i -e 's/.\t\/sqlite/.\/sqlite/' "$instant_run_two"
	sed -i -e 's/..\/sqlite/.\/sqlite/' "$instant_run_two"
	sed -i -e "s/SQLITE=\$MODD.\/sqlite//" "$instant_run_two"
	echo -e '\n' >> "$instant_run_two"
	sh "$instant_run_two"
	
fi
	
		
wrong_result=$(echo "Error: UNIQUE constraint failed: ownership.account,")
if grep -q "$wrong_result" "$TMPDIR/first_detach_result.txt"; then
	ui_print " "
	ui_print "Database file corrupted"
	ui_print "Database file need to be fixed, so please wait some little seconds."
	ui_print "..."; sleep 1;
	
	ACTAPPS=$TMPDIR/actapps.txt
	ACTAPPSBCK=$TMPDIR/actapps.bak
	FINAL=$TMPDIR/final.sh
	
	for o in "$ACTAPPS" "$ACTAPPSBCK" "$FINAL"; do touch "$o" && cat /dev/null > "$o" && chmod 0644 "$o"; done
	
	PLAY_DB_DIR=/data/data/com.android.vending/databases
	
	grep sqlite "$SERVICESH" > "$ACTAPPS"
	sed -i -e "s/.\/sqlite \$PLAY_DB_DIR\/library.db \"UPDATE ownership SET library_id = 'u-wl' where doc_id = '//" -i -e "s/'\";//" "$ACTAPPS"
	sed -i -e '1d' "$ACTAPPS"
	sed -i -e 's/[[:blank:]]*//' "$ACTAPPS"
		
	cp -f "$ACTAPPS" "$ACTAPPSBCK"
	
	var_ACTAPPS=$(awk '{ print }' "$ACTAPPSBCK")
	
	am force-stop com.android.vending
	
	FIRST_PCK_NAME=$(head -n 1 "$ACTAPPS")
	PRESENT_DIR=$(pwd)
	SQL_ENTRY_TEST=$(cd $TMPDIR && ./sqlite $PLAY_DB_DIR/library.db "SELECT * FROM ownership WHERE doc_id = '${FIRST_PCK_NAME}' AND library_id='3'" | wc -l)
	cd "$PRESENT_DIR"
	ZERO=0
	chmod +x "$FINAL"
		
	echo -e "PS_DATA_PATH=\/data\/data\/com.android.vending\/databases\/library.db\n\ncd $TMPDIR\n\n" >> "$FINAL"
	
	if [ "$SQL_ENTRY_TEST" -eq 1 ]; then
		printf '%s\n' "$var_ACTAPPS" | while IFS= read -r line
			do echo -e "./sqlite $PLAY_DB_DIR/library.db \"DELETE FROM ownership WHERE doc_id = '$line' AND library_id = '3'\";\n" >> "$FINAL"
		done
		cd "$TMPDIR"
		chmod +x "$FINAL"
		sh "$FINAL"
		cd "$PRESENT_DIR"
	else
		echo -e "\ncd $TMPDIR\n\n" >> "$FINAL"
		while [ "$ZERO" -le "$SQL_ENTRY_TEST" ]; do
			printf '%s\n' "$var_ACTAPPS" | while IFS= read -r line
				do echo -e "./sqlite $PLAY_DB_DIR/library.db \"DELETE FROM ownership WHERE doc_id = '$line' AND library_id = '3'\";\n" >> "$FINAL"
			done
			SQL_ENTRY_TEST=$(($SQL_ENTRY_TEST - 1))
		done
		cd "$TMPDIR"
		chmod +x "$FINAL"
		sh "$FINAL"
		cd "$PRESENT_DIR"
	fi
	
	for f in "$ACTAPPS" "$ACTAPPSBCK"; do rm -f "$f"; done
	ui_print "Database file fixed."
	ui_print "..."; sleep 1;
fi
		
ui_print "- Detach done"
ui_print "=========================="
ui_print ""
sleep 1;


for w in "$FINALCUST" "$SQSHBAK" "$SQSH" "$BAK" "$instant_run"; do rm -f "$w"; done
}
# ================================================================================================

complete_script() {
ui_print "- Finish the script file..";sleep 1;

cat "$TMPDIR/compatibility.txt" >> "$SERVICESH"

echo "" >> "$SERVICESH"
echo "# Exit" >> "$SERVICESH"
echo "	exit; fi" >> "$SERVICESH"
echo "done &)" >> "$SERVICESH"

ui_print "- Boot script file is now finished."
ui_print "- Reboot your device before using the terminal commands."
ui_print "=> Just reboot now (:"
sleep 1;
}
# ================================================================================================
# ================================================================================================
# ================================================================================================
# Detach Module setup
# Rom @ xda-devlopers

twrp
pre_request

SIMPLE=/sdcard/simple_mode.txt

test -e "$SIMPLE" && simple_mode_pre_request
# ----------------------------------

# Check for basics and/or customs
CHECK=$(cat "$CONF" | tail -n +5 | sed -n '/# Other applications/q;p' |  grep -v -e "#.*" | grep '[A-Za-z0-9]')
CHECK_OTHER=$(cat "$CONF" | tail -n +45 | grep -v '# Other applications' | grep '[0-9A-Za-z]')
CHECK_PACKAGES=$(cat "$CONF" | tail -n +46 | grep '[0-9A-Za-z]')

# Checks for Detach.txt file
simple_mode_checks

[[ "$CH_ONLINE" == "1" || "$CH_DUPLICATE" == "0" ]] && exit



# For common app(s) ONLY
[ "$CHECK" ] && simple_mode_basic
# ----------------------------------



# If NO basic applications and NO custom packages names
[ -e "$SIMPLE" -a ! "$CHECK" -a ! "$CHECK_PACKAGES" ] && nothing_to_add && exit



# Simple mode - if '# Other applications' is write in Detach.txt WITHOUT custom packages names
if [ -e "$SIMPLE" -a "$CHECK_OTHER" -a ! "$CHECK_PACKAGES" ]; then
	ui_print "!- Warning:"
	ui_print "!- You have enable custom packages application"
	ui_print "!- in your /sdcard/Detach.txt file".
	ui_print "!- But you don't have write any custom packages names after that."
	ui_print "!- We are going to ignore it for this time."
fi



# Simple mode - if '# Other applications' is write in Detach.txt WITH custom packages names
[ -e "$SIMPLE" -a "$CHECK_OTHER" -a "$CHECK_PACKAGES" ] && direct_custom_install
# ----------------------------------

# If '# Other applications' is write in Detach.txt with custom packages names
[ ! -e "$SIMPLE" -a "$CHECK_OTHER" -a "$CHECK_PACKAGES" ] && direct_custom_install
# ----------------------------------

# NO '# Other applications' and NO custom packages names write in Detach.txt
[ -z "$CHECK_OTHER" -a -z "$CHECK_PACKAGES" ] && simple_mode_no_custom
# ----------------------------------


# Finishing the setup
# ----------------------------------
instant_detach
complete_script


ui_print "- Module setup done"
ui_print " "
