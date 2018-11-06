#!/bin/sh

# Script to cleanly layout Thunderbird preferences
#
# Copyright (C) 2018 Embecosm Limited
#
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
# Top level autoconf configuration file

# When rebuilding Thunderbird it is useful to be able to extract old config
# information in the form needed when configuring Thunderbird

# The name of a configuration directory is provided as argument. This will be
# a top level directory in ~/.thunderbird of the form XXXXXXX.default,
# although it will likely have been moved elsewhere if this is a clean start.


# Utility shell function to find a user_pref value from a key

# @param[in] $1 Key to look up
# @return  0 on success, 1 on failure (key not found)

user_pref () {
    key=$1
    if line=$(grep "user_pref(\"${key}\"," ${prefs})
    then
	val=$(printf "%s" "${line}" | sed -e 's/^.*, "\([^"]*\).*$/\1/')
	if [ "x${line}" = "x${val}" ]
	then
	    val=$(printf "%s" "${line}" | sed -e 's/^.*, \([^)]*\).*$/\1/')
	fi
	echo ${val}
	return 0
    else
	return 1
    fi
}


# Utility shell function to find a user_pref value from a key with a default

# This always succeeds, since if we don't find the value, we use the default

# @param[in] $1 Key to look up
# @param[in] $2 Default value

default_pref () {
    key="$1"
    default="$2"

    if val=$(user_pref "${key}")
    then
	printf "%s" "${val}"
    else
	printf "%s" "${default}"
    fi
}


# Utility shell function to find a user_pref yes/no value

# This always succeeds, since if we don't find the value, we use the default

# Note that whether "true" means yes or no varies, so we specify

# @param[in] $1 Key to look up
# @param[in] $2 Default value ("true" or "false")
# @param[in] $3 Text corresponding to true ("Yes" or "No")

yes_no_pref () {
    key=$1
    default=$2
    trueval=$3

    if [ "${trueval}" = "Yes" ]
    then
	falseval="No"
    else
	falseval="Yes"
    fi

    if [ $(default_pref "${key}" "${default}") = "true" ]
    then
	printf "%s" ${trueval}
    else
	printf "%s" ${falseval}
    fi
}


# Dump all the data for one account

# @param[in] $1  Identifies
# @param[in] $2  Server

