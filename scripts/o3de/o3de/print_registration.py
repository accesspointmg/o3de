#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import json
import hashlib
import logging
import pathlib
import sys
import urllib.parse

from o3de import o3de_object, validation, utils, repo, cache

logger = logging.getLogger('o3de.print_registration')
logging.basicConfig(format=utils.LOG_FORMAT)


def print_child_engine(engine_name: str, verbose: int = 0, recurse=False) -> int:
    if not engine_name:
        print('No child engine specified.')
        return 1
    engine = o3de_object.manifest.find_child_engine(engine_name)
    if not engine:
        print(f'Child engine {engine_name} not found.')
        return 1
    
    engine.print_child(engine, verbose, recurse)

    return 0

def print_child_project(project_name: str, verbose: int = 0, recurse=False) -> int:
    if not project_name:
        print('No child project specified.')
        return 1
    project = o3de_object.manifest.find_child_project(project_name)
    if not project:
        print(f'Child project {project_name} not found.')
        return 1
    
    project.print_child(project, verbose, recurse)

    return 0

def print_child_gem(gem_name: str, verbose: int = 0, recurse=False) -> int:
    if not gem_name:
        print('No child gem specified.')
        return 1
    gem = o3de_object.manifest.find_child_gem(gem_name)
    if not gem:
        print(f'Child gem {gem_name} not found.')
        return 1
    
    gem.print_child(gem, verbose, recurse)

    return 0

def print_child_template(template_name: str, verbose: int = 0, recurse=False) -> int:
    if not template_name:
        print('No child template specified.')
        return 1
    template = o3de_object.manifest.find_child_template(template_name)
    if not template:
        print(f'Child template {template_name} not found.')
        return 1
    
    template.print_child(template, verbose, recurse)

    return 0

def print_child_repo(repo_name: str, verbose: int = 0, recurse=False) -> int:
    if not repo_name:
        print('No child repo specified.')
        return 1
    repo = o3de_object.manifest.find_child_repo(repo_name)
    if not repo:
        print(f'Child repo {repo_name} not found.')
        return 1
    
    repo.print_child(repo, verbose, recurse)

    return 0

def print_child_restricted(restricted_name: str, verbose: int = 0, recurse=False) -> int:
    if not restricted_name:
        print('No child restricted specified.')
        return 1
    restricted = o3de_object.manifest.find_child_restricted(restricted_name)
    if not restricted:
        print(f'Child restricted {restricted_name} not found.')
        return 1
    
    restricted.print_child(restricted, verbose, recurse)

    return 0

def print_remote_engine(engine_name: str, verbose: int = 0, recurse=False) -> int:
    if not engine_name:
        print('No remote engine specified.')
        return 1
    engine = o3de_object.manifest.find_remote_engine(engine_name)
    if not engine:
        print(f'Remote engine {engine_name} not found.')
        return 1
    
    engine.print_remote(engine, verbose, recurse)

    return 0

def print_remote_project(project_name: str, verbose: int = 0, recurse=False) -> int:
    if not project_name:
        print('No remote project specified.')
        return 1
    project = o3de_object.manifest.find_remote_project(project_name)
    if not project:
        print(f'Remote project {project_name} not found.')
        return 1
    
    project.print_remote(project, verbose, recurse)

    return 0

def print_remote_gem(gem_name: str, verbose: int = 0, recurse=False) -> int:    
    if not gem_name:
        print('No remote gem specified.')
        return 1
    gem = o3de_object.manifest.find_remote_gem(gem_name)
    if not gem:
        print(f'Remote gem {gem_name} not found.')
        return 1
    
    gem.print_remote(gem, verbose, recurse)

    return 0

def print_remote_template(template_name: str, verbose: int = 0, recurse=False) -> int:
    if not template_name:
        print('No remote template specified.')
        return 1
    template = o3de_object.manifest.find_remote_template(template_name)
    if not template:
        print(f'Remote template {template_name} not found.')
        return 1
    
    template.print_remote(template, verbose, recurse)

    return 0

