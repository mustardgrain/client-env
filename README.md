# client-env

client-env provides the ability for a single machine to switch between different
clients' environments and keep them isolated from one another on the same box.
For example, client A may have a certain set of configuration (SSH keys,
environment variables, scripts, etc.) that client B. This allows us to check
in and share certain non-sensitive configuration between developers to ensure
a consistent development environment.

A developer can switch between client environments using the `client-env-set`
shell function. This sets environment variables, `$PATH`, etc., if needed by
the client. It also sets a symlink in `$HOME` named `current-client-env`.

A client environment may contain many sub-directories:

* `bin` directory for scripts and command line utilities
* `conf` directory for configuration
* `data` directory for sample data
* `doc` directory for documentation files
* `notes` directory containing meeting notes or other notes of interest
* `src` directory which contains prototype/one-off scripts

None of the above are strictly required. At this time, in fact, only the `bin`
and `conf` directories are referenced, if either are present.

### Setup

client-env assumes there is an environment variable named `LOCAL_DEV_DIR`
that points to a directory under which all of your `git` repositories live.
This allows tools like [`git-utils`](https://github.com/mustardgrain/git-utils)
to traverse all of your git repositories to perform different bulk operations.
If your clients' environment directories are in git, they live here too.

Under `LOCAL_DEV_DIR` there are top-level client directories and under each
client you can add a specially-named directory named `${client}-env`.

If `${client}-env/bin` is present, it will be added to the `PATH` environment
variable value.

If `${client}-env/conf` is present and contains a script named `client-env.sh`,
the `client-env.sh` script will be `source`-d into the current shell.

Once the directory structure is set up, `source` the
`.client-env-completion.bash` snippet in your `.bashrc` file in order to expose
the `client-env-set` and `client-env-clear` commands:

```bash
source $HOME/dev/mustardgrain/client-env/.client-env-completion.bash
```
