#
# Helper Functions
#

# print error message and exit on error.
function fail() {
	echo "ERROR: ${*}" >&2
	exit 1
}

# print out a strutured message.
function phase() {
	echo "---> Phase: ${*}..."
}

# inspect the path after the informed executable name.
function probe_bin_on_path() {
	local name="${1}"

	if ! type -a ${name} >/dev/null 2>&1; then
		fail "Can't find '${name}' on 'PATH=${PATH}'"
	fi
}

# download and install the informed URL path and tarball name from gihub.com releases, then extracts
# the informed binary name directly on /usr/local/bin (PREFIX).
function download_and_install() {
	local url_path="${1}"
	local tarball="${2}"
	local bin_name="${3}"

	# composing the tarball download location
	local url="https://github.com/${url_path}/${tarball}"
	# temporary tarball download path
	local tmp_tarball="/tmp/${tarball}"
	# installation prefix
	local prefix="/usr/local/bin"

	[[ -f "${tmp_tarball}" ]] && rm -f "${tmp_tarball}"

	phase "Downloading '${url}' to '${tmp_tarball}'"
	curl -sL ${url} >${tmp_tarball}

	phase "Installing '${bin_name}' on prefix '${prefix}'"
	tar -C ${prefix} -zxvpf ${tmp_tarball} ${bin_name}
	rm -fv "${tmp_tarball}"
}
