#!/usr/bin/env bash

# ============================================================ #
# ================== <EPNTROSINT Parameters > ================== #
# ============================================================ #
# Path to directory containing the PENTROSINT executable script.
readonly PENTPath=$(dirname $(readlink -f "$0"))

# Path to directory containing the PENTROSINT library (scripts).
readonly PENTLibPath="$PENTPath/lib"

# Path to the temp. directory available to PENTROSINT & subscripts.
readonly PENTWorkspacePath="/tmp/fluxspace"
readonly PENTIPTablesBackup="$PENTPath/iptables-rules"

# Path to PENTROSINT's preferences file, to be loaded afterward.
readonly PENTPreferencesFile="$PENTPath/preferences/preferences.conf"

# Constants denoting the reference noise floor & ceiling levels.
# These are used by the the wireless network scanner visualizer.
readonly PENTNoiseFloor=-90
readonly PENTNoiseCeiling=-60

readonly PENTVersion=6
readonly PENTRevision=9

# Declare window ration bigger = smaller windows
PENTWindowRatio=4

# Allow to skip dependencies if required, not recommended
PENTSkipDependencies=1

# Check if there are any missing dependencies
PENTMissingDependencies=0

# Allow to use 5ghz support
PENTEnable5GHZ=0

# ============================================================ #
# ================= < Script Sanity Checks > ================= #
# ============================================================ #
if [ $EUID -ne 0 ]; then # Super User Check
  echo -e "\\033[31mAborted, please execute the script as root.\\033[0m"; exit 1
fi

# ===================== < XTerm Checks > ===================== #
# TODO: Run the checks below only if we're not using tmux.
if [ ! "${DISPLAY:-}" ]; then # Assure display is available.
  echo -e "\\033[31mAborted, X (graphical) session unavailable.\\033[0m"; exit 2
fi

if ! hash xdpyinfo 2>/dev/null; then # Assure display probe.
  echo -e "\\033[31mAborted, xdpyinfo is unavailable.\\033[0m"; exit 3
fi

if ! xdpyinfo &>/dev/null; then # Assure display info available.
  echo -e "\\033[31mAborted, xterm test session failed.\\033[0m"; exit 4
fi

# ================ < Parameter Parser Check > ================ #
getopt --test > /dev/null # Assure enhanced getopt (returns 4).
if [ $? -ne 4 ]; then
  echo "\\033[31mAborted, enhanced getopt isn't available.\\033[0m"; exit 5
fi

# =============== < Working Directory Check > ================ #
if ! mkdir -p "$PENTWorkspacePath" &> /dev/null; then
  echo "\\033[31mAborted, can't generate a workspace directory.\\033[0m"; exit 6
fi

# Once sanity check is passed, we can start to load everything.

# ============================================================ #
# =================== < Library Includes > =================== #
# ============================================================ #
source "$PENTLibPath/installer/InstallerUtils.sh"
source "$PENTLibPath/InterfaceUtils.sh"
source "$PENTLibPath/SandboxUtils.sh"
source "$PENTLibPath/FormatUtils.sh"
source "$PENTLibPath/ColorUtils.sh"
source "$PENTLibPath/IOUtils.sh"
source "$PENTLibPath/HashUtils.sh"
source "$PENTLibPath/HelpUtils.sh"

# NOTE: These are configured after arguments are loaded (later).

# ============================================================ #
# =================== < Parse Parameters > =================== #
# ============================================================ #
if ! PENTCLIArguments=$(
    getopt --options="vdk5rinmthb:e:c:l:a:r" \
      --longoptions="debug,version,killer,5ghz,installer,reloader,help,airmon-ng,multiplexer,target,test,auto,bssid:,essid:,channel:,language:,attack:,ratio,skip-dependencies" \
      --name="PENT V$PENTVersion.$PENTRevision" -- "$@"
  ); then
  echo -e "${CRed}Aborted$CClr, parameter error detected..."; exit 5
fi

AttackCLIArguments=${PENTCLIArguments##* -- }
readonly PENTCLIArguments=${PENTCLIArguments%%-- *}
if [ "$AttackCLIArguments" = "$PENTCLIArguments" ]; then
  AttackCLIArguments=""
fi


# ============================================================ #
# ================== < Load Configurables > ================== #
# ============================================================ #

# ============= < Argument Loaded Configurables > ============ #
eval set -- "$PENTCLIArguments" # Set environment parameters.

#[ "$1" != "--" ] && readonly PENTAuto=1 # Auto-mode if using CLI.
while [ "$1" != "" ] && [ "$1" != "--" ]; do
  case "$1" in
    -v|--version) echo "PENT V$PENTVersion.$PENTRevision"; exit;;
    -h|--help) pent_help; exit;;
    -d|--debug) readonly PENTDebug=1;;
    -k|--killer) readonly PENTWIKillProcesses=1;;
    -5|--5ghz) PENTEnable5GHZ=1;;
    -r|--reloader) readonly PENTWIReloadDriver=1;;
    -n|--airmon-ng) readonly PENTAirmonNG=1;;
    -m|--multiplexer) readonly PENTTMux=1;;
    -b|--bssid) PentTargetMAC=$2; shift;;
    -e|--essid) PentTargetSSID=$2;
      # TODO: Rearrange declarations to have routines available for use here.
      PentTargetSSIDClean=$(echo "$PentTargetSSID" | sed -r 's/( |\/|\.|\~|\\)+/_/g'); shift;;
    -c|--channel) PentTargetChannel=$2; shift;;
    -l|--language) PentLanguage=$2; shift;;
    -a|--attack) PentAttack=$2; shift;;
    -i|--install) PENTSkipDependencies=0; shift;;
    --ratio) PENTWindowRatio=$2; shift;;
    --auto) readonly PENTAuto=1;;
    --skip-dependencies) readonly PENTSkipDependencies=1;;
  esac
  shift # Shift new parameters
done

shift # Remove "--" to prepare for attacks to read parameters.
# Executable arguments are handled after subroutine definition.

# =================== < User Preferences > =================== #
# Load user-defined preferences if there's an executable script.
# If no script exists, prepare one for the user to store config.
# WARNING: Preferences file must assure no redeclared constants.
if [ -x "$PENTPreferencesFile" ]; then
  source "$PENTPreferencesFile"
else
  echo '#!/usr/bin/env bash' > "$PENTPreferencesFile"
  chmod u+x "$PENTPreferencesFile"
fi

# ================ < Configurable Constants > ================ #
if [ "$PENTAuto" != "1" ]; then # If defined, assure 1.
  readonly PENTAuto=${PENTAuto:+1}
fi

if [ "$PENTDebug" != "1" ]; then # If defined, assure 1.
  readonly PENTDebug=${PENTDebug:+1}
fi

if [ "$PENTAirmonNG" != "1" ]; then # If defined, assure 1.
  readonly PENTAirmonNG=${PENTAirmonNG:+1}
fi

if [ "$PENTWIKillProcesses" != "1" ]; then # If defined, assure 1.
  readonly PENTWIKillProcesses=${PENTWIKillProcesses:+1}
fi

if [ "$PENTWIReloadDriver" != "1" ]; then # If defined, assure 1.
  readonly PENTWIReloadDriver=${PENTWIReloadDriver:+1}
fi

# PENTDebug [Normal Mode "" / Developer Mode 1]
if [ $PENTDebug ]; then
  :> /tmp/pent.debug.log
  readonly PENTOutputDevice="/tmp/pent.debug.log"
  readonly PENTHoldXterm="-hold"
else
  readonly PENTOutputDevice=/dev/null
  readonly PENTHoldXterm=""
fi

# ================ < Configurable Variables > ================ #
readonly PENTPromptDefault="$CRed[${CSBlu}PENTROSINT$CSYel@$CSWht$HOSTNAME$CClr$CRed]-[$CSYel~$CClr$CRed]$CClr "
PENTPrompt=$PENTPromptDefault

readonly PENTVLineDefault="$CRed[$CSYel*$CClr$CRed]$CClr"
PENTVLine=$PENTVLineDefault

# ================== < Library Parameters > ================== #
readonly InterfaceUtilsOutputDevice="$PENTOutputDevice"

readonly SandboxWorkspacePath="$PENTWorkspacePath"
readonly SandboxOutputDevice="$PENTOutputDevice"

readonly InstallerUtilsWorkspacePath="$PENTWorkspacePath"
readonly InstallerUtilsOutputDevice="$PENTOutputDevice"
readonly InstallerUtilsNoticeMark="$PENTVLine"

readonly PackageManagerLog="$InstallerUtilsWorkspacePath/package_manager.log"

declare  IOUtilsHeader="pent_header"
readonly IOUtilsQueryMark="$PENTVLine"
readonly IOUtilsPrompt="$PENTPrompt"

readonly HashOutputDevice="$PENTOutputDevice"

