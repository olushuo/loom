
declare -x BACKUPDIR=/tmp
# mk_file <path> [mode] [args...]: create file at @path, with contents from @args or stdin
# @path: absolute file path
# @mode: file mode in octal numbers (e.g. 0755)
# @args: if present, each separate arg creates a new line in @path, else take stdin input
# Creates any missing directory components and backs up existing instance to $BACKUPDIR.
function mk_file() {
	local FPATH="${1:?}"
	local MODE=""
	local DIR=$(dirname "${FPATH}") ARG
	if [[ ${2:-} =~ ^[0-7]+$ ]]; then
		MODE=$2
		shift
	fi
	[ -d "${DIR}" ]       || mkdir -p "${DIR}"     || die "FATAL: failed to create $DIR for $FPATH"
	[ -d ${BACKUPDIR:?} ] || mkdir -p ${BACKUPDIR} || die "FATAL: failed to create $BACKUPDIR"
	[ ! -e "${FPATH}" ]   || mv -f "${FPATH}" "$(consecutive_file "${BACKUPDIR%/}/${FPATH##*/}")"
	if [ $# -gt 1 ]; then
		for ARG in "${@:2}"; do echo "${ARG}"; done
	else
		cat
	fi > "${FPATH}" || die "failed to create ${FPATH}"
	if [[ "${MODE}" ]]; then
		chmod ${MODE} "${FPATH}" || die "FATAL: failed to change mode of $FPATH"
		debug "Created ${FPATH} (mode ${MODE})"
	else
		debug "Created ${FPATH}"
	fi >&2
}

# Generate new filename, so as not to overwrite existing one: file - file.1 - file.2 ...
function consecutive_file() {
	local FILE="${1:?}" i
	for ((i=1 ; ; i++)); do
		[ -e "${FILE}" ] || break
		FILE="${1}.${i}"
	done
	echo ${FILE}
}
