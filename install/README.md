All files in this directory is "compiled" from `src/` directory.

Compliation is defined by line matching `^source FILEPATH$`,
where `FILEPATH` is resolved from the basedir of current file relatively.

Files from `bin/` will source files from `lib/`.
All files in `bin/` is compiled to this directory.