# ============================================================ #
# =================== < Default Language > =================== #
# ============================================================ #
# Set by default in case pent is aborted before setting one.
source "$PENTPath/language/en.sh"

# ============================================================ #
# ================== < Startup & Shutdown > ================== #
# ============================================================ #
pent_startup() {
  if [ "$PENTDebug" ]; then return 1; fi

  # Make sure that we save the iptable files
  iptables-save >"$PENTIPTablesBackup"
  local banner=()

  format_center_literals \
    	"___       __________________              _____" 
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  	" __ |     / /__(_)__  __/__(_)_______________  /_"
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  	" __ | /| / /__  /__  /_ __  /___  __ \  __ \  __/"
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  	"__ |/ |/ / _  / _  __/ _  / __  /_/ / /_/ / /_"  
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  	"____/|__/  /_/  /_/    /_/  _  .___/\____/\__/"  
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  	"            /_/"
  banner+=("$FormatCenterLiterals")   
  format_center_literals \
  "   __         __  __    ___ __  __  __     ___ "
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  " |__ _  _   |__)|_ |\ | | |__)/  \(_ ||\ | | "
  banner+=("$FormatCenterLiterals")
  format_center_literals \
  "|| (_)|||  |   |__| \| | | \ \__/__)|| \| |"
  banner+=("$FormatCenterLiterals")

  clear

  if [ "$PENTAuto" ]; then echo -e "$CBlu"; else echo -e "$CRed"; fi

  for line in "${banner[@]}"; do
    echo "$line"; sleep 0.05
  done

  echo # Do not remove.  
  sleep 2
  format_center_literals "${CGrn}Checking Dependencies"
  echo -e "$FormatCenterLiterals"
  echo # Do not remove.

  local requiredCLITools=(
    "aircrack-ng" "bc" "awk:awk|gawk|mawk"
    "curl" "cowpatty" "dhcpd:isc-dhcp-server|dhcp" "7zr:p7zip" "hostapd" "lighttpd"
    "iwconfig:wireless-tools" "macchanger" "mdk4" "dsniff" "mdk3" "nmap" "openssl"
    "php-cgi" "xterm" "rfkill" "unzip" "route:net-tools"
    "fuser:psmisc" "killall:psmisc"
  )

    while ! installer_utils_check_dependencies requiredCLITools[@]; do
        if ! installer_utils_run_dependencies InstallerUtilsCheckDependencies[@]; then
            echo
            echo -e "${CRed}Dependency installation failed!$CClr"
            echo    "Press enter to retry, ctrl+c to exit..."
            read -r bullshit
        fi
    done
    if [ $PENTMissingDependencies -eq 1 ]  && [ $PENTSkipDependencies -eq 1 ];then
        echo -e "\n\n"
        format_center_literals "[ ${CSRed}Missing dependencies: try to install using ./pent.sh -i${CClr} ]"
        echo -e "$FormatCenterLiterals"; sleep 3

        exit 7
    fi

  echo -e "\\n\\n" # This echo is for spacing
}

