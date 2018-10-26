#!/bin/bash

function usage() {
    exec cat >&2 <<EO_USAGE
usage: ${0##*/} [options]
      -h, --help        display this help screen
      -d, --defaults    use the default values wherever suggested
EO_USAGE
}

if [ -z "${RUNNING_IN_SCRIPT}" ]; then
	declare -x TEMP

	# Parse command-line options
	TEMP="$(getopt -a -o hid -l help,defaults, -n "${0##*/}" -- "$@")" || usage

	eval set -- "${TEMP}"
	while true; do
		case "$1" in
		-h|--help    )	usage;;
		-d|--defaults)	__PROMPT_USES_DEFAULT="enabled"; shift;;
			   --)	shift;                           break;;
			    *)	die "Internal getopt error.";;
		esac
	done

	# Log output to 'running_<script_name>.log'
	RUNNING_IN_SCRIPT="true"
fi

#------------------------------------------------------------------------------------------------------------
# Logging Utilities
#------------------------------------------------------------------------------------------------------------
if [ -t 1 ]; then
	# See http://misc.flogisoft.com/bash/tip_colors_and_formatting
	_FATAL=$'\e[31;47;1m'
	_ERROR=${_FATAL}
	_INVERSE=$'\e[1;7m'
	_WARN=$'\e[33;44;1m'
	_INFO=$'\e[37;44;1m'
	_DEBUG=$'\e[30;47;1m'
	_PROMPT=${_INFO}
	_NOTE=$'\e[37;44;1;7m'	# _INFO with reverse video
	_RESET=$'\e[0m'
else
	_FATAL="" _ERROR="" _INVERSE="" _WARN=""
	_INFO=""  _DEBUG="" _PROMPT=""  _NOTE="" _RESET=""
fi

function note()  { echo -e >&2 "${_NOTE}$*${_RESET}";  }
function info()  { echo -e >&2 "${_INFO}$*${_RESET}";  }
function warn()  { echo -e >&2 "${_WARN}WARNING: $*${_RESET}"; }
function error() { echo -e >&2 "${_FATAL}$*${_RESET}"; }
function debug() { echo -e >&2 "${_DEBUG}$*${_RESET}"; }

# debug_run <cmd> [<args>]: run @cmd with @args after displaying it
function debug_run() {
	debug "$*"
	"$@"
}

# Like Perl, for fatal errors (works also in subshells)
function die()   {
	error "$@"
	kill 0
}