dump_data () {
    idstr="mail.identity.$1"
    servstr="mail.server.$2"

    printf "\n==============================================================\n\n"
    printf "Account Settings\n"
    printf "%s\n\n" "----------------"

    ac_name=$(user_pref "${servstr}.name")
    your_name=$(user_pref "${idstr}.fullName")
    email=$(user_pref "${idstr}.useremail")
    reply_to=$(user_pref "${idstr}.reply_to")
    org=$(user_pref "${idstr}.organization")
    sig=$(user_pref "${idstr}.htmlSigText")
    smtp=$(user_pref "${idstr}.smtpServer")
    smtpdesc=$(user_pref "mail.smtpserver.${smtp}.description")
    smtphost=$(user_pref "mail.smtpserver.${smtp}.hostname")

    printf "%-25s %s\n" "Account Name:"     "${ac_name}"
    printf "%-25s %s\n" "Your Name:"        "${your_name}"
    printf "%-25s %s\n" "Email Address:"    "${email}"
    printf "%-25s %s\n" "Reply-to Address:" "${reply_to}"
    printf "%-25s %s\n" "Organization:"     "${org}"
    printf "Signature text:\n\n"
    printf "%s\n\n" "${sig}"
    printf "%-25s %s (%s)\n" "Outgoing Server (SMTP): " "${smtpdesc}" \
	   "${smtphost}"

    printf "\nServer Settings\n"
    printf "%s\n\n" "---------------"

    server_name=$(user_pref "${servstr}.hostname")
    port=$(user_pref "${servstr}.port")
    user_name=$(user_pref "${servstr}.userName")
    conn_sec="SSL/TLS*"
    auth_meth=$(user_pref "${servstr}.authMethod")
    case "${auth_method}"
    in
	3) auth_meth="Normal Password"
	   ;;
	*) auth_meth="OAuth2"
	   ;;
    esac
    check_for_new=$(user_pref "${servstr}.check_new_mail")
    case "${check_for_new}"
    in
	true) check_for_new="Yes"
	      ;;
	*) check_for_new="No"
	   ;;
    esac
    bin=$(user_pref "${servstr}.trash_folder_name" | \
	      sed -e "s|\[Gmail\]/\(.*\$\)|\1 on ${ac_name}|")
    clean_on_exit=$(user_pref "${servstr}.cleanup_inbox_on_exit")
    case "${clean_on_exit}"
    in
	true) clean_on_exit="Yes"
	      ;;
	*) clean_on_exit="No"
	   ;;
    esac
    dir=$(user_pref "${servstr}.directory")

    printf "%-35s %s\n" "Server Name:"                       "${server_name}"
    printf "%-35s %s\n" "User Name:"                         "${user_name}"
    printf "%-35s %s\n" "Port:"                              "${port}"
    printf "%-35s %s\n" "Connection security:"               "${conn_sec}"
    printf "%-35s %s\n" "Authentication method:"             "${auth_meth}"
    printf "%-35s %s\n" "Check for new messages at startup:" \
	   "${check_for_new}"
    printf "%-35s %s\n" "Move mail to: " "${bin}"
    printf "%-35s %s\n" "Clean up (\"Expunge\") Inbox on exit:" \
	   "${clean_on_exit}"
    printf "%-35s\n" "Local directory:"
    printf "   %s\n" "${dir}"

    printf "\nCopies & Folders\n"
    printf "%s\n\n" "----------------"

    sent=$(user_pref "${idstr}.fcc_folder" | \
	       sed -e "s|^.*\[Gmail\]/\(.*\$\)|\1 on ${ac_name}|")
    if [ "x${sent}" != "x" ]
    then
	do_sent="true"
    else
	do_sent="false"
    fi
    do_bcc=$(user_pref "${idstr}.doBcc")
    if [ "xtrue" = "x${do_bcc}" ]
    then
	bcc=$(user_pref "${idstr}.doBccList")
    fi
    archives=$(user_pref "${idstr}.archive_folder" | \
		   sed -e "s|^.*\[Gmail\]/\(.*\$\)|\1 on ${ac_name}|" | \
		   sed -e "s|^imap://.*|Archives Folder on: ${ac_name}|")

    if [ "x${archives}" != "x" ]
    then
	do_archives="true"
    else
	do_archives="false"
    fi
    drafts=$(user_pref "${idstr}.draft_folder" | \
		   sed -e "s|^.*\[Gmail\]/\(.*\$\)|\1 on ${ac_name}|" | \
		   sed -e "s|^imap://.*|Drafts Folder on: ${ac_name}|")

    if [ "x${drafts}" != "x" ]
    then
	do_drafts="true"
    else
	do_drafts="false"
    fi
    templates=$(user_pref "${idstr}.stationery_folder" | \
		   sed -e "s|^.*\[Gmail\]/\(.*\$\)|\1 on ${ac_name}|" | \
		   sed -e "s|^imap://.*|Templates Folder on: ${ac_name}|")

    if [ "x${templates}" != "x" ]
    then
	do_templates="true"
    else
	do_templates="false"
    fi

    if [ "xtrue" = "x${do_sent}" ]
    then
	printf "%-26s %s\n" "Place a copy in:" "${sent}"
    fi
    if [ "xtrue" = "x${do_bcc}" ]
    then
	printf "%-26s %s\n" "Bcc these mail addresses:" "${bcc}"
    fi
    if [ "xtrue" = "x${do_archives}" ]
    then
	printf "%-26s %s\n" "Keep message archives in:" "${archives}"
    fi
    if [ "xtrue" = "x${do_drafts}" ]
    then
	printf "%-26s %s\n" "Keep message drafts in:" "${drafts}"
    fi
    if [ "xtrue" = "x${do_templates}" ]
    then
	printf "%-26s %s\n" "Keep message templates in:" "${templates}"
    fi

    printf "\nComposition & Addressing\n"
    printf "%s\n\n" "------------------------"

    compose_html=$(user_pref "${idstr}.compose_html")
    case "${compose_html}"
    in
	true) compose_html="Yes"
	      ;;
	*) compose_html="No"
	   ;;
    esac
    reply_loc=$(user_pref "${idstr}.reply_on_top")
    case "${reply_loc}"
    in
	0) reply_loc="Start my reply below the quote"
	   ;;
	1) reply_loc="Start my reply above the quote"
	   ;;
	2) reply_loc="Select the quote"
	   ;;
	*) reply_loc=""
	   ;;
    esac
    sig_on_reply=$(user_pref "${idstr}.sig_on_reply")
    case "${sig_on_reply}"
    in
	false) sig_on_reply="No"
	      ;;
	*) sig_on_reply="Yes"			# Default
	   ;;
    esac
    sig_on_fwd=$(user_pref "${idstr}.sig_on_fwd")
    case "${sig_on_fwd}"
    in
	true) sig_on_fwd="Yes"
	      ;;
	*) sig_on_fwd="No"
	   ;;
    esac
    glob_ldap="Use my gloval LDAP server preferences for this account*"

    printf "%-26s %s\n" "Compose messages in HTML format:" "${compose_html}"
    if [ "x" != "x${reply_loc}" ]
    then
	printf "Automatically quote the original message when replying\n"
	printf "  Then, ${reply_loc}\n"
    fi
    printf "%-26s %s\n" "Include signature for replies:" "${sig_on_reply}"
    printf "%-26s %s\n" "Include signature for forwards:" "${sig_on_fwd}"
    printf "%s\n" "${glob_ldap}"

    printf "\n%s\n" "Junk Settings"
    printf "%s\n\n" "-------------"

    spam_level=$(user_pref "${servstr}.spamLevel")
    if [ "x0" = "x${spam_level}" ]
    then
	enable_junk="No"
    else
	enable_junk="Yes"
    fi

    move_spam=$(user_pref "${servstr}.moveOnSpam")

    junk_dir=$(user_pref "${servstr}.spamActionTargetFolder" | \
		    sed -e "s|^.*\[Gmail\]/\(.*\$\)|\1 on ${ac_name}|" | \
		    sed -e "s|^imap://.*|\"Junk\" folder on: ${ac_name}|")

    purge_spam=$(user_pref "${servstr}.purgeSpam")

    printf "%-26s %s\n" "Enable jumk mail controls for this account:" \
	   "${enable_junk}"

    if [ "Yes" = "${enable_junk}" ]
    then
	printf "Do not automatically mark as junk if sender is in:\n"
	printf "  Collected Addresses:          No*\n"
	printf "  jeremypeterbennett@gmail.com: Yes*\n"
	printf "  Personal Address Book:        Yes*\n"
	printf "Trust junk mail headers set by SpamAssassin*\n"

	if [ "xtrue" = "x${move_spam}" ]
	then
	    printf "Move new junk messages to:\n"
	    printf "  %s\n" "${junk_dir}"
	fi
	if [ "xtrue" = "x${purge_spam}" ]
	then
	    printf "Automatically delete junk mail older than 14* days\n"
	fi
    fi

    printf "\nSynchronisation & Storage\n"
    printf "%s\n\n" "-------------------------"

    printf "Keep messages for this account on this computer*\n"
    printf "Synchornise all messages locally regardless of age*\n"
    printf "Don't delete any messages*\n"
    printf "Always keep starred messages*\n"

    printf "\nDKIM Verifier Options\n"
    printf "%s\n\n" "---------------------"

    printf "Verify DKIM signatures: Use default value*\n"
    printf "Read Authentication-Results header: Use default value*\n"

    printf "\nSigning/Encryption Options...\n"
    printf "%s\n\n" "-----------------------------"

    enable_pgp=$(user_pref "${idstr}.enablePgp")
    case "${enable_pgp}"
    in
	true) enable_pgp="Yes"
	      ;;
	*) enable_pgp="No"
	   ;;
    esac

    pgp_key="Use email address of this entity to identify OpenPGP key*"

    pgp_encrypt="No*"
    pgp_sign="Yes*"
    pgp_mime="No*"
    ppg_sign_non_enc_after_default="No*"
    ppg_sign_enc_after_default="No*"
    pgp_encrypt_on_save="Yes*"
    pgp_pref="Prefer Enigmail (OpenPGP)*"

    printf "Enable Open PGP support (Enigmail for this identity: %s\n" \
	   "${enable_pgp}"

    if [ "Yes" = "$enable_pgp" ]
    then
	printf "%s\n" "${gpg_key}"
	printf "Message Composition Default Options\n"
	printf "  %-24s %s\n" "Encrypt messages by default" "${pgp_encrypt}"
	printf "  %-24s %s\n" "Sign messages by default" "${pgp_sign}"
	printf "  %-24s %s\n" "Use PGP/MIME by default" "${pgp_mime}"
	printf "After application of defaults and rules\n"
	printf "  %-24s %s\n" "Sign non-encrypted messages" \
	       "${ppg_sign_non_enc_after_default}"
	printf "  %-24s %s\n" "Sign encrypted messages" \
	       "${ppg_sign_enc_after_default}"
	printf "  %-24s %s\n" "Encrypt draft messages on saving" \
	       "${pgp_encrypt_on_save}"
	printf "If both Enigmail and S/MIME are possible:\n"
	printf "  %s\n" "${pgp_pref}"
    fi

    printf "\nReturn Receipts\n"
    printf "%s\n\n" "---------------"

    printf "Use my global return receipt preferences for this account\n"

    printf "\nSecurity\n"
    printf "%s\n\n" "--------"

}