def print_remote_repo(repo_name: str, verbose: int = 0, recurse=False) -> int:
    if not repo_name:
        print('No remote repo specified.')
        return 1
    repo = o3de_object.manifest.find_remote_repo(repo_name)
    if not repo:
        print(f'Remote repo {repo_name} not found.')
        return 1
    
    repo.print_remote(repo, verbose, recurse)

    return 0

def print_remote_restricted(restricted_name: str, verbose: int = 0, recurse=False) -> int:
    if not restricted_name:
        print('No remote restricted specified.')
        return 1
    restricted = o3de_object.manifest.find_remote_restricted(restricted_name)
    if not restricted:
        print(f'Remote restricted {restricted_name} not found.')
        return 1
    
    restricted.print_remote(restricted, verbose, recurse)

    return 0

def print_engine(engine_name, verbose: int = 0, recurse=False) -> None:
    if not engine_name:
        print('No engine specified.')
        return 1
       
    engine = o3de_object.manifest.find_engine(engine_name)
    if not engine:
        print(f'Engine {engine_name} not found.')
        return 1
    
    engine.print(engine, verbose, recurse)

    return 0

def print_project(project_name, verbose: int = 0, recurse=False) -> None:
    if not project_name:
        print('No project specified.')
        return 1
    
    project = o3de_object.manifest.find_project(project_name)
    if not project:
        print(f'Project {project_name} not found.')
        return 1
    
    project.print(project, verbose, recurse)

    return 0

def print_gem(gem_name, verbose: int = 0, recurse=False) -> None:
    if not gem_name:
        print('No gem specified.')
        return 1
    
    gem = o3de_object.manifest.find_gem(gem_name)
    if not gem:
        print(f'Gem {gem_name} not found.')
        return 1
    
    gem.print(gem, verbose, recurse)

    return 0

def print_template(template_name, verbose: int = 0, recurse=False) -> None:
    if not template_name:
        print('No template specified.')
        return 1
    
    template = o3de_object.manifest.find_template(template_name)
    if not template:
        print(f'Template {template_name} not found.')
        return 1
    
    template.print(template, verbose, recurse)

    return 0

def print_repo(repo_name, verbose: int = 0, recurse=False) -> None:
    if not repo_name:
        print('No repo specified.')
        return 1
    
    repo = o3de_object.manifest.find_repo(repo_name)
    if not repo:
        print(f'Repo {repo_name} not found.')
        return 1
    
    repo.print(repo, verbose, recurse)

    return 0

def print_restricted(restricted_name, verbose: int = 0, recurse=False) -> None:
    if not restricted_name:
        print('No restricted specified.')
        return 1
    
    restricted = o3de_object.manifest.find_restricted(restricted_name)
    if not restricted:
        print(f'Restricted {restricted_name} not found.')
        return 1
    
    restricted.print(restricted, verbose, recurse)

    return 0


def print_this_engine(verbose: int = 0, recurse=False) -> int:
    this_engine_path, this_engine = o3de_object.manifest.get_this_engine()
    if not this_engine_path:
        print('No engine path found.')
        return 1
    
    print_engine(this_engine.get_header().get_name(), verbose, recurse)

    return 0


