#!/usr/bin/env bash
# shellcheck disable=2016
# TODO need a declarative version of the `poetry install` command that says "reify virtualenv to current pyproject.toml/poetry.lock state"
layout_poetry() {
	if [[ ! -f pyproject.toml ]]; then
		log_error 'No pyproject.toml found.  Use `poetry new` or `poetry init` to create one first.'
		exit 2
	fi

	local VENV
	VENV=$(poetry env info --path)
	if [[ ! -d $VENV || ! -d $VENV/bin ]]; then
		log_status 'No created poetry virtual environment found. Creating new one...'
		poetry install || exit 2
		VENV=$(poetry env info --path)
	else
		log_status 'Synchronising poetry virtual environment to lockfile...'
		poetry lock
		poetry sync || exit 2
	fi

	export VIRTUAL_ENV="$VENV"
	export POETRY_ACTIVE=1
	PATH_add "$VENV/bin"
}
