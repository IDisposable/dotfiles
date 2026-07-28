#!/bin/sh
# Points a WSL ~/.claude at the Windows .claude with symbolic links.
# Run once per WSL distribution. Safe to re-run.
# Override the Windows path with WIN_CLAUDE=/mnt/c/Users/<name>/.claude
set -eu

win="${WIN_CLAUDE:-/mnt/c/Users/idisp/.claude}"
dest="$HOME/.claude"
stamp="$(date +%Y-%m-%d)"

if [ ! -d "$win" ]; then
	echo "error: $win not found. Is the Windows drive mounted?" >&2
	exit 1
fi

mkdir -p "$dest"

link_file() {
	lf_target="$win/$1"
	lf_path="$dest/$1"

	if [ ! -e "$lf_target" ]; then
		echo "skip  $1: no target at $lf_target"
		return 0
	fi

	if [ -L "$lf_path" ]; then
		if [ "$(readlink "$lf_path")" = "$lf_target" ]; then
			echo "ok    $1: already linked"
			return 0
		fi
		rm "$lf_path"
	elif [ -e "$lf_path" ]; then
		# Never discard a real file. The WSL copy can be the only one.
		mv "$lf_path" "$lf_path.bak-$stamp"
		echo "saved $1: previous file kept as $1.bak-$stamp"
	fi

	ln -s "$lf_target" "$lf_path"
	echo "link  $1 -> $lf_target"
}

link_dir() {
	ld_target="$win/$1"
	ld_path="$dest/$1"

	mkdir -p "$ld_target"

	if [ -L "$ld_path" ]; then
		if [ "$(readlink "$ld_path")" = "$ld_target" ]; then
			echo "ok    $1: already linked"
			return 0
		fi
		rm "$ld_path"
	elif [ -d "$ld_path" ]; then
		# rmdir refuses a directory that holds files. That is the safe behavior.
		if ! rmdir "$ld_path" 2>/dev/null; then
			echo "error: $ld_path is not empty. Move its contents to $ld_target first." >&2
			exit 1
		fi
	fi

	ln -s "$ld_target" "$ld_path"
	echo "link  $1 -> $ld_target"
}

link_file CLAUDE.md
link_file settings.json
link_file settings.local.json
link_dir rules
link_dir transcripts

echo
echo "Left per machine on purpose: plugins/, projects/, sessions/, .credentials.json."
echo "See README.md, section Host setup (WSL)."