# Handle one account.

# If neither server nor identity is found, that is failure. We only do
# detailed processing if both are found.

# @param[in] $1  Number of the account
# @return  0 on success (which if only one of identies or server is found may
#           mean no further processing) and 1 on failure.

do_account () {
    n=$1
    res=0

    if ! ids=$(user_pref "mail.account.account${n}.identities")
    then
	res=$((res + 1))
    fi

    if ! server=$(user_pref "mail.account.account${n}.server")
    then
	res=$((res + 1))
    fi

    case ${res}
    in
	2) return 1;			# Neither found => failure
	   ;;

	1) return 0;			# One found => success and all done
	   ;;

	*)
	   ;;
    esac

    dump_data "${ids}" "${server}"

    return 0
}


# Handle one SMTP server.

# We look for a server name to determine if it exists

# @param[in] $1  Number of the SMTP server
# @return  0 on success and 1 on failure.

do_smtp () {
    smtp="mail.smtpserver.smtp${1}"

    if ! server_name=$(user_pref "${smtp}.hostname")
    then
	return 1
    fi

    desc=$(user_pref "${smtp}.description")
    port=$(user_pref "${smtp}.port")
    security=$(user_pref "${smtp}.try_ssl")
    case "${security}"
    in
	3) security="SSL/TLS"
	   ;;
	2) security="STARTTLS"
	   ;;
	*) security="None"
	   ;;
    esac

    auth_meth=$(user_pref "${smtp}.authMethod")
    case "${auth_method}"
    in
	3) auth_meth="Normal Password"
	   ;;
	*) auth_meth="OAuth2"
	   ;;
    esac

    user_name=$(user_pref "${smtp}.username")

    printf "\n"
    printf "%-22s %s\n" "Description:"           "${desc}"
    printf "%-22s %s\n" "Server Name:"           "${server_name}"
    printf "%-22s %s\n" "Port:"                  "${port}"
    printf "%-22s %s\n" "Connection security:"   "${security}"
    printf "%-22s %s\n" "Authentication method:" "${auth_meth}"
    printf "%-22s %s\n" "User Name:"             "${user_name}"

    return 0
}


