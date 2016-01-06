# client-env

client-env provides the ability for a single machine to switch between different
clients' environments and keep them isolated from one another on the same box.
For example, client A may have a certain set of configuration (SSH keys,
environment variables, scripts, etc.) that client B. This allows us to check
in and share certain non-sensitive configuration between developers to ensure
a consistent development environment.

A developer can switch between client environments using the `client-env-set`
and `client-env-clear` shell functions. Thus environment variables (`$PATH`,
etc.), symbolic links, client-specific scripts, etc. can be set and cleared,
respectively, if needed by the client.

It also sets a symbolic link in `$HOME` named `current-client-env`.

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

If `${client}-env/conf` is present and contains a script named
`client-env-set.sh`, that script will be `source`-d into the current shell when
`client-env-set` is called. If the script named `client-env-clear.sh` is
present, that script will be `source`-d into the current shell when
`client-env-clear` is called.

Once the directory structure is set up, `source` the
`.client-env-completion.bash` snippet in your `.bashrc` file in order to expose
the `client-env-set` and `client-env-clear` commands:

```bash
source $HOME/dev/mustardgrain/client-env/.client-env-completion.bash
```

### Example Scripts

The following are example scripts for `client-env-set.sh` and
`client-env-clear.sh`.

##### `client-env-set.sh`

```bash
__client-env-symlink-add bigcorp $HOME/.aws credentials

export AWS_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxx
export AWS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxx
export AWS_KEYPAIR=$HOME/.ssh/default.pem
```

##### `client-env-clear.sh`

```bash
__client-env-symlink-rm bigcorp $HOME/.aws credentials

unset AWS_ACCESS_KEY
unset AWS_SECRET_KEY
unset AWS_KEYPAIR
```

Note that these are `source`-d into the current shell and thus the environment
variables will be `export`-ed (set) and `unset` in the shell.