def print_child_engines(verbose: int = 0) -> int:
    engine_paths, engines = o3de_object.manifest.get_child_engines()
    if not engine_paths:
        print('No child engines found.')
        return 1
    if verbose == 0:
        print(json.dumps(engine_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(engines.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Child Engines ##################################\n')
        for engine in engines:
            print(f'## Engines ########################################\n')
            print(f'Engine URI: {engine.get_header().get_object_uri()}')
            print(json.dumps(engine.get_object_json_data, indent=4))
        print(f'##################################################\n')
    return 0

def print_child_projects(verbose: int = 0) -> int:
    project_paths, projects = o3de_object.manifest.get_child_projects()
    if not project_paths:
        print('No child projects found.')
        return 1
    if verbose == 0:
        print(json.dumps(project_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(projects.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Child Projects ##################################\n')
        for project in projects:
            print(f'Project URI: {project.get_header().get_object_uri()}')
            print(json.dumps(project.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_child_gems(verbose: int = 0) -> int:
    gem_paths, gems = o3de_object.manifest.get_child_gems()
    if not gem_paths:
        print('No child gems found.')
        return 1
    if verbose == 0:
        print(json.dumps(gem_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(gems.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Child Gems ##################################\n')
        for gem in gems:
            print(f'Gem URI: {gem.get_header().get_object_uri()}')
            print(json.dumps(gem.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_child_templates(verbose: int = 0) -> int:
    template_paths, templates = o3de_object.manifest.get_child_templates()
    if not template_paths:
        print('No child templates found.')
        return 1
    if verbose == 0:
        print(json.dumps(template_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(templates.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Child Templates ##################################\n')
        for template in templates:
            print(f'Template URI: {template.get_header().get_object_uri()}')
            print(json.dumps(template.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_child_repos(verbose: int = 0) -> int:
    repo_paths, repos = o3de_object.manifest.get_child_repos()
    if not repo_paths:
        print('No child repos found.')
        return 1
    if verbose == 0:
        print(json.dumps(repo_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(repos.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Child Repos ##################################\n')
        for repo in repos:
            print(f'Repo URI: {repo.get_header().get_object_uri()}')
            print(json.dumps(repo.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_child_restricteds(verbose: int = 0) -> int:
    restricted_paths, restricteds = o3de_object.manifest.get_child_restricteds()
    if not restricted_paths:
        print('No child restricteds found.')
        return 1
    if verbose == 0:
        print(json.dumps(restricted_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(restricteds.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Child Restricteds ##################################\n')
        for restricted in restricteds:
            print(f'Restricted URI: {restricted.get_header().get_object_uri()}')
            print(json.dumps(restricted.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_remote_engines(verbose: int = 0) -> int:
    engine_paths, engines = o3de_object.manifest.get_remote_engines()
    if not engine_paths:
        print('No remote engines found.')
        return 1
    if verbose == 0:
        print(json.dumps(engine_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(engines.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Remote Engines #################################\n')
        for engine in engines:
            print(f'## Engines ########################################\n')
            print(f'Engine URI: {engine.get_header().get_object_uri()}')
            print(json.dumps(engine.get_object_json_data, indent=4))
        print(f'##################################################\n')
    return 0

def print_remote_projects(verbose: int = 0) -> int:
    project_paths, projects = o3de_object.manifest.get_remote_projects()
    if not project_paths:
        print('No remote projects found.')
        return 1
    if verbose == 0:
        print(json.dumps(project_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(projects.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Remote Projects #################################\n')
        for project in projects:
            print(f'Project URI: {project.get_header().get_object_uri()}')
            print(json.dumps(project.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_remote_gems(verbose: int = 0) -> int:
    gem_paths, gems = o3de_object.manifest.get_remote_gems()
    if not gem_paths:
        print('No remote gems found.')
        return 1
    if verbose == 0:
        print(json.dumps(gem_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(gems.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Remote Gems #################################\n')
        for gem in gems:
            print(f'Gem URI: {gem.get_header().get_object_uri()}')
            print(json.dumps(gem.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_remote_templates(verbose: int = 0) -> int:
    template_paths, templates = o3de_object.manifest.get_remote_templates()
    if not template_paths:
        print('No remote templates found.')
        return 1
    if verbose == 0:
        print(json.dumps(template_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(templates.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Remote Templates #################################\n')
        for template in templates:
            print(f'Template URI: {template.get_header().get_object_uri()}')
            print(json.dumps(template.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_remote_repos(verbose: int = 0) -> int:    
    repo_paths, repos = o3de_object.manifest.get_remote_repos()
    if not repo_paths:
        print('No remote repos found.')
        return 1
    if verbose == 0:
        print(json.dumps(repo_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(repos.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Remote Repos #################################\n')
        for repo in repos:
            print(f'Repo URI: {repo.get_header().get_object_uri()}')
            print(json.dumps(repo.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def print_remote_restricteds(verbose: int = 0) -> int:      
    restricted_paths, restricteds = o3de_object.manifest.get_remote_restricteds()
    if not restricted_paths:
        print('No remote restricteds found.')
        return 1
    if verbose == 0:
        print(json.dumps(restricted_paths, indent=4))
    elif verbose == 1:
        print(json.dumps(str(restricteds.get_object_json_data()), indent=4))
    elif verbose > 1:
        print(f'## Remote Restricteds #################################\n')
        for restricted in restricteds:
            print(f'Restricted URI: {restricted.get_header().get_object_uri()}')
            print(json.dumps(restricted.get_object_json_data(), indent=4))
        print(f'##################################################\n')
    return 0

def _run_register_show(args: argparse) -> int:
    if args.this_engine:
        return print_this_engine(args.verbose, args.recurse)
    
    elif args.child_engines:
        return print_child_engines(args.verbose, args.recurse)
    elif args.child_projects:
        return print_child_projects(args.verbose, args.recurse)
    elif args.child_gems:
        return print_child_gems(args.verbose, args.recurse)
    elif args.child_templates:
        return print_child_templates(args.verbose, args.recurse)
    elif args.child_repos:
        return print_child_repos(args.verbose, args.recurse)
    elif args.child_restricteds:
        return print_child_restricteds(args.verbose, args.recurse)

    elif args.remote_engines:
        return print_remote_engines(args.verbose, args.recurse)
    elif args.remote_projects:
        return print_remote_projects(args.verbose, args.recurse)
    elif args.remote_gems:
        return print_remote_gems(args.verbose, args.recurse)
    elif args.remote_templates:
        return print_remote_templates(args.verbose, args.recurse)
    elif args.remote_repos:
        return print_remote_repos(args.verbose, args.recurse)
    elif args.remote_restricteds:
        return print_remote_restricteds(args.verbose, args.recurse)
         
    elif args.child_manifest:
        return o3de_object.manifest.print_child(args.verbose, args.recurse)
    elif args.child_engine:
        return print_child_engine(args.child_engine, args.verbose, args.recurse)
    elif args.child_project:
        return print_child_project(args.child_project, args.verbose, args.recurse)
    elif args.child_gem:
        return print_child_gem(args.child_gem, args.verbose, args.recurse)
    elif args.child_template:
        return print_child_template(args.child_template, args.verbose, args.recurse)
    elif args.child_repo:
        return print_child_repo(args.child_repo, args.verbose, args.recurse)
    elif args.child_restricted:
        return print_child_restricted(args.child_restricted, args.verbose, args.recurse)
    
    elif args.remote_manifest:
        return o3de_object.manifest.print_remote(args.verbose, args.recurse)
    elif args.remote_engine:
        return print_remote_engine(args.remote_engine, args.verbose, args.recurse)
    elif args.remote_project:
        return print_remote_project(args.remote_project, args.verbose, args.recurse)
    elif args.remote_gem:
        return print_remote_gem(args.remote_gem, args.verbose, args.recurse)
    elif args.remote_template:
        return print_remote_template(args.remote_template, args.verbose, args.recurse)
    elif args.remote_repo:
        return print_remote_repo(args.remote_repo, args.verbose, args.recurse)
    elif args.remote_restricted:
        return print_remote_restricted(args.remote_restricted, args.verbose, args.recurse)
    
    elif args.engine:
        return print_engine(args.remote_engine, args.verbose, args.recurse)
    elif args.project:
        return print_project(args.remote_project, args.verbose, args.recurse)
    elif args.gem:
        return print_gem(args.remote_gem, args.verbose, args.recurse)
    elif args.template:
        return print_template(args.remote_template, args.verbose, args.recurse)
    elif args.repo:
        return print_repo(args.remote_repo, args.verbose, args.recurse)
    elif args.restricted:
        return print_restricted(args.remote_restricted, args.verbose, args.recurse)

    else:#if args.manifest:
        return o3de_object.manifest.print(args.verbose, args.recurse)

def add_args(subparsers) -> None:
    """
    add_args is called to add subparsers arguments to each command such that it can be
    a central python file such as o3de.py.
    It can be run from the o3de.py script as follows
    call add_args and execute: python o3de.py register-show --manifest
    :param subparsers: the caller instantiates subparsers and passes it in here
    """
    register_show_subparser = subparsers.add_parser('register-show')

    register_show_subparser.add_argument('-v', '--verbose', action='count', required=False,
                        default=0,
                        help='How verbose do you want the output to be.')

    register_show_subparser.add_argument('-r', '--recurse', action='store_true', required=False,
                       default=False,
                       help='recurse into children.')

    group = register_show_subparser.add_mutually_exclusive_group(required=True)
    group.add_argument('--this-engine', action='store_true', required=False,
                       default=False,
                       help='Output the current engine path.')

    group.add_argument('--child-manifest', action='store_true', required=False,
                       default=False,
                       help='Output the manifest children.')
    group.add_argument('--child-engines', action='store_true', required=False,
                       default=False,
                       help='Output the child engines registered.')
    group.add_argument('--child-projects', action='store_true', required=False,
                       default=False,
                       help='Output the child projects registered.')
    group.add_argument('--child-gems', action='store_true', required=False,
                       default=False,
                       help='Output the child gems registered.')
    group.add_argument('--child-templates', action='store_true', required=False,
                       default=False,
                       help='Output the child templates registered.')
    group.add_argument('--child-repos', action='store_true', required=False,
                       default=False,
                       help='Output the child repos registered.')
    group.add_argument('--child-restricteds', action='store_true', required=False,
                       default=False,
                       help='Output the child restricteds registered.')
    
    group.add_argument('--remote-manifest', action='store_true', required=False,
                       default=False,
                       help='Output the remote manifest.')
    group.add_argument('--remote-engines', action='store_true', required=False,
                       default=False,
                       help='Output the remote engines registered.')
    group.add_argument('--remote-projects', action='store_true', required=False,
                       default=False,
                       help='Output the remote projects registered.')
    group.add_argument('--remote-gems', action='store_true', required=False,
                       default=False,
                       help='Output the remote gems registered.')
    group.add_argument('--remote-templates', action='store_true', required=False,
                       default=False,
                       help='Output the remote templates registered.')
    group.add_argument('--remote-repos', action='store_true', required=False,
                       default=False,
                       help='Output the remote repos registered.')
    group.add_argument('--remote-restricteds', action='store_true', required=False,
                       default=False,
                       help='Output the remote restricteds registered.')
    
    group.add_argument('--manifest', action='store_true', required=False,
                       default=False,
                       help='Output the manifest.')
    
    group.add_argument('--child-engine', type=str, required=False,
                       default=False,
                       help='Output the child engine registered.')
    group.add_argument('--child-project',type=str, required=False,
                       default=False,
                       help='Output the child projects registered.')
    group.add_argument('--child-gem', type=str, required=False,
                       default=False,
                       help='Output the child gem registered.')
    group.add_argument('--child-template', type=str, required=False,
                       default=False,
                       help='Output the child template registered.')
    group.add_argument('--child-repo', type=str, required=False,
                       default=False,
                       help='Output the child repo registered.')
    group.add_argument('--child-restricted', type=str, required=False,
                       default=False,
                       help='Output the child restricted registered.')
    
    group.add_argument('--remote-engine', type=str, required=False,
                       default=False,
                       help='Output the remote engine registered.')
    group.add_argument('--remote-project', type=str, required=False,
                       default=False,
                       help='Output the remote project registered.')
    group.add_argument('--remote-gem', type=str, required=False,
                       default=False,
                       help='Output the remote gem registered.')
    group.add_argument('--remote-template', type=str, required=False,
                       default=False,
                       help='Output the remote template registered.')
    group.add_argument('--remote-repo', type=str, required=False,
                       default=False,
                       help='Output the remote repo registered.')
    group.add_argument('--remote-restricted', type=str, required=False,
                       default=False,
                       help='Output the remote restricted registered.')
    
    group.add_argument('--engine', type=str, required=False,
                       default=False,
                       help='Output the remote engine registered.')
    group.add_argument('--project', type=str, required=False,
                       default=False,
                       help='Output the remote project registered.')
    group.add_argument('--gem', type=str, required=False,
                       default=False,
                       help='Output the remote gem registered.')
    group.add_argument('--template', type=str, required=False,
                       default=False,
                       help='Output the remote template registered.')
    group.add_argument('--repo', type=str, required=False,
                       default=False,
                       help='Output the remote repo registered.')
    group.add_argument('--restricted', type=str, required=False,
                       default=False,
                       help='Output the remote restricted registered.')

    register_show_subparser.set_defaults(func=_run_register_show)