# Report general preferences

do_prefs () {

    printf "\n%s\n" "General"
    printf "%s\n\n" "-------"

    res=$(yes_no_pref "datareporting.sessions.current.clean" "false" "No")
    printf "%-35s: %s\n" "Show start page in message area" "${res}"

    if [ "${res}" = "Yes" ]
    then
	if res=$(user_pref "mailnews.start_page.url")
	then
	    printf "  Location: %s\n" ${res}
	else
	    printf "  Location: https://live.mozillamessaging.com/thunderbird/start?locale=en-GB&version=%s&os=Linux&buildid=%s\n" \
		$(user_pref "mailnews.start_page_override.mstone") \
		$(user_pref "toolkit.telemetry.previousBuildID")
	fi
    fi

    printf "%-35s %s\n" "Default search engine" "Google*"
    printf "When new messages arrive:\n"
    printf "  %-33s %s\n" "Show an alert:" \
	   $(yes_no_pref "mail.biff.show_alert" "true" "Yes")
    printf "  %-33s %s\n" "Play a sound:" \
	   $(yes_no_pref "mail.biff.play_sound" "true" "Yes")
    printf "  %-33s %s\n" "Show in the messaging menu:" \
	   $(yes_no_pref "mail.chat.show_desktop_notifications" "true" "Yes")
    printf "    %-31s\n" "For messages in all folders*"
    printf "%-35s\n" "Default system sound for new mail*"

    printf "\n%s\n" "Display/Formatting"
    printf "%s\n\n" "------------------"

    font=$(default_pref "font.name.sans-serif.x-western" "sans-serif")
    printf "%-15s %s\n" "Default font" "${font}"
    printf "  %-13s %s\n" "Size:" \
	   $(default_pref "font.size.variable.x-western" "22")

    printf "When displaying quoted messages:\n"
    case $(default_pref "mail.quoted_style" "0")
    in
	1)  res="Bold"
	    ;;
	2)  res="Italic"
	    ;;
	3)  res="Bold Italic"
	    ;;
	*)  res="Regular"
	    ;;
    esac
    printf "  %-13s %s\n" "Style" "${res}"
    case $(default_pref "mail.quoted_size" "0")
    in
	1)  res="Larger"
	    ;;
	2)  res="Smaller"
	    ;;
	*)  res="Regular"
	    ;;
    esac
    printf "  %-13s %s\n" "Size" "${res}"
    printf "  %-13s %s\n" "Color" "$(default_pref "mail.citation_color" "Black")"

    printf "\n%s\n" "Display/Tags"
    printf "%s\n\n" "------------"

    n=1

    while tag=$(user_pref "mailnews.tags.\$label${n}.tag")
    do
	color=$(default_pref "mailnews.tags.\$label${n}.color" "Black")
	printf "%-8s: %s\n" "${color}" "${tag}"
	n=$(( n + 1 ))
    done

    printf "\n%s\n" "Display/Advanced"
    printf "%s\n\n" "----------------"

    res=$(yes_no_pref "mailnews.mark_message_read.auto" "true" "Yes")
    printf "%s %s\n" "Automatically mark messages as read:" "${res}"

    if [ "${res}" = "Yes" ]
    then
	res=$(default_pref "mailnews.mark_message_read.delay" "false")

	if [ "${res}" = "false" ]
	then
	    printf "  Immediately on display\n"
	else
	    printf "  After displaying for %s seconds\n" \
		   $(default_pref "mailnews.mark_message_read.delay.interval" \
				  "5")
	fi
    fi

    case $(default_pref "mail.openMessageBehavior" "2")
    in
	0) res="A new message window"
	   ;;
	1) res="An existing message window"
	   ;;
	*) res="A new tab"
	   ;;
    esac

    printf "Open messages in:\n"
    printf "  %s\n" "${res}"

    printf "%s %s\n" "Show only display name for people in my address book:" \
	   $(yes_no_pref "mail.showCondensedAddresses" "true" "Yes")

    printf "\n%s\n" "Composition/General"
    printf "%s\n\n" "-------------------"

    case $(default_pref "mail.forward_message_mode" "1")
    in
	0) res="As Attachment"
	   ;;
	*) res="Inline"
	   ;;
    esac
    printf "%s %s\n" "Forward messages: " "${res}"
    printf "  %s %s\n" "add extension to file name:" \
	   $(yes_no_pref "mail.forward_add_extension" "true" "Yes")
    printf "%s %s\n" "AutoSave:" $(yes_no_pref "mail.compose.autosave" true \
					       "Yes")
    printf "  every %s minutes\n" \
	   $(default_pref "mail.compose.autosaveinterval" "5")
    printf "%s %s\n" "Confirm when using keyboard shortcut to send message:" \
	   $(yes_no_pref "mail.warn_on_send_accel_key" "true" "Yes")
    printf "%s %s\n" "Check for missing attachments" \
	   $(yes_no_pref "mail.compose.attachment_reminder" "true" "Yes")
    val=$(default_pref "msgcompose.font_face" "Variable Width")
    case "${val}"
    in
	"Variable Width")
	    res="Variable Width"
	    ;;
	"tt")
	    res="Fixed Width"
	    ;;
	"Helvetica, Arial, sans-serif")
	    res="Helvetica,Arial"
	    ;;
	"Times New Roman, Times, serif")
	    res="Times"
	    ;;
	"Courier New, Courier, monospace")
	    res="Courier"
	    ;;
	*)
	    res="${val}"
	    ;;
    esac
    printf "%s %s\n" "Font: " "${res}"
    val=$(default_pref "msgcompose.font_size" "medium")
    case ${val}
    in
	x-small) res="Tiny"
		 ;;
	small) res="Small"
		 ;;
	large) res="Large"
		 ;;
	x-large) res="Extra Large"
		 ;;
	xx-large) res="Huge"
		 ;;
	*) res="Medium"
		 ;;
    esac
    printf "  %-17s %s\n" "size:" "${res}"
    printf "  %-17s %s\n" "text color:" \
	   $(default_pref "msgcompose.text_color" "Black")
    printf "  %-17s %s\n" "background color:" \
	   $(default_pref "msgcompose.background_color" "White")

    printf "\n%s\n" "Composition/Addressing"
    printf "%s\n\n" "----------------------"

    printf "Autocomplete addresses from:\n"
    printf "  %s %s\n" "Local Address Books:" \
	   $(yes_no_pref mail.enable_autocomplete "true" "Yes")
    printf "  %s %s\n" "Directory Server:   " \
	   $(yes_no_pref ldap_2.autoComplete.useDirectory "false" "Yes")
    res=$(yes_no_pref "mail.collect_email_address_outgoing" "false" "No")
    printf "%s %s\n" "Automatically add outgoing email addresses: " "${res}"
    if [ "${res}" = "Yes" ]
    then
	res=$(default_pref "mail.collect_addressbook" "Collected Addresses")
	printf "  to my: %s\n" "${res}"
    fi

    printf "\n%s\n" "Composition/Spelling"
    printf "%s\n\n" "--------------------"

    printf "%-31s %s\n" "Check spelling before sending:" \
	   $(yes_no_pref "mail.SpellCheckBeforeSend" "false" "Yes")
    printf "%-31s %s\n" "Enable spell check as you type:" \
	   $(yes_no_pref "mail.spellcheck.inline" "true" "Yes")
    case $(default_pref "spellchecker.dictionary" "en-US")
    in
	en-GB)
	    res="English (United Kingdom)"
	    ;;
	*)
	    res="English (United States)"
	    ;;
    esac
    printf "%s %s\n" "Language:" "${res}"

    printf "\n%s\n" "Chat"
    printf "%s\n\n" "----"

    case $(default_pref "messenger.startup.action" "1")
    in
	0) res="Connect my chat automatically"
	   ;;
	*) res="Keep by chat accounts offline"
	   ;;
    esac
    printf "%s%s\n" "When Thunderbird starts:" "${res}"
    res=$(yes_no_pref "messenger.status.reportIdle" "true" "Yes")
    printf "%s %s\n" "Let my contacts know I am idle:" "${res}"
    if [ "${res}" = "Yes" ]
    then
	res=$(default_pref "messenger.status.timeBeforeIdle" "300")
	res=$(( res / 60 ))
	printf "  after %s minutes of inactivity\n" "${res}"
	if [ $(default_pref "messenger.status.awayWhenIdle" "true") = "true" ]
	then
	    res=$(user_pref "messenger.status.defaultIdleAwayMessage")
	    printf "  and set my status to Away with this status message\n"
	    printf "    %s\n" "${res}"
	fi
    fi
    printf "%s %s\n" "Send typing notifications in conversations:" \
	   $(yes_no_pref "purple.conversations.im.send_typing" "true" "Yes")
    res=$(yes_no_pref "mail.chat.show_desktop_notifications" "true" "Yes")
    printf "When messages directed at you arrive:\n"
    printf "%-22s %s\n" "  Show a notification:" "${res}"
    if [ "${res}" = "Yes" ]
    then
	case $(default_pref "mail.chat.notification_info", 0)
	in
	    1) res="with sender's name only"
	       ;;
	    2) res="without any info"
	       ;;
	    *) res="with sender's name and message preview"
	       ;;
	esac
	printf "    %s\n" "${res}"
    fi
    res=$(yes_no_pref "mail.chat.play_sound" "true" "Yes")
    printf "%-22s %s\n" "  Play a sound:" "${res}"
    if [ "${res}" = "Yes" ]
    then
	case $(default_pref "mail.chat.play_sound.type" "0")
	in
	    1) printf "    Use the following sound file\n"
	       res=$(user_pref "mail.chat.play_sound.url" | \
			 sed -e 's|file://||')
	       printf "      %s\n" "${res}"
	       ;;
	    *) printf "    Default system sound for new mail\n"
	       ;;
	esac
    fi

    printf "\n%s\n" "Privacy"
    printf "%s\n\n" "-------"

    case $(default_pref "extensions.enigmail.juniorMode" "0")
    in
	1) res="Force using S/MIME and Enigmail"
	   ;;
	2) res="Force using p=p (Pretty Easy Privacy"
	   ;;
	*) res="Automatically decide if Junior Mode should be used"
	   ;;
    esac

    printf "Enigmail Junior Mode\n"
    printf "  %s\n" "${res}"
    printf "%s %s\n" "Allow remote content in messages: " \
	   $(yes_no_pref "mailnews.message_display.disable_remote_image" \
			 "true" "No")

    printf "%s %s\n" "Remember web sites and linkes I've visited" \
	   $(yes_no_pref "places.history.enabled" false "No")
    case $(default_pref "network.cookie.cookieBehavior" "0")
    in
	1) acc="Yes"
	   when="Never"
	   ;;
	2) acc="No"
	   ;;
	3) acc="Yes"
	   when="From visited"
	   ;;
	*) acc="Yes"
	   when="Always"
	   ;;
    esac
    printf "%s %s\n" "Accept cookies from sites:" "${acc}"
    if [ "${acc}" = "Yes" ]
    then
	printf "  %s %s\n" "Accept third party cookies: " "${when}"
	case $(default_pref "network.cookie.lifetimePolicy" "0")
	in
	    1) res="ask me every time"
	       ;;
	    2) res="I close Thunderbird"
	       ;;
	    *) res="they expire"
	       ;;
	esac
	printf "%s %s\n" "  Keep until:" "${res}"
    fi

    printf "%s %s\n" "Tell sites that I do not want to be tracked:" \
	   $(yes_no_pref "privacy.donottrackheader.enabled" "false" "Yes")

    printf "\n%s\n" "Security/Junk"
    printf "%s\n\n" "-------------"

    if [ $(default_pref "mail.spam.manualMark" false) = "true" ]
    then
	printf "When I mark messages as junk:\n"
	case $(default_pref "mail.spam.manualMarkMode" "0")
	in
	    1) res="Delete them"
	       ;;
	    *) res="Move them to the account's \"junk\" folder"
	       ;;
	esac
	printf "  %s\n" "${res}"
    fi
    printf "%-45s %s\n" "Mark messages determined to be junk as read:" \
	   $(yes_no_pref "mail.spam.markAsReadOnSpam" "false" "Yes")
    printf "%-45s %s\n" "Enable adaptive junk filter logging:" \
	   $(yes_no_pref "mail.spam.logging.enabled" "false" "Yes")

    printf "\n%s\n" "Security/Email Scams"
    printf "%s\n\n" "--------------------"

    printf "%s %s\n" "Tell me if the message I'm reading is a suspected scam:" \
	   $(yes_no_pref "mail.phishing.detection.enabled" "true" "Yes")

    printf "\n%s\n" "Security/Anti-Virus"
    printf "%s\n\n" "-------------------"

    printf "%s %s\n" \
	   "Allow anti-virus clients to quarantine individual messages:" \
	   $(yes_no_pref "mailnews.downloadToTempFile" "false" "Yes")

    printf "\n%s\n" "Security/Passwords"
    printf "%s\n\n" "------------------"

    printf "Use a master password: Yes*\n"

    printf "\n%s\n" "Attachments/Incoming"
    printf "%s\n\n" "--------------------"

    if [ "true" = $(default_pref "browser.download.useDownloadDir" "false") ]
    then
	printf "Save files to %s\n" \
	       $(default_pref "browser.download.dir" "Desktop" |
		     sed -e "s|${HOME}/Desktop|Desktop|")
    else
	printf "Always ask me where to save files\n"
    fi

    printf "\n%s\n" "Attachments/Outgoing"
    printf "%s\n\n" "--------------------"

    if [ "true" = $(default_pref "mail.compose.big_attachments.notify" "true") ]
    then
	res=$(default_pref "mail.compose.big_attachments.threshold_kb" "5120")
	res=$(( res / 1024 ))
	printf "Offer to share for files larger than %s MB\n" "${res}"
    fi

    printf "\n%s\n" "Advanced/General"
    printf "%s\n\n" "----------------"

    printf "%s %s\n" "When sending messages, always request a return receipt" \
	   $(yes_no_pref "mail.receipt.request_return_receipt_on" "false" "Yes")
    printf "When a receipt arrives:\n"
    case $(default_pref "mail.incorporate.return_receipt" "0")
    in
	1) res="Move it to my \"Sent\" folder"
	   ;;
	*) res="Leave it in my inbox"
	   ;;
    esac
    printf "  %s\n" "${res}"

    printf "When I receive a request for a return receipt:\n"
    if [ $(default_pref "mail.mdn.report.enabled" "true") = "false" ]
    then
	printf "  Never send a return receipt\n"
    else
	printf "  Allow return receipts for some messages\n"
	case $(default_pref "mail.mdn.report.not_in_to_cc" "2")
	in
	    0) res="Never send"
	       ;;
	    1) res="Always send"
	       ;;
	    *) res="Ask me"
	       ;;
	esac
	printf "    %-42s %s\n" "If I'm not in the To or Cc of the message:" \
	       "${res}"
	case $(default_pref "mail.mdn.report.outside_domain" "2")
	in
	    0) res="Never send"
	       ;;
	    1) res="Always send"
	       ;;
	    *) res="Ask me"
	       ;;
	esac
	printf "    %-42s %s\n" "If the sender is outside my domain:" "${res}"
	case $(default_pref "mail.mdn.report.other" "2")
	in
	    0) res="Never send"
	       ;;
	    1) res="Always send"
	       ;;
	    *) res="Ask me"
	       ;;
	esac
	printf "    %-42s %s\n" "In all other cases:" "${res}"
    fi

    printf "%-21s %s\n" "Use autoscrolling:" \
	   $(yes_no_pref "general.autoScroll" "false" "Yes")
    printf "%-21s %s\n" "Use smooth scrolling:" \
	   $(yes_no_pref "general.smoothScroll" "true" "Yes")
    printf "%s %s\n" "Always check to see if Thunderbird is the default:" \
	   $(yes_no_pref "mail.shell.checkDefaultClient" "true" "Yes")
    printf "%s %s\n" "Enable Global Search and Indexer:" \
	   $(yes_no_pref "mailnews.database.global.indexer.enabled" "true" "Yes")
    printf "Message Store Type for new accounts: File per folder (mbox)*\n"
    printf "%s %s\n" "Use hardware acceleration when available:" \
	   $(yes_no_pref "layers.acceleration.disabled" "true" "No")

    printf "\n%s\n" "Advanced/Data Choices"
    printf "%s\n\n" "---------------------"

    printf "Enable Crash Reporter: Yes*\n"

    printf "\n%s\n" "Advanced/Network and Disc Space"
    printf "%s\n\n" "-------------------------------"

    printf "Use system proxy settings*\n"

    res=$(user_pref "browser.cache.disk.capacity")
    res=$(( res / 1024 ))
    printf "Use up to %s MB of space for the cache\n" "${res}"

    printf "\n%s\n" "Advanced/Certificates"
    printf "%s\n\n" "---------------------"

    printf "When a server requests my personal certificate:\n"
    printf "Select one automatically\n"

}


