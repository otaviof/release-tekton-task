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