pent_shutdown() {
  if [ $PENTDebug ]; then return 1; fi

  # Show the header if the subroutine has already been loaded.
  if type -t pent_header &> /dev/null; then
    pent_header
  fi

  echo -e "$CWht[$CRed-$CWht]$CRed $PENTCleanupAndClosingNotice$CClr"

  # Get running processes we might have to kill before exiting.
  local processes
  readarray processes < <(ps -A)

  # Currently, pent is only responsible for killing airodump-ng, since
  # pent explicitly uses it to scan for candidate target access points.
  # NOTICE: Processes started by subscripts, such as an attack script,
  # MUST BE TERMINATED BY THAT SCRIPT in the subscript's abort handler.
  local -r targets=("airodump-ng")

  local targetID # Program identifier/title
  for targetID in "${targets[@]}"; do
    # Get PIDs of all programs matching targetPID
    local targetPID
    targetPID=$(
      echo "${processes[@]}" | awk '$4~/'"$targetID"'/{print $1}'
    )
    if [ ! "$targetPID" ]; then continue; fi
    echo -e "$CWht[$CRed-$CWht] `io_dynamic_output $PENTKillingProcessNotice`"
    kill -s SIGKILL $targetPID &> $PENTOutputDevice
  done
  kill -s SIGKILL $authService &> $PENTOutputDevice

  # Assure changes are reverted if installer was activated.
  if [ "$PackageManagerCLT" ]; then
    echo -e "$CWht[$CRed-$CWht] "$(
      io_dynamic_output "$PENTRestoringPackageManagerNotice"
    )"$CClr"
    # Notice: The package manager has already been restored at this point.
    # InstallerUtils assures the manager is restored after running operations.
  fi

  # If allocated interfaces exist, deallocate them now.
  if [ ${#PentInterfaces[@]} -gt 0 ]; then
    local interface
    for interface in "${!PentInterfaces[@]}"; do
      # Only deallocate pent or airmon-ng created interfaces.
      if [[ "$interface" == "flux"* || "$interface" == *"mon"* || "$interface" == "prism"* ]]; then
        pent_deallocate_interface $interface
      fi
    done
  fi

  echo -e "$CWht[$CRed-$CWht] $PENTDisablingCleaningIPTablesNotice$CClr"
  if [ -f "$PENTIPTablesBackup" ]; then
    iptables-restore <"$PENTIPTablesBackup" \
      &> $PENTOutputDevice
  else
    iptables --flush
    iptables --table nat --flush
    iptables --delete-chain
    iptables --table nat --delete-chain
  fi

  echo -e "$CWht[$CRed-$CWht] $PENTRestoringTputNotice$CClr"
  tput cnorm

  if [ ! $PENTDebug ]; then
    echo -e "$CWht[$CRed-$CWht] $PENTDeletingFilesNotice$CClr"
    sandbox_remove_workfile "$PENTWorkspacePath/*"
  fi

  if [ $PENTWIKillProcesses ]; then
    echo -e "$CWht[$CRed-$CWht] $PENTRestartingNetworkManagerNotice$CClr"

    # TODO: Add support for other network managers (wpa_supplicant?).
    if [ ! -x "$(command -v systemctl)" ]; then
        if [ -x "$(command -v service)" ];then
        service network-manager restart &> $PENTOutputDevice &
        service networkmanager restart &> $PENTOutputDevice &
        service networking restart &> $PENTOutputDevice &
      fi
    else
      systemctl restart network-manager.service &> $PENTOutputDevice &
    fi
  fi

  echo -e "$CWht[$CGrn+$CWht] $CGrn$PENTCleanupSuccessNotice$CClr"
  echo -e "$CWht[$CGrn+$CWht] $CGry$PENTThanksSupportersNotice$CClr"

  sleep 3

  clear

  exit 0
}


# ============================================================ #
# ================== < Helper Subroutines > ================== #
# ============================================================ #
# The following will kill the parent proces & all its children.
pent_kill_lineage() {
  if [ ${#@} -lt 1 ]; then return -1; fi

  if [ ! -z "$2" ]; then
    local -r options=$1
    local match=$2
  else
    local -r options=""
    local match=$1
  fi

  # Check if the match isn't a number, but a regular expression.
  # The following might
  if ! [[ "$match" =~ ^[0-9]+$ ]]; then
    match=$(pgrep -f $match 2> $PENTOutputDevice)
  fi

  # Check if we've got something to kill, abort otherwise.
  if [ -z "$match" ]; then return -2; fi

  kill $options $(pgrep -P $match 2> $PENTOutputDevice) \
    &> $PENTOutputDevice
  kill $options $match &> $PENTOutputDevice
}


# ============================================================ #
# ================= < Handler Subroutines > ================== #
# ============================================================ #
# Delete log only in Normal Mode !
pent_conditional_clear() {
  # Clear iff we're not in debug mode
  if [ ! $PENTDebug ]; then clear; fi
}

pent_conditional_bail() {
  echo ${1:-"Something went wrong, whoops! (report this)"}
  sleep 5
  if [ ! $PENTDebug ]; then
    pent_handle_exit
    return 1
  fi
  echo "Press any key to continue execution..."
  read -r bullshit
}

# ERROR Report only in Developer Mode
if [ $PENTDebug ]; then
  pent_error_report() {
    echo "Exception caught @ line #$1"
  }

  trap 'pent_error_report $LINENO' ERR
fi

pent_handle_abort_attack() {
  if [ $(type -t stop_attack) ]; then
    stop_attack &> $PENTOutputDevice
    unprep_attack &> $PENTOutputDevice
  else
    echo "Attack undefined, can't stop anything..." > $PENTOutputDevice
  fi

  pent_target_tracker_stop
}

# In case of abort signal, abort any attacks currently running.
trap pent_handle_abort_attack SIGABRT

pent_handle_exit() {
  pent_handle_abort_attack
  pent_shutdown
  exit 1
}

# In case of unexpected termination, run pent_shutdown.
trap pent_handle_exit SIGINT SIGHUP


pent_handle_target_change() {
  echo "Target change signal received!" > $PENTOutputDevice

  local targetInfo
  readarray -t targetInfo < <(more "$PENTWorkspacePath/target_info.txt")

  PentTargetMAC=${targetInfo[0]}
  PentTargetSSID=${targetInfo[1]}
  PentTargetChannel=${targetInfo[2]}

  PentTargetSSIDClean=$(pent_target_normalize_SSID)

  if ! stop_attack; then
    pent_conditional_bail "Target tracker failed to stop attack."
  fi

  if ! unprep_attack; then
    pent_conditional_bail "Target tracker failed to unprep attack."
  fi

  if ! load_attack "$PENTPath/attacks/$PentAttack/attack.conf"; then
    pent_conditional_bail "Target tracker failed to load attack."
  fi

  if ! prep_attack; then
    pent_conditional_bail "Target tracker failed to prep attack."
  fi

  if ! pent_run_attack; then
    pent_conditional_bail "Target tracker failed to start attack."
  fi
}

# If target monitoring enabled, act on changes.
trap pent_handle_target_change SIGALRM


# ============================================================ #
# =============== < Resolution & Positioning > =============== #
# ============================================================ #
pent_set_resolution() { # Windows + Resolution

  # Get dimensions
  # Verify this works on Kali before commiting.
  # shopt -s checkwinsize; (:;:)
  # SCREEN_SIZE_X="$LINES"
  # SCREEN_SIZE_Y="$COLUMNS"

  SCREEN_SIZE=$(xdpyinfo | grep dimension | awk '{print $4}' | tr -d "(")
  SCREEN_SIZE_X=$(printf '%.*f\n' 0 $(echo $SCREEN_SIZE | sed -e s'/x/ /'g | awk '{print $1}'))
  SCREEN_SIZE_Y=$(printf '%.*f\n' 0 $(echo $SCREEN_SIZE | sed -e s'/x/ /'g | awk '{print $2}'))

  # Calculate proportional windows
  if hash bc ;then
    PROPOTION=$(echo $(awk "BEGIN {print $SCREEN_SIZE_X/$SCREEN_SIZE_Y}")/1 | bc)
    NEW_SCREEN_SIZE_X=$(echo $(awk "BEGIN {print $SCREEN_SIZE_X/$PENTWindowRatio}")/1 | bc)
    NEW_SCREEN_SIZE_Y=$(echo $(awk "BEGIN {print $SCREEN_SIZE_Y/$PENTWindowRatio}")/1 | bc)

    NEW_SCREEN_SIZE_BIG_X=$(echo $(awk "BEGIN {print 1.5*$SCREEN_SIZE_X/$PENTWindowRatio}")/1 | bc)
    NEW_SCREEN_SIZE_BIG_Y=$(echo $(awk "BEGIN {print 1.5*$SCREEN_SIZE_Y/$PENTWindowRatio}")/1 | bc)

    SCREEN_SIZE_MID_X=$(echo $(($SCREEN_SIZE_X + ($SCREEN_SIZE_X - 2 * $NEW_SCREEN_SIZE_X) / 2)))
    SCREEN_SIZE_MID_Y=$(echo $(($SCREEN_SIZE_Y + ($SCREEN_SIZE_Y - 2 * $NEW_SCREEN_SIZE_Y) / 2)))

    # Upper windows
    TOPLEFT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+0+0"
    TOPRIGHT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y-0+0"
    TOP="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+$SCREEN_SIZE_MID_X+0"

    # Lower windows
    BOTTOMLEFT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+0-0"
    BOTTOMRIGHT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y-0-0"
    BOTTOM="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+$SCREEN_SIZE_MID_X-0"

    # Y mid
    LEFT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y+0-$SCREEN_SIZE_MID_Y"
    RIGHT="-geometry $NEW_SCREEN_SIZE_Xx$NEW_SCREEN_SIZE_Y-0+$SCREEN_SIZE_MID_Y"

    # Big
    TOPLEFTBIG="-geometry $NEW_SCREEN_SIZE_BIG_Xx$NEW_SCREEN_SIZE_BIG_Y+0+0"
    TOPRIGHTBIG="-geometry $NEW_SCREEN_SIZE_BIG_Xx$NEW_SCREEN_SIZE_BIG_Y-0+0"
  fi
}


# ============================================================ #
# ================= < Sequencing Framework > ================= #
# ============================================================ #
# The following lists some problems with the framework's design.
# The list below is a list of DESIGN FLAWS, not framework bugs.
# * Sequenced undo instructions' return value is being ignored.
# * A global is generated for every new namespace being used.
# * It uses eval too much, but it's bash, so that's not so bad.
# TODO: Try to fix this or come up with a better alternative.
declare -rA PENTUndoable=( \
  ["set"]="unset" \
  ["prep"]="unprep" \
  ["run"]="halt" \
  ["start"]="stop" \
)

# Yes, I know, the identifiers are fucking ugly. If only we had
# some type of mangling with bash identifiers, that'd be great.
pent_do() {
  if [ ${#@} -lt 2 ]; then return -1; fi

  local -r __pent_do__namespace=$1
  local -r __pent_do__identifier=$2

  # Notice, the instruction will be adde to the Do Log
  # regardless of whether it succeeded or failed to execute.
  eval FXDLog_$__pent_do__namespace+=\("$__pent_do__identifier"\)
  eval ${__pent_do__namespace}_$__pent_do__identifier "${@:3}"
  return $?
}

pent_undo() {
  if [ ${#@} -ne 1 ]; then return -1; fi

  local -r __pent_undo__namespace=$1

  # Removed read-only due to local constant shadowing bug.
  # I've reported the bug, we can add it when fixed.
  eval local __pent_undo__history=\("\${FXDLog_$__pent_undo__namespace[@]}"\)

  eval echo \$\{FXDLog_$__pent_undo__namespace[@]\} \
    > $PENTOutputDevice

  local __pent_undo__i
  for (( __pent_undo__i=${#__pent_undo__history[@]}; \
    __pent_undo__i > 0; __pent_undo__i-- )); do
    local __pent_undo__instruction=${__pent_undo__history[__pent_undo__i-1]}
    local __pent_undo__command=${__pent_undo__instruction%%_*}
    local __pent_undo__identifier=${__pent_undo__instruction#*_}

    echo "Do ${PENTUndoable["$__pent_undo__command"]}_$__pent_undo__identifier" \
      > $PENTOutputDevice
    if eval ${__pent_undo__namespace}_${PENTUndoable["$__pent_undo__command"]}_$__pent_undo__identifier; then
      echo "Undo-chain succeded." > $PENTOutputDevice
      eval FXDLog_$__pent_undo__namespace=\("${__pent_undo__history[@]::$__pent_undo__i}"\)
      eval echo History\: \$\{FXDLog_$__pent_undo__namespace[@]\} \
        > $PENTOutputDevice
      return 0
    fi
  done

  return -2 # The undo-chain failed.
}

pent_done() {
  if [ ${#@} -ne 1 ]; then return -1; fi

  local -r __pent_done__namespace=$1

  eval "PentDone=\${FXDLog_$__pent_done__namespace[-1]}"

  if [ ! "$PentDone" ]; then return 1; fi
}

pent_done_reset() {
  if [ ${#@} -ne 1 ]; then return -1; fi

  local -r __pent_done_reset__namespace=$1

  eval FXDLog_$__pent_done_reset__namespace=\(\)
}

pent_do_sequence() {
  if [ ${#@} -ne 2 ]; then return 1; fi

  # TODO: Implement an alternative, better method of doing
  # what this subroutine does, maybe using for-loop itePENTWindowRation.
  # The for-loop implementation must support the subroutines
  # defined above, including updating the namespace tracker.

  local -r __pent_do_sequence__namespace=$1

  # Removed read-only due to local constant shadowing bug.
  # I've reported the bug, we can add it when fixed.
  local __pent_do_sequence__sequence=("${!2}")

  if [ ${#__pent_do_sequence__sequence[@]} -eq 0 ]; then
    return -2
  fi

  local -A __pent_do_sequence__index=()

  local i
  for i in $(seq 0 $((${#__pent_do_sequence__sequence[@]} - 1))); do
    __pent_do_sequence__index["${__pent_do_sequence__sequence[i]}"]=$i
  done

  # Start sequence with the first instruction available.
  local __pent_do_sequence__instructionIndex=0
  local __pent_do_sequence__instruction=${__pent_do_sequence__sequence[0]}
  while [ "$__pent_do_sequence__instruction" ]; do
    if ! pent_do $__pent_do_sequence__namespace $__pent_do_sequence__instruction; then
      if ! pent_undo $__pent_do_sequence__namespace; then
        return -2
      fi

      # Synchronize the current instruction's index by checking last.
      if ! pent_done $__pent_do_sequence__namespace; then
        return -3;
      fi

      __pent_do_sequence__instructionIndex=${__pent_do_sequence__index["$PentDone"]}

      if [ ! "$__pent_do_sequence__instructionIndex" ]; then
        return -4
      fi
    else
      let __pent_do_sequence__instructionIndex++
    fi

    __pent_do_sequence__instruction=${__pent_do_sequence__sequence[$__pent_do_sequence__instructionIndex]}
    echo "Running next: $__pent_do_sequence__instruction" \
      > $PENTOutputDevice
  done
}


# ============================================================ #
# ================= < Load All Subroutines > ================= #
# ============================================================ #
pent_header() {
  format_apply_autosize "[%*s]\n"
  local verticalBorder=$FormatApplyAutosize

  format_apply_autosize "%*s${CSRed} 
__        ___  __ _             _     _____                      ____  _____ _   _ _____ ____   ___  ____ ___ _   _ _____ 
\ \      / (_)/ _(_)_ __   ___ | |_  |  ___| __ ___  _ __ ___   |  _ \| ____| \ | |_   _|  _ \ / _ \/ ___|_ _| \ | |_   _|
 \ \ /\ / /| | |_| | '_ \ / _ \| __| | |_ | '__/ _ \| '_   _ \  | |_) |  _| |  \| | | | | |_) | | | \___ \| ||  \| | | |  
  \ V  V / | |  _| | |_) | (_) | |_  |  _|| | | (_) | | | | | | |  __/| |___| |\  | | | |  _ <| |_| |___) | || |\  | | |  
   \_/\_/  |_|_| |_| .__/ \___/ \__| |_|  |_|  \___/|_| |_| |_| |_|   |_____|_| \_| |_| |_| \_\ ___/|____/___|_| \_| |_|  
                   |_|                                                                                                     %*s$CSBlu\n"
  local headerTextFormat="$FormatApplyAutosize"

  pent_conditional_clear


  printf "$headerTextFormat" "" ""

  echo
}

# ======================= < Language > ======================= #
pent_unset_language() {
  PentLanguage=""

  if [ "$PENTPreferencesFile" ]; then
    sed -i.backup "/PentLanguage=.\+/ d" "$PENTPreferencesFile"
  fi
}

pent_set_language() {
  if [ ! "$PentLanguage" ]; then
    # Get all languages available.
    local languageCodes
    readarray -t languageCodes < <(ls -1 language | sed -E 's/\.sh//')
	
    local languages
    readarray -t languages < <(
      head -n 3 language/*.sh |
      grep -E "^# native: " |
      sed -E 's/# \w+: //'
    )

    io_query_format_fields "$PENTVLine Select your language" \
      "\t$CRed[$CSYel%d$CClr$CRed]$CClr %s / %s\n" \
      languageCodes[@] languages[@]

    PentLanguage=${IOQueryFormatFields[0]}

    echo # Do not remove.
  fi

  # Check if all language files are present for the selected language.
  find -type d -name language | while read language_dir; do
    if [ ! -e "$language_dir/${PentLanguage}.sh" ]; then
      echo -e "$PENTVLine ${CYel}Warning${CClr}, missing language file:"
      echo -e "\t$language_dir/${PentLanguage}.sh"
      return 1
    fi
  done

  if [ $? -eq 1 ]; then # If a file is missing, fall back to english.
    echo -e "\n\n$PENTVLine Falling back to English..."; sleep 5
    PentLanguage="en"
  fi

  source "$PENTPath/language/$PentLanguage.sh"

  if [ "$PENTPreferencesFile" ]; then
    if more $PENTPreferencesFile | \
      grep -q "PentLanguage=.\+" &> /dev/null; then
      sed -r "s/PentLanguage=.+/PentLanguage=$PentLanguage/g" \
      -i.backup "$PENTPreferencesFile"
    else
      echo "PentLanguage=$PentLanguage" >> "$PENTPreferencesFile"
    fi
  fi
}

# ====================== < Interfaces > ====================== #
declare -A PentInterfaces=() # Global interfaces' registry.

pent_deallocate_interface() { # Release interfaces
  if [ ! "$1" ] || ! interface_is_real $1; then return 1; fi

  local -r oldIdentifier=$1
  local -r newIdentifier=${PentInterfaces[$oldIdentifier]}

  # Assure the interface is in the allocation table.
  if [ ! "$newIdentifier" ]; then return 2; fi

  local interfaceIdentifier=$newIdentifier
  echo -e "$CWht[$CSRed-$CWht] "$(
    io_dynamic_output "$PENTDeallocatingInterfaceNotice"
  )"$CClr"

  if interface_is_wireless $oldIdentifier; then
    # If interface was allocated by airmon-ng, deallocate with it.
    if [[ "$oldIdentifier" == *"mon"* || "$oldIdentifier" == "prism"* ]]; then
      if ! airmon-ng stop $oldIdentifier &> $PENTOutputDevice; then
        return 4
      fi
    else
      # Attempt deactivating monitor mode on the interface.
      if ! interface_set_mode $oldIdentifier managed; then
        return 3
      fi

      # Attempt to restore the original interface identifier.
      if ! interface_reidentify "$oldIdentifier" "$newIdentifier"; then
        return 5
      fi
    fi
  fi

  # Once successfully renamed, remove from allocation table.
  unset PentInterfaces[$oldIdentifier]
  unset PentInterfaces[$newIdentifier]
}

# Parameters: <interface_identifier>
# ------------------------------------------------------------ #
# Return 1: No interface identifier was passed.
# Return 2: Interface identifier given points to no interface.
# Return 3: Unable to determine interface's driver.
# Return 4: Pent failed to reidentify interface.
# Return 5: Interface allocation failed (identifier missing).
pent_allocate_interface() { # Reserve interfaces
  if [ ! "$1" ]; then return 1; fi

  local -r identifier=$1

  # If the interface is already in allocation table, we're done.
  if [ "${PentInterfaces[$identifier]+x}" ]; then
    return 0
  fi

  if ! interface_is_real $identifier; then return 2; fi


  local interfaceIdentifier=$identifier
  echo -e "$CWht[$CSGrn+$CWht] "$(
    io_dynamic_output "$PENTAllocatingInterfaceNotice"
  )"$CClr"


  if interface_is_wireless $identifier; then
    # Unblock wireless interfaces to make them available.
    echo -e "$PENTVLine $PENTUnblockingWINotice"
    rfkill unblock all &> $PENTOutputDevice

    if [ "$PENTWIReloadDriver" ]; then
      # Get selected interface's driver details/info-descriptor.
      echo -e "$PENTVLine $PENTGatheringWIInfoNotice"

      if ! interface_driver "$identifier"; then
        echo -e "$PENTVLine$CRed $PENTUnknownWIDriverError"
        sleep 3
        return 3
      fi

      # Notice: This local is function-scoped, not block-scoped.
      local -r driver="$InterfaceDriver"

      # Unload the driver module from the kernel.
      rmmod -f $driver &> $PENTOutputDevice

      # Wait while interface becomes unavailable.
      echo -e "$PENTVLine "$(
        io_dynamic_output $PENTUnloadingWIDriverNotice
      )
      while interface_physical "$identifier"; do
        sleep 1
      done
    fi

    if [ "$PENTWIKillProcesses" ]; then
      # Get list of potentially troublesome programs.
      echo -e "$PENTVLine $PENTFindingConflictingProcessesNotice"

      # Kill potentially troublesome programs.
      echo -e "$PENTVLine $PENTKillingConflictingProcessesNotice"

      # TODO: Make the loop below airmon-ng independent.
      # Maybe replace it with a list of network-managers?
      # WARNING: Version differences could break code below.
      for program in "$(airmon-ng check | awk 'NR>6{print $2}')"; do
        killall "$program" &> $PENTOutputDevice
      done
    fi

    if [ "$PENTWIReloadDriver" ]; then
      # Reload the driver module into the kernel.
      modprobe "$driver" &> $PENTOutputDevice

      # Wait while interface becomes available.
      echo -e "$PENTVLine "$(
        io_dynamic_output $PENTLoadingWIDriverNotice
      )
      while ! interface_physical "$identifier"; do
        sleep 1
      done
    fi

    # Set wireless flag to prevent having to re-query.
    local -r allocatingWirelessInterface=1
  fi

  # If we're using the interface library, reidentify now.
  # If usuing airmon-ng, let airmon-ng rename the interface.
  if [ ! $PENTAirmonNG ]; then
    echo -e "$PENTVLine $PENTReidentifyingInterface"

    # Prevent interface-snatching by renaming the interface.
    if [ $allocatingWirelessInterface ]; then
      # Get next wireless interface to add to PentInterfaces global.
      pent_next_assignable_interface fluxwl
    else
      # Get next ethernet interface to add to PentInterfaces global.
      pent_next_assignable_interface fluxet
    fi

    interface_reidentify $identifier $PentNextAssignableInterface

    if [ $? -ne 0 ]; then # If reidentifying failed, abort immediately.
      return 4
    fi
  fi

  if [ $allocatingWirelessInterface ]; then
    # Activate wireless interface monitor mode and save identifier.
    echo -e "$PENTVLine $PENTStartingWIMonitorNotice"

    # TODO: Consider the airmon-ng flag is set, monitor mode is
    # already enabled on the interface being allocated, and the
    # interface identifier is something non-airmon-ng standard.
    # The interface could already be in use by something else.
    # Snatching or crashing interface issues could occur.

    # NOTICE: Conditionals below populate newIdentifier on success.
    if [ $PENTAirmonNG ]; then
      local -r newIdentifier=$(
        airmon-ng start $identifier |
        grep "monitor .* enabled" |
        grep -oP "wl[a-zA-Z0-9]+mon|mon[0-9]+|prism[0-9]+"
      )
    else
      # Attempt activating monitor mode on the interface.
      if interface_set_mode $PentNextAssignableInterface monitor; then
        # Register the new identifier upon consecutive successes.
        local -r newIdentifier=$PentNextAssignableInterface
      else
        # If monitor-mode switch fails, undo rename and abort.
        interface_reidentify $PentNextAssignableInterface $identifier
      fi
    fi
  fi

  # On failure to allocate the interface, we've got to abort.
  # Notice: If the interface was already in monitor mode and
  # airmon-ng is activated, WE didn't allocate the interface.
  if [ ! "$newIdentifier" -o "$newIdentifier" = "$oldIdentifier" ]; then
    echo -e "$PENTVLine $PENTInterfaceAllocationFailedError"
    sleep 3
    return 5
  fi

  # Register identifiers to allocation hash table.
  PentInterfaces[$newIdentifier]=$identifier
  PentInterfaces[$identifier]=$newIdentifier

  echo -e "$PENTVLine $PENTInterfaceAllocatedNotice"
  sleep 3

  # Notice: Interfaces are accessed with their original identifier
  # as the key for the global PentInterfaces hash/map/dictionary.
}

# Parameters: <interface_prefix>
# Description: Prints next available assignable interface name.
# ------------------------------------------------------------ #
pent_next_assignable_interface() {
  # Find next available interface by checking global.
  local -r prefix=$1
  local index=0
  while [ "${PentInterfaces[$prefix$index]}" ]; do
    let index++
  done
  PentNextAssignableInterface="$prefix$index"
}

# Parameters: <interfaces:lambda> [<query>]
# Note: The interfaces lambda must print an interface per line.
# ------------------------------------------------------------ #
# Return -1: Go back
# Return  1: Missing interfaces lambda identifier (not passed).
pent_get_interface() {
  if ! type -t "$1" &> /dev/null; then return 1; fi

  if [ "$2" ]; then
    local -r interfaceQuery="$2"
  else
    local -r interfaceQuery=$PENTInterfaceQuery
  fi

  while true; do
    local candidateInterfaces
    readarray -t candidateInterfaces < <($1)
    local interfacesAvailable=()
    local interfacesAvailableInfo=()
    local interfacesAvailableColor=()
    local interfacesAvailableState=()

    # Gather information from all available interfaces.
    local candidateInterface
    for candidateInterface in "${candidateInterfaces[@]}"; do
      if [ ! "$candidateInterface" ]; then
        local skipOption=1
        continue
      fi

      interface_chipset "$candidateInterface"
      interfacesAvailableInfo+=("$InterfaceChipset")

      # If it has already been allocated, we can use it at will.
      local candidateInterfaceAlt=${PentInterfaces["$candidateInterface"]}
      if [ "$candidateInterfaceAlt" ]; then
        interfacesAvailable+=("$candidateInterfaceAlt")

        interfacesAvailableColor+=("$CGrn")
        interfacesAvailableState+=("[*]")
      else
        interfacesAvailable+=("$candidateInterface")

        interface_state "$candidateInterface"

        if [ "$InterfaceState" = "up" ]; then
          interfacesAvailableColor+=("$CPrp")
          interfacesAvailableState+=("[-]")
        else
          interfacesAvailableColor+=("$CClr")
          interfacesAvailableState+=("[+]")
        fi
      fi
    done

    # If only one interface exists and it's not unavailable, choose it.
    if [ "${#interfacesAvailable[@]}" -eq 1 -a \
      "${interfacesAvailableState[0]}" != "[-]" -a \
      "$skipOption" == "" ]; then PentInterfaceSelected="${interfacesAvailable[0]}"
      PentInterfaceSelectedState="${interfacesAvailableState[0]}"
      PentInterfaceSelectedInfo="${interfacesAvailableInfo[0]}"
      break
    else
      if [ $skipOption ]; then
        interfacesAvailable+=("$PENTGeneralSkipOption")
        interfacesAvailableColor+=("$CClr")
      fi

      interfacesAvailable+=(
        "$PENTGeneralRepeatOption"
        "$PENTGeneralBackOption"
      )

      interfacesAvailableColor+=(
        "$CClr"
        "$CClr"
      )

      format_apply_autosize \
        "$CRed[$CSYel%1d$CClr$CRed]%b %-8b %3s$CClr %-*.*s\n"

      io_query_format_fields \
        "$PENTVLine $interfaceQuery" "$FormatApplyAutosize" \
        interfacesAvailableColor[@] interfacesAvailable[@] \
        interfacesAvailableState[@] interfacesAvailableInfo[@]

      echo

      case "${IOQueryFormatFields[1]}" in
        "$PENTGeneralSkipOption")
          PentInterfaceSelected=""
          PentInterfaceSelectedState=""
          PentInterfaceSelectedInfo=""
          return 0;;
        "$PENTGeneralRepeatOption") continue;;
        "$PENTGeneralBackOption") return -1;;
        *)
          PentInterfaceSelected="${IOQueryFormatFields[1]}"
          PentInterfaceSelectedState="${IOQueryFormatFields[2]}"
          PentInterfaceSelectedInfo="${IOQueryFormatFields[3]}"
          break;;
      esac
    fi
  done
}


# ============== < Pent Target Subroutines > ============== #
# Parameters: interface [ channel(s) [ band(s) ] ]
# ------------------------------------------------------------ #
# Return 1: Missing monitor interface.
# Return 2: Xterm failed to start airmon-ng.
# Return 3: Invalid capture file was generated.
# Return 4: No candidates were detected.
pent_target_get_candidates() {
  # Assure a valid wireless interface for scanning was given.
  if [ ! "$1" ] || ! interface_is_wireless "$1"; then return 1; fi

  echo -e "$PENTVLine $PENTStartingScannerNotice"
  echo -e "$PENTVLine $PENTStartingScannerTip"

  # Assure all previous scan results have been cleared.
  sandbox_remove_workfile "$PENTWorkspacePath/dump*"

  #if [ "$PENTAuto" ]; then
  #  sleep 30 && killall xterm &
  #fi

  # Begin scanner and output all results to "dump-01.csv."
if ! xterm -title "$PENTScannerHeader" $TOPLEFTBIG \
    -bg "#000000" -fg "#FFFFFF" -e \
    "airodump-ng -Mat WPA "${2:+"--channel $2"}" "${3:+"--band $3"}" -w \"$PENTWorkspacePath/dump\" $1" 2> $PENTOutputDevice; then
    echo -e "$PENTVLine$CRed $PENTGeneralXTermFailureError"
    sleep 5
    return 2
fi

  # Sanity check the capture files generated by the scanner.
  # If the file doesn't exist, or if it's empty, abort immediately.
  if [ ! -f "$PENTWorkspacePath/dump-01.csv" -o \
    ! -s "$PENTWorkspacePath/dump-01.csv" ]; then
    sandbox_remove_workfile "$PENTWorkspacePath/dump*"
    return 3
  fi

  # Syntheize scan opePENTWindowRation results from output file "dump-01.csv."
  echo -e "$PENTVLine $PENTPreparingScannerResultsNotice"
  # WARNING: The code below may break with different version of airmon-ng.
  # The times matching operator "{n}" isn't supported by mawk (alias awk).
  # readarray PENTTargetCandidates < <(
  #   gawk -F, 'NF==15 && $1~/([A-F0-9]{2}:){5}[A-F0-9]{2}/ {print $0}'
  #   $PENTWorkspacePath/dump-01.csv
  # )
  # readarray PENTTargetCandidatesClients < <(
  #   gawk -F, 'NF==7 && $1~/([A-F0-9]{2}:){5}[A-F0-9]{2}/ {print $0}'
  #   $PENTWorkspacePath/dump-01.csv
  # )
  local -r matchMAC="([A-F0-9][A-F0-9]:)+[A-F0-9][A-F0-9]"
  readarray PentTargetCandidates < <(
    awk -F, "NF==15 && length(\$1)==17 && \$1~/$matchMAC/ {print \$0}" \
    "$PENTWorkspacePath/dump-01.csv"
  )
  readarray PentTargetCandidatesClients < <(
    awk -F, "NF==7 && length(\$1)==17 && \$1~/$matchMAC/ {print \$0}" \
    "$PENTWorkspacePath/dump-01.csv"
  )

  # Cleanup the workspace to prevent potential bugs/conflicts.
  sandbox_remove_workfile "$PENTWorkspacePath/dump*"

  if [ ${#PentTargetCandidates[@]} -eq 0 ]; then
    echo -e "$PENTVLine $PENTScannerDetectedNothingNotice"
    sleep 3
    return 4
  fi
}


pent_get_target() {
  # Assure a valid wireless interface for scanning was given.
  if [ ! "$1" ] || ! interface_is_wireless "$1"; then return 1; fi

  local -r interface=$1

  local choices=( \
    "$PENTScannerChannelOptionAll (2.4GHz)" \
    "$PENTScannerChannelOptionAll (5GHz)" \
    "$PENTScannerChannelOptionAll (2.4GHz & 5Ghz)" \
    "$PENTScannerChannelOptionSpecific" "$PENTGeneralBackOption"
  )

  io_query_choice "$PENTScannerChannelQuery" choices[@]

  echo

  case "$IOQueryChoice" in
    "$PENTScannerChannelOptionAll (2.4GHz)")
      pent_target_get_candidates $interface "" "bg";;

    "$PENTScannerChannelOptionAll (5GHz)")
      pent_target_get_candidates $interface "" "a";;

    "$PENTScannerChannelOptionAll (2.4GHz & 5Ghz)")
      pent_target_get_candidates $interface "" "abg";;

    "$PENTScannerChannelOptionSpecific")
      pent_header

      echo -e "$PENTVLine $PENTScannerChannelQuery"
      echo
      echo -e "     $PENTScannerChannelSingleTip ${CBlu}6$CClr               "
      echo -e "     $PENTScannerChannelMiltipleTip ${CBlu}1-5$CClr             "
      echo -e "     $PENTScannerChannelMiltipleTip ${CBlu}1,2,5-7,11$CClr      "
      echo
      echo -ne "$PENTPrompt"

      local channels
      read channels

      echo

      pent_target_get_candidates $interface $channels;;

    "$PENTGeneralBackOption")
      return -1;;
  esac

  # Abort if errors occured while searching for candidates.
  if [ $? -ne 0 ]; then return 2; fi

  local candidatesMAC=()
  local candidatesClientsCount=()
  local candidatesChannel=()
  local candidatesSecurity=()
  local candidatesSignal=()
  local candidatesPower=()
  local candidatesESSID=()
  local candidatesColor=()

  # Gather information from all the candidates detected.
  # TODO: Clean up this for loop using a cleaner algorithm.
  # Maybe try using array appending & [-1] for last elements.
  for candidateAPInfo in "${PentTargetCandidates[@]}"; do
    # Strip candidate info from any extraneous spaces after commas.
    candidateAPInfo=$(echo "$candidateAPInfo" | sed -r "s/,\s*/,/g")

    local i=${#candidatesMAC[@]}

    candidatesMAC[i]=$(echo "$candidateAPInfo" | cut -d , -f 1)
    candidatesClientsCount[i]=$(
      echo "${PentTargetCandidatesClients[@]}" |
      grep -c "${candidatesMAC[i]}"
    )
    candidatesChannel[i]=$(echo "$candidateAPInfo" | cut -d , -f 4)
    candidatesSecurity[i]=$(echo "$candidateAPInfo" | cut -d , -f 6)
    candidatesPower[i]=$(echo "$candidateAPInfo" | cut -d , -f 9)
    candidatesColor[i]=$(
      [ ${candidatesClientsCount[i]} -gt 0 ] && echo $CGrn || echo $CClr
    )

    # Parse any non-ascii characters by letting bash handle them.
    # Escape all single quotes in ESSID and let bash's $'...' handle it.
    local sanitizedESSID=$(
      echo "${candidateAPInfo//\'/\\\'}" | cut -d , -f 14
    )
    candidatesESSID[i]=$(eval "echo \$'$sanitizedESSID'")

    local power=${candidatesPower[i]}
    if [ $power -eq -1 ]; then
      # airodump-ng's man page says -1 means unsupported value.
      candidatesQuality[i]="??"
    elif [ $power -le $PENTNoiseFloor ]; then
      candidatesQuality[i]=0
    elif [ $power -gt $PENTNoiseCeiling ]; then
      candidatesQuality[i]=100
    else
      # Bash doesn't support floating point division, work around it...
      # Q = ((P - F) / (C - F)); Q-quality, P-power, F-floor, C-Ceiling.
      candidatesQuality[i]=$(( \
        (${candidatesPower[i]} * 10 - $PENTNoiseFloor * 10) / \
        (($PENTNoiseCeiling - $PENTNoiseFloor) / 10) \
      ))
    fi
  done

  format_center_literals "WIFI LIST"
  local -r headerTitle="$FormatCenterLiterals\n\n"

  format_apply_autosize "$CRed[$CSYel ** $CClr$CRed]$CClr %-*.*s %4s %3s %3s %2s %-8.8s %18s\n"
  local -r headerFields=$(
    printf "$FormatApplyAutosize" \
      "ESSID" "QLTY" "PWR" "STA" "CH" "SECURITY" "BSSID"
  )

  format_apply_autosize "$CRed[$CSYel%03d$CClr$CRed]%b %-*.*s %3s%% %3s %3d %2s %-8.8s %18s\n"
  io_query_format_fields "$headerTitle$headerFields" \
   "$FormatApplyAutosize" \
    candidatesColor[@] \
    candidatesESSID[@] \
    candidatesQuality[@] \
    candidatesPower[@] \
    candidatesClientsCount[@] \
    candidatesChannel[@] \
    candidatesSecurity[@] \
    candidatesMAC[@]

  echo

  PentTargetMAC=${IOQueryFormatFields[7]}
  PentTargetSSID=${IOQueryFormatFields[1]}
  PentTargetChannel=${IOQueryFormatFields[5]}

  PentTargetEncryption=${IOQueryFormatFields[6]}

  PentTargetMakerID=${PentTargetMAC:0:8}
  PentTargetMaker=$(
    macchanger -l |
    grep ${PentTargetMakerID,,} 2> $PENTOutputDevice |
    cut -d ' ' -f 5-
  )

  PentTargetSSIDClean=$(pent_target_normalize_SSID)

  # We'll change a single hex digit from the target AP's MAC address.
  # This new MAC address will be used as the rogue AP's MAC address.
  local -r rogueMACHex=$(printf %02X $((0x${PentTargetMAC:13:1} + 1)))
  PentTargetRogueMAC="${PentTargetMAC::13}${rogueMACHex:1:1}${PentTargetMAC:14:4}"
}

pent_target_normalize_SSID() {
  # Sanitize network ESSID to make it safe for manipulation.
  # Notice: Why remove these? Some smartass might decide to name their
  # network "; rm -rf / ;". If the string isn't sanitized accidentally
  # shit'll hit the fan and we'll have an extremly distressed user.
  # Replacing ' ', '/', '.', '~', '\' with '_'
  echo "$PentTargetSSID" | sed -r 's/( |\/|\.|\~|\\)+/_/g'
}

pent_target_show() {
  format_apply_autosize "%*s$CBlu%7s$CClr: %-32s%*s\n"

  local colorlessFormat="$FormatApplyAutosize"
  local colorfullFormat=$(
    echo "$colorlessFormat" | sed -r 's/%-32s/%-32b/g'
  )

  printf "$colorlessFormat" "" "ESSID" "\"${PentTargetSSID:-[N/A]}\" / ${PentTargetEncryption:-[N/A]}" ""
  printf "$colorlessFormat" "" "Channel" " ${PentTargetChannel:-[N/A]}" ""
  printf "$colorfullFormat" "" "BSSID" " ${PentTargetMAC:-[N/A]} ($CYel${PentTargetMaker:-[N/A]}$CClr)" ""

  echo
}

pent_target_tracker_daemon() {
  if [ ! "$1" ]; then return 1; fi # Assure we've got pent's PID.

  readonly pentPID=$1
  readonly monitorTimeout=10 # In seconds.
  readonly capturePath="$PENTWorkspacePath/tracker_capture"

  if [ \
    -z "$PentTargetMAC" -o \
    -z "$PentTargetSSID" -o \
    -z "$PentTargetChannel" ]; then
    return 2 # If we're missing target information, we can't track properly.
  fi

  while true; do
    echo "[T-Tracker] Captor listening for $monitorTimeout seconds..."
    timeout --preserve-status $monitorTimeout airodump-ng -aw "$capturePath" \
      -d "$PentTargetMAC" $PentTargetTrackerInterface &> /dev/null
    local error=$? # Catch the returned status error code.

    if [ $error -ne 0 ]; then # If any error was encountered, abort!
      echo -e "[T-Tracker] ${CRed}Error:$CClr Operation aborted (code: $error)!"
      break
    fi

    local targetInfo=$(head -n 3 "$capturePath-01.csv" | tail -n 1)
    sandbox_remove_workfile "$capturePath-*"

    local targetChannel=$(
      echo "$targetInfo" | awk -F, '{gsub(/ /, "", $4); print $4}'
    )

    echo "[T-Tracker] $targetInfo"

    if [ "$targetChannel" -ne "$PentTargetChannel" ]; then
      echo "[T-Tracker] Target channel change detected!"
      PentTargetChannel=$targetChannel
      break
    fi

    # NOTE: We might also want to check for SSID changes here, assuming the only
    # thing that remains constant is the MAC address. The problem with that is
    # that airodump-ng has some serious problems with unicode, apparently.
    # Try feeding it an access point with Chinese characters and check the .csv.
  done

  # Save/overwrite the new target information to the workspace for retrival.
  echo "$PentTargetMAC" > "$PENTWorkspacePath/target_info.txt"
  echo "$PentTargetSSID" >> "$PENTWorkspacePath/target_info.txt"
  echo "$PentTargetChannel" >> "$PENTWorkspacePath/target_info.txt"

  # NOTICE: Using different signals for different things is a BAD idea.
  # We should use a single signal, SIGINT, to handle different situations.
  kill -s SIGALRM $pentPID # Signal pent a change was detected.

  sandbox_remove_workfile "$capturePath-*"
}

pent_target_tracker_stop() {
  if [ ! "$PentTargetTrackerDaemonPID" ]; then return 1; fi
  kill -s SIGABRT $PentTargetTrackerDaemonPID &> /dev/null
  PentTargetTrackerDaemonPID=""
}

pent_target_tracker_start() {
  if [ ! "$PentTargetTrackerInterface" ]; then return 1; fi

  pent_target_tracker_daemon $$ &> "$PENTOutputDevice" &
  PentTargetTrackerDaemonPID=$!
}

pent_target_unset_tracker() {
  if [ ! "$PentTargetTrackerInterface" ]; then return 1; fi

  PentTargetTrackerInterface=""
}

pent_target_set_tracker() {
  if [ "$PentTargetTrackerInterface" ]; then
    echo "Tracker interface already set, skipping." > $PENTOutputDevice
    return 0
  fi

  # Check if attack provides tracking interfaces, get & set one.
  if ! type -t attack_tracking_interfaces &> /dev/null; then
    echo "Tracker DOES NOT have interfaces available!" > $PENTOutputDevice
    return 1
  fi

  if [ "$PentTargetTrackerInterface" == "" ]; then
    echo "Running get interface (tracker)." > $PENTOutputDevice
    local -r interfaceQuery=$PENTTargetTrackerInterfaceQuery
    local -r interfaceQueryTip=$PENTTargetTrackerInterfaceQueryTip
    local -r interfaceQueryTip2=$PENTTargetTrackerInterfaceQueryTip2
    if ! pent_get_interface attack_tracking_interfaces \
      "$interfaceQuery\n$PENTVLine $interfaceQueryTip\n$PENTVLine $interfaceQueryTip2"; then
      echo "Failed to get tracker interface!" > $PENTOutputDevice
      return 2
    fi
    local selectedInterface=$PentInterfaceSelected
  else
    # Assume user passed one via the command line and move on.
    # If none was given we'll take care of that case below.
    local selectedInterface=$PentTargetTrackerInterface
    echo "Tracker interface passed via command line!" > $PENTOutputDevice
  fi

  # If user skipped a tracker interface, move on.
  if [ ! "$selectedInterface" ]; then
    pent_target_unset_tracker
    return 0
  fi

  if ! pent_allocate_interface $selectedInterface; then
    echo "Failed to allocate tracking interface!" > $PENTOutputDevice
    return 3
  fi

  echo "Successfully got tracker interface." > $PENTOutputDevice
  PentTargetTrackerInterface=${PentInterfaces[$selectedInterface]}
}

pent_target_unset() {
  PentTargetMAC=""
  PentTargetSSID=""
  PentTargetChannel=""

  PentTargetEncryption=""

  PentTargetMakerID=""
  PentTargetMaker=""

  PentTargetSSIDClean=""

  PentTargetRogueMAC=""

  return 1 # To trigger undo-chain.
}

pent_target_set() {
  # Check if attack is targetted & set the attack target if so.
  if ! type -t attack_targetting_interfaces &> /dev/null; then
    return 1
  fi

  if [ \
    "$PentTargetSSID" -a \
    "$PentTargetMAC" -a \
    "$PentTargetChannel" \
  ]; then
    # If we've got a candidate target, ask user if we'll keep targetting it.

    pent_header
    pent_target_show
    echo
    echo -e  "$PENTVLine $PENTTargettingAccessPointAboveNotice"

    # TODO: This doesn't translate choices to the selected language.
    while ! echo "$choice" | grep -q "^[ynYN]$" &> /dev/null; do
      echo -ne "$PENTVLine $PENTContinueWithTargetQuery [Y/n] "
      local choice
      read choice
      if [ ! "$choice" ]; then break; fi
    done

    echo -ne "\n\n"

    if [ "${choice,,}" != "n" ]; then
      return 0
    fi
  elif [ \
    "$PentTargetSSID" -o \
    "$PentTargetMAC" -o \
    "$PentTargetChannel" \
  ]; then
    # TODO: Survey environment here to autofill missing fields.
    # In other words, if a user gives incomplete information, scan
    # the environment based on either the ESSID or BSSID, & autofill.
    echo -e "$PENTVLine $PENTIncompleteTargettingInfoNotice"
    sleep 3
  fi

  if ! pent_get_interface attack_targetting_interfaces \
    "$PENTTargetSearchingInterfaceQuery"; then
    return 2
  fi

  if ! pent_allocate_interface $PentInterfaceSelected; then
    return 3
  fi

  if ! pent_get_target \
    ${PentInterfaces[$PentInterfaceSelected]}; then
    return 4
  fi
}


# =================== < Hash Subroutines > =================== #
# Parameters: <hash path> <bssid> <essid> [channel [encryption [maker]]]
pent_hash_verify() {
  if [ ${#@} -lt 3 ]; then return 1; fi

  local -r hashPath=$1
  local -r hashBSSID=$2
  local -r hashESSID=$3
  local -r hashChannel=$4
  local -r hashEncryption=$5
  local -r hashMaker=$6

  if [ ! -f "$hashPath" -o ! -s "$hashPath" ]; then
    echo -e "$PENTVLine $PENTHashFileDoesNotExistError"
    sleep 3
    return 2
  fi

  if [ "$PENTAuto" ]; then
    local -r verifier="cowpatty"
  else
    pent_header

    echo -e "$PENTVLine $PENTHashVerificationMethodQuery"
    echo

    pent_target_show

    local choices=( \
      "$PENTHashVerificationMethodAircrackOption" \
      "$PENTHashVerificationMethodCowpattyOption" \
    )

    # Add pyrit to the options is available.
    if [ -x "$(command -v pyrit)" ]; then
      choices+=("$PENTHashVerificationMethodPyritOption")
    fi

    options+=("$PENTGeneralBackOption")

    io_query_choice "" choices[@]

    echo

    case "$IOQueryChoice" in
      "$PENTHashVerificationMethodPyritOption")
        local -r verifier="pyrit" ;;

      "$PENTHashVerificationMethodAircrackOption")
        local -r verifier="aircrack-ng" ;;

      "$PENTHashVerificationMethodCowpattyOption")
        local -r verifier="cowpatty" ;;

      "$PENTGeneralBackOption")
        return -1 ;;
    esac
  fi

  hash_check_handshake \
    "$verifier" \
    "$hashPath" \
    "$hashESSID" \
    "$hashBSSID"

  local -r hashResult=$?

  # A value other than 0 means there's an issue with the hash.
  if [ $hashResult -ne 0 ]; then
    echo -e "$PENTVLine $PENTHashInvalidError"
  else
    echo -e "$PENTVLine $PENTHashValidNotice"
  fi

  sleep 3

  if [ $hashResult -ne 0 ]; then return 1; fi
}

pent_hash_unset_path() {
  if [ ! "$PentHashPath" ]; then return 1; fi
  PentHashPath=""

  # Since we're auto-selecting when on auto, trigger undo-chain.
  if [ "$PENTAuto" ]; then return 2; fi
}

# Parameters: <hash path> <bssid> <essid> [channel [encryption [maker]]]
pent_hash_set_path() {
  if [ "$PentHashPath" ]; then return 0; fi

  pent_hash_unset_path

  local -r hashPath=$1

  # If we've got a default path, check if a hash exists.
  # If one exists, ask users if they'd like to use it.
  if [ "$hashPath" -a -f "$hashPath" -a -s "$hashPath" ]; then
    if [ "$PENTAuto" ]; then
      echo "Using default hash path: $hashPath" > $PENTOutputDevice
      PentHashPath=$hashPath
      return
    else
      local choices=( \
        "$PENTUseFoundHashOption" \
        "$PENTSpecifyHashPathOption" \
        "$PENTHashSourceRescanOption" \
        "$PENTGeneralBackOption" \
      )

      pent_header

      echo -e "$PENTVLine $PENTFoundHashNotice"
      echo -e "$PENTVLine $PENTUseFoundHashQuery"
      echo

      io_query_choice "" choices[@]

      echo

      case "$IOQueryChoice" in
        "$PENTUseFoundHashOption")
          PentHashPath=$hashPath
          return ;;

        "$PENTHashSourceRescanOption")
          pent_hash_set_path "$@"
          return $? ;;

        "$PENTGeneralBackOption")
          return -1 ;;
      esac
    fi
  fi

  while [ ! "$PentHashPath" ]; do
    pent_header

    echo
    echo -e "$PENTVLine $PENTPathToHandshakeFileQuery"
    echo -e "$PENTVLine $PENTPathToHandshakeFileReturnTip"
    echo
    echo -ne "$PENTAbsolutePathInfo: "
    read PentHashPath

    # Back-track when the user leaves the hash path blank.
    # Notice: Path is cleared if we return, no need to unset.
    if [ ! "$PentHashPath" ]; then return 1; fi

    echo "Path given: \"$PentHashPath\"" > $PENTOutputDevice

    # Make sure the path points to a valid generic file.
    if [ ! -f "$PentHashPath" -o ! -s "$PentHashPath" ]; then
      echo -e "$PENTVLine $PENTEmptyOrNonExistentHashError"
      sleep 5
      pent_hash_unset_path
    fi
  done
}

# Paramters: <defaultHashPath> <bssid> <essid>
pent_hash_get_path() {
  # Assure we've got the bssid and the essid passed in.
  if [ ${#@} -lt 2 ]; then return 1; fi

  while true; do
    pent_hash_unset_path
    if ! pent_hash_set_path "$@"; then
      echo "Failed to set hash path." > $PENTOutputDevice
      return -1 # WARNING: The recent error code is NOT contained in $? here!
    else
      echo "Hash path: \"$PentHashPath\"" > $PENTOutputDevice
    fi

    if pent_hash_verify "$PentHashPath" "$2" "$3"; then
      break;
    fi
  done

  # At this point PentHashPath will be set and ready.
}


# ================== < Attack Subroutines > ================== #
pent_unset_attack() {
  local -r attackWasSet=${PentAttack:+1}
  PentAttack=""
  if [ ! "$attackWasSet" ]; then return 1; fi
}

pent_set_attack() {
  if [ "$PentAttack" ]; then return 0; fi

  pent_unset_attack

  pent_header

  echo -e "$PENTVLine $PENTAttackQuery"
  echo

  pent_target_show

  local attacks
  readarray -t attacks < <(ls -1 "$PENTPath/attacks")

  local descriptions
  readarray -t descriptions < <(
    head -n 3 "$PENTPath/attacks/"*"/language/$PentLanguage.sh" | \
    grep -E "^# description: " | sed -E 's/# \w+: //'
  )

  local identifiers=()

  local attack
  for attack in "${attacks[@]}"; do
    local identifier=$(
      head -n 3 "$PENTPath/attacks/$attack/language/$PentLanguage.sh" | \
      grep -E "^# identifier: " | sed -E 's/# \w+: //'
    )
    if [ "$identifier" ]; then
      identifiers+=("$identifier")
    else
      identifiers+=("$attack")
    fi
  done

  attacks+=("$PENTGeneralBackOption")
  identifiers+=("$PENTGeneralBackOption")
  descriptions+=("")

  io_query_format_fields "" \
    "\t$CRed[$CSYel%d$CClr$CRed]$CClr%0.0s $CCyn%b$CClr %b\n" \
    attacks[@] identifiers[@] descriptions[@]

  echo

  if [ "${IOQueryFormatFields[1]}" = "$PENTGeneralBackOption" ]; then
    return -1
  fi

  if [ "${IOQueryFormatFields[1]}" = "$PENTAttackRestartOption" ]; then
    return 2
  fi


  PentAttack=${IOQueryFormatFields[0]}
}

pent_unprep_attack() {
  if type -t unprep_attack &> /dev/null; then
    unprep_attack
  fi

  IOUtilsHeader="pent_header"

  # Remove any lingering targetting subroutines loaded.
  unset attack_targetting_interfaces
  unset attack_tracking_interfaces

  # Remove any lingering restoration subroutines loaded.
  unset load_attack
  unset save_attack

  PentTargetTrackerInterface=""

  return 1 # Trigger another undo since prep isn't significant.
}

pent_prep_attack() {
  local -r path="$PENTPath/attacks/$PentAttack"

  if [ ! -x "$path/attack.sh" ]; then return 1; fi
  if [ ! -x "$path/language/$PentLanguage.sh" ]; then return 2; fi

  # Load attack parameters if any exist.
  if [ "$AttackCLIArguments" ]; then
    eval set -- "$AttackCLIArguments"
    # Remove them after loading them once.
    unset AttackCLIArguments
  fi

  # Load attack and its corresponding language file.
  # Load english by default to overwrite globals that ARE defined.
  source "$path/language/en.sh"
  if [ "$PentLanguage" != "en" ]; then
    source "$path/language/$PentLanguage.sh"
  fi
  source "$path/attack.sh"

  # Check if attack is targetted & set the attack target if so.
  if type -t attack_targetting_interfaces &> /dev/null; then
    if ! pent_target_set; then return 3; fi
  fi

  # Check if attack provides tracking interfaces, get & set one.
  # TODO: Uncomment the lines below after implementation.
  if type -t attack_tracking_interfaces &> /dev/null; then
    if ! pent_target_set_tracker; then return 4; fi
  fi

  # If attack is capable of restoration, check for configuration.
  if type -t load_attack &> /dev/null; then
    # If configuration file available, check if user wants to restore.
    if [ -f "$path/attack.conf" ]; then
      local choices=( \
        "$PENTAttackRestoreOption" \
        "$PENTAttackResetOption" \
      )

      io_query_choice "$PENTAttackResumeQuery" choices[@]

      if [ "$IOQueryChoice" = "$PENTAttackRestoreOption" ]; then
        load_attack "$path/attack.conf"
      fi
    fi
  fi

  if ! prep_attack; then return 5; fi

  # Save the attack for user's convenience if possible.
  if type -t save_attack &> /dev/null; then
    save_attack "$path/attack.conf"
  fi
}

pent_run_attack() {
  start_attack
  pent_target_tracker_start

  local choices=( \
    "$PENTSelectAnotherAttackOption" \
    "$PENTGeneralExitOption" \
  )

  io_query_choice \
    "$(io_dynamic_output $PENTAttackInProgressNotice)" choices[@]

  echo

  # IOQueryChoice is a global, meaning, its value is volatile.
  # We need to make sure to save the choice before it changes.
  local choice="$IOQueryChoice"

  pent_target_tracker_stop


  # could execute twice
  # but mostly doesn't matter
  if [ ! -x "$(command -v systemctl)" ]; then
    if [ "$(systemctl list-units | grep systemd-resolved)" != "" ];then
        systemctl restart systemd-resolved.service
    fi
  fi

  if [ -x "$(command -v service)" ];then
    if service --status-all | grep -Fq 'systemd-resolved'; then
      sudo service systemd-resolved.service restart
    fi
  fi

  stop_attack

  if [ "$choice" = "$PENTGeneralExitOption" ]; then
    pent_handle_exit
  fi

  pent_unprep_attack
  pent_unset_attack
}

# ============================================================ #
# ================= < Argument Executables > ================= #
# ============================================================ #
eval set -- "$PENTCLIArguments" # Set environment parameters.
while [ "$1" != "" -a "$1" != "--" ]; do
  case "$1" in
    -t|--target) echo "Not yet implemented!"; sleep 3; pent_shutdown;;
  esac
  shift # Shift new parameters
done

# ============================================================ #
# ===================== < PENT Loop > ===================== #
# ============================================================ #
pent_main() {
  pent_startup

  pent_set_resolution

  # Removed read-only due to local constant shadowing bug.
  # I've reported the bug, we can add it when fixed.
  local sequence=(
    "set_language"
    "set_attack"
    "prep_attack"
    "run_attack"
  )

  while true; do # Pent's runtime-loop.
    pent_do_sequence pent sequence[@]
  done

  pent_shutdown
}

pent_main # Start Pent

# FLUXSCRIPT END
