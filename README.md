# GitLab Custom Utils

This project provides a lightweight GitLab testing environment with CLI tools and data generators for local development and performance testing.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/gennadyd/gitlab-api-utils.git
cd gitlab-api-utils
cp .env.example .env
```

This prepares your local workspace and creates a configurable `.env` file.

### 2. Configure GitLab EE Container

Edit your `.env` file and uncomment the `GITLAB_URL` variable:

```ini
GITLAB_URL=http://localhost
```

Then start the GitLab EE container:

```bash
./gitlab-ee/build-gitlab-ee.sh
```

This script will:
- Start a GitLab EE container
- Display the root password at the end of setup

You can verify the container is running:

```bash
docker ps | grep gitlab-ee
```

### 3. Create a Personal Access Token

Log into GitLab using the default admin account:

- Username: `root`  
- Password:  
  - Either copy the password shown after running the setup script  
  - Or run this command to retrieve it manually:

    ```bash
    docker exec -it gitlab-ee bash -c 'cat /etc/gitlab/initial_root_password' | grep -i password
    ```

Then visit:

[http://localhost/-/profile/personal_access_tokens](http://localhost/-/profile/personal_access_tokens)

Create a new token with the following scopes:
- `api`
- `write_repository`

Save the token to your `.env` file:

```ini
GITLAB_TOKEN=glpat-xxxxx
```

### 4. Generate Test Data

Use the data generator to populate GitLab with sample projects and merge requests:

```bash
./data-generator/run-generator.sh --auto
```

This will:
- Run the `gitlab/gpt-data-generator` container
- Use `gpt.json` to create test data under the `gpt` group

Notes:
- Without `--auto`, the script will prompt for confirmation.
- Users are not created by this generator.
- Merge requests and issues are created only within large projects.

### 5. Create Dummy Users

You can create test users (`devtest_1` to `devtest_5`) using a direct API script — no Docker image is required:

```bash
./utils/create-gitlab-dummy-users.sh
```

To verify that the users were created:

```bash
source .env
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/users?search=devtest"
```

This should return a JSON array with matching users.

### 6. Build GitLab Utils Image

This step builds the `gitlab-utils` Docker image, which includes CLI tools for interacting with GitLab:

```bash
./utils/build-gitlab-utils-image.sh
```

The image contains:
- A wrapper CLI tool (`gitlab-api-tool.sh`)
- Helper commands to fetch MRs/issues or assign roles via GitLab API

Once built, you can use the CLI tools from the container.

## CLI Utilities

You can use a CLI wrapper script to interact with GitLab's API.

### Setup Alias (optional)

```bash
alias gitlab-api-tool=./utils/gitlab-api-tool.sh
```

You may also add this alias to your `~/.bashrc` or `~/.zshrc`.

### Usage Examples

#### 1. Get Merge Requests by Year

```bash
gitlab-api-tool get --type mr --year 2019
```

Sample output:

```
Waiting for GitLab API to respond...
GitLab is up.

Running container: gitlab-utils
Running container with command:
docker run --rm -it --name gitlab-utils --network host --env-file /home/gennadyd/git/myTemps/gitlab-custom-utils/.env gitlab-utils get --type mr --year 2019
Fetching list of accessible projects...
Found 52 projects.
[3608] Added one question
[3607] Rebase master
[3605] Fix typo error
[3604] Fixed broken link
[3602] Delete LICENSE

Project: gpt/large_projects/gitlabhq1 (102) — 5 merge_requests
```

#### 2. Get Issues by Year

```bash
gitlab-api-tool get --type issues --year 2018
```

Sample output:

```
Waiting for GitLab API to respond...
GitLab is up.

Running container: gitlab-utils
Running container with command:
docker run --rm -it --name gitlab-utils --network host --env-file /home/gennadyd/git/myTemps/gitlab-custom-utils/.env gitlab-utils get --type issues --year 2018
Fetching list of accessible projects...
Found 52 projects.
[6710] No search result with two or less words in chinese
[6712] Support Forum: Account suspended and I did not do anything! How can that be?
[6720] What is a quick way to merge two gitlab systems into one?
[6714] what's the deference between the author and committer？
[6713] got error "standard_init_linux.go:195: exec user process caused "exec format error"" when run gitlab by docker
[6715] Mysql2 Specified key was too long; max key length is 767 bytes
[6719] Translation into Turkish
[6717] Where is personal token?
[6718] Quick Actions does not update state of Issue after Comment submitted
[6722] Contribution Summary Table Not Visible until Logged In
[6711] Where is project_path defined
[6716] Feature Request: Commit Individual Branch (Without Committing the whole master)
[6724] why not offer delete Milestone?
[6721] dd
[6723] why i don't have openid scope in gitlab?

Project: gpt/large_projects/gitlabhq1 (102) — 15 issues
```

#### 3. Assign Role to User in Group

```bash
gitlab-api-tool assign-role --username devtest_3 --repo_or_group_name gpt --role reporter
```

Sample output:

```
User 'devtest_3' is not a member of group 'gpt'. Adding...
User 'devtest_3' added to group 'gpt' with role 'reporter'.
```

#### 4. Assign Role to User in Project

```bash
gitlab-api-tool assign-role --username devtest_1 --repo_or_group_name gpt/large_projects/gitlabhq1 --role developer
```

Sample output:

```
Access level for 'devtest_1' in project 'gpt/large_projects/gitlabhq1' updated to 'developer'.
```


## Clean Up (coming soon)

To stop and remove all related containers:

```bash
./clean.sh
```

This script is not yet implemented.

## Troubleshooting (coming soon)

This section will contain tips and commands to help diagnose and fix common issues, such as:

- GitLab container not starting
- API returning 504 errors
- Token/authentication issues
