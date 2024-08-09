# AiiDA DB backup script

This repo holds a script used to backup an AiiDA database using the `verdi storage backup` AiiDA CLI command.

The following Python environments are supported:

| Environment     | Command                                                     |
|-----------------|-------------------------------------------------------------|
| `conda`         | `./aiida-backup.sh -e conda -c <conda-env> -n <project-name>` |
| `venv`          | `./aiida-backup.sh -e venv -v <venv-path> -n <project-name>`  |
| `aiida-project` | `./aiida-backup.sh -e aiida-project -n <project-name>`        |

The script will backup all existing (autodetected) AiiDA profiles in the provided environment to `ROOT/<project-name>/<profile-name>`, where `ROOT` is to be predefined by the user within the script.

Alternatively, the user can choose to backup only specific profiles with `-p "<profile1> <profile2> ..."`.