# Report extensions

do_extensions () {
    n=0

    printf "%s\n" "Extensions"
    printf "%s\n\n" "----------"

    while true
    do
	ext=$(jq ".addons[${n}].defaultLocale.name" ${exts} | \
		  sed -e 's/^"//' -e 's/"$//')

	if [ "${ext}" = "null" ]
	then
	    break
	fi

	ver=$(jq ".addons[${n}].version" ${exts} | \
		  sed -e 's/^"//' -e 's/"$//')
	printf "%s %s\n" "${ext}" "${ver}"

	n=$(( n + 1 ))
    done
}



# Main program: sort out args

if [ $# -ne 1 ]
then
    echo "Usage: $0 <config-dir>"
    exit 1
fi

if [ ! -d $1 ]
then
    echo "Config dir $1 not found"
    exit 1
fi

confdir=$(cd $1; pwd)
prefs="$confdir/prefs.js"
exts="$confdir/extensions.json"

# Go through each account in turn. We stop when neither identities nor server
# can be found.

n=1

while do_account $n
do
    n=$(( n + 1 ))
done

# Do the outgoing SMTP servers

n=1

printf "\n==============================================================\n\n"

while do_smtp $n
do
    n=$(( n + 1 ))
done

# Preferences

printf "\n==============================================================\n\n"
do_prefs

# Extensions

printf "\n==============================================================\n\n"
do_extensions

exit 0
