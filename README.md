# client-env

client-env provides the ability for a single machine to switch between different clients' environments and keep them isolated from one another on the same box. For example, client A may have a certain set of configuration (SSH keys, environment variables, scripts, etc.) that client B. This allows us to check in and share certain non-sensitive configuration between developers to ensure a consistent development environment.

A developer can switch between client environments using the `switch-client-env` shell function. This sets environment variables, `$PATH`, etc., if needed by the client.

A client environment may contain many sub-directories:

* `bin` directory for scripts and command line utilities
* `conf` directory for configuration
* `data` directory for sample data
* `doc` directory for documentation files
* `notes` directory containing meeting notes or other notes of interest
* `src` directory which contains prototype/one-off scripts

None of the above are strictly required. At this time, in fact, only the `bin` directory is referenced, if it is present.

### Setup

client-env assumes there is a directory in your `$HOME` directory named `.mustardgrain`. Inside that directory is a symlink (`dev`) and two sub-directories (`bin` and `env`).

For example, when running `tree $HOME/.mustardgrain`, I see:

```
/Users/kirk/.mustardgrain/
├── bin
│   ├── foo -> /Users/kirk/dev/foo
│   └── bar -> /Users/kirk/dev/bar
├── dev -> /Users/kirk/dev
└── env
    ├── foo -> /Users/kirk/topsecret/foo-env
    ├── bar -> /Users/kirk/topsecret/bar-env
    └── baz -> /Users/kirk/topsecret/baz-env
```

`dev` points to the root directory under which all of your `git` repositories live. This allows tools like [`git-utils`](https://github.com/mustardgrain/git-utils) to traverse all of your Git repositories to perform different operations. If your clients' environment directories are in Git, they could live here too.

`bin` is a subdirectory of `$HOME/.mustardgrain` that contains symlinks to the top level of your clients' environment directories, if needed. For example, in the above, clients `foo` and `bar` have client-specific utilities and/or scripts in their client environment directories, though `baz` doesn't have any.

`env` is a subdirectory of `$HOME/.mustardgrain` that contains symlinks to your clients' environment directories, if needed. Inside that directory, it is assumed that there is a script named `client-env.sh` that is `source`d into the current shell. In the above example, our clients have provided sensitive information (SSH keys, AWS credentials, etc.) that we don't want to commit to and store in a Git repository. These files live in a separate directory than the _main_ client environment directory. Having a separate `bin` and `env` directory allows us to keep them separate. If desired, the `bin` and `env` directories could point to the same client environment directory in all cases, or on a client-by-client basis.

Once the directory structure is set up, `source` the `.switch-client-env-completion.bash` snippet in your `.bashrc` file in order to expose the `switch-client-env` command:

```bash
  source $HOME/dev/client-env/.switch-client-env-completion.bash
```
