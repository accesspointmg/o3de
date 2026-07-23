import argparse
import logging
import pathlib
import subprocess
import os
import urllib.parse

from o3de import utils

logging.basicConfig(format=utils.LOG_FORMAT)
logger = logging.getLogger('o3de.gitget')
logger.setLevel(logging.INFO)

def run_command(command, cwd=None, env=None):
    """Run a command and capture its output, with optional environment variables."""
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True, env=merged_env)
    if result.returncode != 0:
        logger.error(f"Command '{' '.join(command)}' failed with exit code {result.returncode}")
        logger.debug(f"stdout: {result.stdout}")
        logger.debug(f"stderr: {result.stderr}")
        raise subprocess.CalledProcessError(result.returncode, command)
    return result.returncode

def prepare_repo_url(repo_url, token=None):
    """Insert access token into repo URL if provided."""
    if not token:
        return repo_url
        
    # Parse the URL to inject the token
    parsed = urllib.parse.urlparse(repo_url)
    if parsed.scheme in ('http', 'https'):
        netloc = f"{token}@{parsed.netloc}"
        return urllib.parse.urlunparse((parsed.scheme, netloc, parsed.path, 
                                      parsed.params, parsed.query, parsed.fragment))
    return repo_url

def init_git_repo(local_dir, repo_url, token=None):
    """Initialize a Git repository with proper authentication."""
    local_dir = pathlib.Path(local_dir)
    
    # Create the local directory if it doesn't exist
    local_dir.mkdir(parents=True, exist_ok=True)
    
    # Initialize a new Git repository
    run_command(["git", "init", str(local_dir)])
    
    # Configure the repository to use the token if provided
    authenticated_url = prepare_repo_url(repo_url, token)
    run_command(["git", "-C", str(local_dir), "remote", "add", "origin", authenticated_url])
    
    # Enable sparse checkout
    run_command(["git", "-C", str(local_dir), "config", "core.sparseCheckout", "true"])
    
    return local_dir

def sparse_checkout_root_files(repo_url, branch, local_dir, token=None):
    """Sparse checkout only files in the root directory of the repository."""
    try:
        local_dir = init_git_repo(local_dir, repo_url, token)
        
        # Specify the root files to checkout
        sparse_checkout_file = local_dir / ".git" / "info" / "sparse-checkout"
        with sparse_checkout_file.open("w") as f:
            f.write("/*\n")
            f.write("!/*/*\n")
        
        # Pull the specified files from the remote repository
        run_command(["git", "-C", str(local_dir), "pull", "origin", branch])
        return 0
    except subprocess.CalledProcessError as e:
        logger.error(f"Git operation failed: {e}")
        return e.returncode

def sparse_checkout(repo_url, branch, file_or_folder_path, local_dir, token=None):
    """Sparse checkout a specific file or folder from the repository."""
    try:
        local_dir = init_git_repo(local_dir, repo_url, token)
        
        # Specify the file or folder to checkout
        sparse_checkout_file = local_dir / ".git" / "info" / "sparse-checkout"
        with sparse_checkout_file.open("w") as f:
            f.write(str(file_or_folder_path) + "\n")
        
        # Pull the specified file or folder from the remote repository
        run_command(["git", "-C", str(local_dir), "pull", "origin", branch])
        return 0
    except subprocess.CalledProcessError as e:
        logger.error(f"Git operation failed: {e}")
        return e.returncode

def _run_gitget(args: argparse) -> int:
    branch = args.branch if args.branch else "main"
    
    # Use token if provided
    token = args.token or os.environ.get('GIT_ACCESS_TOKEN')
    
    if args.file is None:
        return sparse_checkout_root_files(args.git_repo, branch, args.to, token)
    else:
        return sparse_checkout(args.git_repo, branch, args.file, args.to, token)

def add_args(subparsers) -> None:
    """
    add_args is called to add subparsers arguments to each command such that it can be
    a central python file such as o3de.py.
    It can be run from the o3de.py script as follows
    call add_args and execute: python o3de.py gitget --git-repo "https://git.overlo3de.com/apmg/Marine.git" --file "gem.json" --to "f:/marine" --token "ghp_1a2b3c4d5e6f7g8h9i0j"
    :param subparsers: the caller instantiates subparsers and passes it in here
    """
    gitget_subparser = subparsers.add_parser('gitget')

    # Sub-commands should declare their own verbosity flag, if desired
    utils.add_verbosity_arg(gitget_subparser)

    gitget_subparser.description = "download a single file from any git repo"
                           
    gitget_subparser.add_argument('--git-repo', 
                      dest='git_repo',
                      type=str,
                      required=True,
                      help='The git repo.')
    
    gitget_subparser.add_argument('--file', 
                       dest='file',
                       type=pathlib.Path, 
                       required=False,
                       help='the file you want from the git repo. otherwise all root files' )

    gitget_subparser.add_argument('--to', 
                      dest='to',
                      type=pathlib.Path,
                      required=True,
                      help='The path to the output folder.')
    
    gitget_subparser.add_argument('--branch', 
                       dest='branch',
                       type=str, 
                       required=False,
                       help='the branch you want from the git repo.' )
    
    gitget_subparser.add_argument('--token',
                      dest='token',
                      type=str,
                      required=False,
                      help='Personal access token for authentication (avoids 2FA issues)')
       
    gitget_subparser.set_defaults(func=_run_gitget)