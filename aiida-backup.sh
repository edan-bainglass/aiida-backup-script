#!/bin/bash

# CLI OPTIONS (IGNORE!) #################################################################

show_help() {
    echo
    echo "Usage: ./aiida-backup.sh [-h] [-e env-type] [-c conda-env -x conda-path] [-v venv-path] [-n project] [-p profiles]"
    echo
    echo "Examples:"
    echo "  conda:            ./aiida-backup.sh -e conda -c <conda-env> -n <project>"
    echo "  venv:             ./aiida-backup.sh -e venv -v aiida2.5 -n <project>"
    echo "  aiida-project:    ./aiida-backup.sh -e aiida-project -n <project>"
    echo
    echo "Options:"
    echo "  -h                Show this help message"
    echo "  -e env-type       The type of environment to activate (conda, venv, aiida-project)"
    echo "  -c conda-env      The name of the Conda environment to activate"
    echo "  -x conda-path     The path to the Conda shell executable (conda.sh)"
    echo "  -v venv-path      The path to the virtual environment to activate"
    echo "  -n project        The name of the AiiDA project (required) - used as a subdirectory under the target ROOT directory"
    echo "  -p profiles       The names of AiiDA profiles to backup (optional) - if not specified, all profiles will be backed up"
    echo "  -k keep           The number of backups to keep (default: 3)"
    echo
    echo "NOTE: "
    echo "  The project argument is required for backups, which assume a ROOT -> PROJECT -> PROFILE structure in the backup folder."
    echo "  If you do not already have a project name, we recommend using 'default', in which case, you would use (for example):"
    echo
    echo "    ./aiida-backup.sh -e conda -c <conda-env> -x <conda-path> -n default"
    echo
}

if [ "$#" -eq 0 ] || [ "${1:0:1}" != "-" ]; then
    show_help
    exit 0
fi

while getopts "he:c:x:v:a:n:p:k:" opt; do
    case "${opt}" in
    h) show_help && exit 0 ;;
    e) env=$OPTARG ;;
    c) conda_env=$OPTARG ;;
    x) conda_path=$OPTARG ;;
    v) venv_path=$OPTARG ;;
    n) project=$OPTARG ;;
    p) profiles=$OPTARG ;;
    k) keep=$OPTARG ;;
    *) echo "Invalid argument. Run with -h for help." && exit 1 ;;
    esac
done

if [ ! "$project" ]; then
    echo "Project name not specified. Use -n <name>" && exit 1
fi

case "${env}" in
conda)
    if [ ! "$conda_env" ]; then
        echo "Conda environment not specified. Use -c <name>" && exit 1
    fi
    if [ ! "$conda_path" ]; then
        echo "Conda.sh path not specified. Use -s <absolute-path-to-conda.sh>" && exit 1
    fi
    source "$conda_path"
    conda activate "$conda_env"
    ;;
venv)
    if [ ! "$venv_path" ]; then
        echo "Virtual environment path not specified. Use -v <path>"
        exit 1
    fi
    source "$venv_path/bin/activate"
    ;;
aiida-project)
    if [ ! -f "$HOME/.aiida_project.env" ]; then
        echo ".aiida_project.env not found in user home directory. Is aiida-project initialized?" && exit 1
    fi
    export $(grep -v '^#' "$HOME/.aiida_project.env" | xargs)
    source "$aiida_venv_dir/$project/bin/activate"
    ;;
*)
    echo "Python environment type not specified. Use -e <conda\|venv\|aiida-project>" && exit 1
    ;;
esac

# ROOT DIRECTORY FOR ALL BACKUPS ########################################################

NFS_ACCOUNT=""
ROOT="/nfs/wsbackup/${NFS_ACCOUNT}/aiida" # if on workstation

# Uncomment if on Thanos
# ROOT="/nfs/nfsbackup/aiida_thanos"

# BACKUP UTILITY ########################################################################

backup() {
    local project=$1
    local profiles=$2
    local log_file="$ROOT/$project/backup.log"

    # Overwrite log file, if exists
    mkdir -p "$ROOT/$project"
    echo -e "\nBacking up \"$project\" project" 2>&1 | tee "$log_file"

    # Find all profiles if none specified
    if [ ! "$profiles" ]; then
        profiles=$(verdi profile list | awk 'NF && !/Report:/ {gsub(/^\*/, ""); print $1}')
        [[ -z "$profiles" ]] && echo "No profiles found!" | tee -a "$log_file" && exit 1
    fi

    # Backup each profile
    for profile in $profiles; do
        path="$ROOT/$project/$profile"
        mkdir -p "$path"
        echo -e "\nBacking up \"$profile\" profile to $path \n" 2>&1 | tee -a "$log_file"
        verdi -p "$profile" storage backup --keep "${keep-3}" "$path" 2>&1 | tee -a "$log_file"
    done
}

# RUN BACKUP UTILITY ####################################################################

backup "$project" "$profiles"
