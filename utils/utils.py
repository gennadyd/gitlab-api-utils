import os
import sys
import argparse
import requests

API_URL = os.environ["GITLAB_URL"]
TOKEN = os.environ["GITLAB_TOKEN"]
HEADERS = {"PRIVATE-TOKEN": TOKEN}

ROLE_MAP = {
    'guest': 10,
    'reporter': 20,
    'developer': 30,
    'maintainer': 40,
    'owner': 50
}

def get_user_id(username):
    """Return GitLab user ID by username."""
    response = requests.get(f"{API_URL}/api/v4/users?username={username}", headers=HEADERS)
    if response.ok and response.json():
        return response.json()[0]["id"]
    print(f"User '{username}' not found.")
    return None

def get_entity_id(name):
    """Return (ID, type) list for project or group name."""
    for entity_type in ["projects", "groups"]:
        response = requests.get(f"{API_URL}/api/v4/{entity_type}/{name.replace('/', '%2F')}", headers=HEADERS)
        if response.ok:
            return response.json()["id"], entity_type[:-1]  # 'projects' → 'project'
    print(f"Project or group '{name}' not found.")
    return None, None

def assign_role(username, entity_name, role):
    """Assign or update access level for user in project or group."""
    access_level = ROLE_MAP.get(role.lower())
    if access_level is None:
        print(f"Invalid role '{role}'. Valid roles: {', '.join(ROLE_MAP.keys())}")
        return

    user_id = get_user_id(username)
    if not user_id:
        return

    entity_id, entity_type = get_entity_id(entity_name)
    if not entity_id:
        return

    member_url = f"{API_URL}/api/v4/{entity_type}s/{entity_id}/members/{user_id}"
    response = requests.get(member_url, headers=HEADERS)

    if response.status_code == 200:
        # Member exists — update access level
        update = requests.put(member_url, headers=HEADERS, json={"access_level": access_level})
        if update.ok:
            print(f"Access level for '{username}' in {entity_type} '{entity_name}' updated to '{role}'.")
        else:
            print(f"Failed to update access: {update.status_code}, {update.text}")
    elif response.status_code == 404:
        # Member not found — add new
        print(f"User '{username}' is not a member of {entity_type} '{entity_name}'. Adding...")
        add_url = f"{API_URL}/api/v4/{entity_type}s/{entity_id}/members"
        add = requests.post(add_url, headers=HEADERS, json={"user_id": user_id, "access_level": access_level})
        if add.status_code == 201:
            print(f"User '{username}' added to {entity_type} '{entity_name}' with role '{role}'.")
        else:
            print(f"Failed to add user: {add.status_code}, {add.text}")
    else:
        print(f"Unexpected response: {response.status_code}, {response.text}")

def list_items_created_in_year(entity_type, year):
    """Search issues or merge requests created in the given year across all accessible projects."""
    assert entity_type in ["issues", "mr"]
    path = "merge_requests" if entity_type == "mr" else "issues"

    since = f"{year}-01-01T00:00:00Z"
    until = f"{year + 1}-01-01T00:00:00Z"

    # Get all accessible projects
    projects = []
    page = 1
    print("Fetching list of accessible projects...")

    while True:
        r = requests.get(f"{API_URL}/api/v4/projects", headers=HEADERS, params={"page": page, "per_page": 100})
        if r.status_code != 200:
            print(f"Failed to fetch projects. Status: {r.status_code}, Response: {r.text}")
            return
        data = r.json()
        if not data:
            break
        projects.extend(data)
        page += 1

    print(f"Found {len(projects)} projects.")

    # Search in each project
    for project in projects:
        project_id = project["id"]
        project_name = project["path_with_namespace"]
        total = 0
        page = 1
        collected = []

        while True:
            url = f"{API_URL}/api/v4/projects/{project_id}/{path}"
            params = {
                "created_after": since,
                "created_before": until,
                "page": page,
                "per_page": 100
            }
            r = requests.get(url, headers=HEADERS, params=params)
            if r.status_code != 200:
                break
            items = r.json()
            if not items:
                break
            collected.extend(items)
            total += len(items)
            page += 1

        if total > 0:
            for item in collected:
                title = item.get("title") or item.get("description") or "(no title)"
                print(f"[{item['id']}] {title}")

            print(f"\nProject: {project_name} ({project_id}) — {total} {path}")

def main():
    parser = argparse.ArgumentParser(description="GitLab utility script")
    subcommands = parser.add_subparsers(dest="command")

    assign = subcommands.add_parser("assign-role", help="Assign role to a user in a project or group")
    assign.add_argument("--username", required=True)
    assign.add_argument("--repo_or_group_name", required=True)
    assign.add_argument("--role", required=True)

    get = subcommands.add_parser("get", help="List issues or merge requests for a given year")
    get.add_argument("--type", choices=["mr", "issues"], required=True)
    get.add_argument("--year", type=int, required=True)

    args = parser.parse_args()

    if args.command == "assign-role":
        assign_role(args.username, args.repo_or_group_name, args.role)
    elif args.command == "get":
        list_items_created_in_year(args.type, args.year)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