# in_array <element> <array> - return true if @array contains @element
function in_array() {
	local ELEMENT="${1:?}" CAND

	[ $# -gt 1 ] && \
	for CAND in "${@:2}"; do
		[[ "${CAND}" == "${ELEMENT}" ]] && break
	done
}

# join <sep> <el1> <el2> ...: join el<1> .. el<n> using separator @sep
function join() {
	local SEP="${1:?}" IFS=$'\t'

	sed "s#${IFS}#${SEP//\#/\\#}#g" <<< "${*:2}"
}

# Prompt for a value, allowing defaults and limiting choices:
# a) prompt <msg>                     - prompt for a non-empty answer
# b) prompt <msg> <default>           - prompt using @default in case of empty answer
# c) prompt <msg> <v1> <v2> [.. <vn>] - allow only v1 .. vn as valid answer
#    Special Case: if <vn> repeats an element v1 .. v<n-1>, it is used as a default
#    The case of using a single repeated element twice is the same as (b).
# d) If a function is passed in as the last argument, treat all preceding arguments
#    according to (a)..(c) and use this as one-argument validation function for $ANS.
function prompt() {
	local MSG="${_PROMPT}${1:?}${_RESET}" DEFAULT="" ANS="" VALFNC
	local -a ALLOWED=( "${@:2}" )

	# Special case: last argument is a one-argument validation function for $ANS.
	if [[ ${#ALLOWED[*]} -ge 1 && $(type -t ${ALLOWED[${#ALLOWED[*]}-1]}) == function ]]; then
		VALFNC=${ALLOWED[${#ALLOWED[*]}-1]}
		ALLOWED=( "${ALLOWED[@]:0:${#ALLOWED[*]}-1}" )
	fi

	case ${#ALLOWED[*]} in
	0) ;;
	1) DEFAULT=${ALLOWED[0]}
	   MSG="${MSG} [${DEFAULT}]";;
	*) if in_array ${ALLOWED[${#ALLOWED[*]}-1]} "${ALLOWED[@]:0:${#ALLOWED[*]}-1}"; then
		# Choice with default present.
		DEFAULT="${ALLOWED[${#ALLOWED[*]}-1]}"
		ALLOWED=( "${ALLOWED[@]:0:${#ALLOWED[*]}-1}" )
	   fi
	   MSG="${MSG} [$(join '/' "${ALLOWED[@]}")]"
	   ;;
	esac

	# Handling of defaults depends on the environment variable __PROMPT_USES_DEFAULT.
	# If it is set to "silent", it will not even echo the choice.
	if [ -n "${DEFAULT}" -a -n "${__PROMPT_USES_DEFAULT}" ]; then
		[[ ${__PROMPT_USES_DEFAULT} == silent ]] || echo >&2 "${MSG}: ${_NOTE}${DEFAULT}${_RESET}"
		echo ${DEFAULT}
		return
	fi

	until [[ "$ANS" ]]; do
		read -p "${MSG}: " ANS
		if [ -z "${ANS}" -a ${#ALLOWED[*]} -eq 1 ]; then
			ANS="${DEFAULT}"
		elif [ -n "${ANS}" -a ${#ALLOWED[*]} -gt 1 ]; then
			in_array "${ANS}" "${ALLOWED[@]}" || ANS=""
		elif [ -n "$VALFNC" ]; then
			ANS="$(${VALFNC} "${ANS}")"
		fi
	done
	echo ${ANS}
}

# confirm [<msg> [<OK-answer> [<not-OK-answer> [<default>]]]]: continue asking until 'y' or 'n' is pressed
# Uses 'OK-answer' as default. Returns whether OK/not-OK matched as exit code.
function confirm() {
	local MSG="${1:-Do you want to continue?}" OK="${2:-y}" NO="${3:-n}" DEFAULT="${4:-}"

	if [[ -n "$DEFAULT" && $DEFAULT == ${NO} ]]; then
		[[ $(prompt "${MSG}" "${NO}" "${OK}" "${NO}") == ${OK} ]]
	elif [[ -n "$DEFAULT" && $DEFAULT != $OK ]]; then
		die "$FUNCNAME BUG: DEFAULT='$DEFAULT' does not correspond to '$OK' or '$NO'"
	else
		[[ $(prompt "${MSG}" "${OK}" "${NO}" "${OK}") == ${OK} ]]
	fi
}

# confirmCont [<msg> [<OK-answer> [<not-OK-answer>]]]: continue asking until 'y' or 'n' is pressed
# - if all 3 arguments are present, do not return until $OK or $NO has been entered,
# - else use 'confirm' with defaults
function confirmCont() {
	local MSG="${1:-Do you want to continue?}" OK="${2:-y}" NO="${3:-n}"

	if [ $# -eq 3 ]; then
		[[ $(prompt "${MSG}" "${OK}" "${NO}") == ${OK} ]]
	else
		confirm "$@"
	fi && return
	die 'Exiting script, as requested!'
}

info "Loom is going to be installed..."

confirmCont "So far, Loom is only tested on Ubuntu 1804, are your sure you want to continue?" YES no
cp -v ./vimrc_ubuntu1804 ~/.vimrc

confirm "Vim and Git is needed" y n y

info "Installing Vundle..." 
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

info "Installing all plugins..." 
vim +PluginInstall +qall

info "Installing build-essential cmake python3-dev..." 
sudo apt install -y  build-essential cmake python3-dev

info "Installing Mono..." 
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update

sudo apt install -y mono-complete

confirm "Enable Go support" y n y

confirm "Enable JavaScript support" y n y
wget -qO- https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g typescript

confirm "Enable Rust support" y n y
curl https://sh.rustup.rs -sSf | sh

confirm "Enable Java support" y n y

info "Set up tern_for_vim..."
cd ~/.vim/bundle/tern_for_vim
npm install

info "Set up fonts..."
cd ~/.vim/bundle/fonts
./install.sh

info "Installing cargo and some extra package..."
sudo apt install -y cargo cargo-doc gdb-doc rust-doc rust-src libhttp-parser2.7.1 libstd-rust-1.28 libstd-rust-dev \
    rust-gdb rustc rust-gdb rustc

info "Compiling YouCompleteMe, it may take a while..."
cd ~/.vim/bundle/YouCompleteMe
python3 install.py --all

info "Return to your home directory..."
cd ~


