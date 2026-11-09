# Publishing abaqus-remote on GitHub with git

All commands run in a WSL terminal.

## 1. One-time git setup

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"     # the email on your GitHub account
git config --global init.defaultBranch main
```

## 2. Sign in to GitHub from WSL

The easiest way is the GitHub CLI:

```bash
sudo apt update && sudo apt install gh
gh auth login          # GitHub.com -> HTTPS -> "Login with a web browser"
```

(Alternative: create a Personal Access Token at GitHub > Settings > Developer settings > Tokens,
and paste it as the password the first time `git push` asks.)

## 3. Make the folder a git repository and commit

```bash
cd ~/simul/abaqus-remote
git init
git add .
git status             # check: only the tool files, no .odb/.cae/models
git commit -m "Initial release of abaqus-remote"
```

## 4. Create the GitHub repo and push

With `gh` (creates the repo and pushes in one step):

```bash
gh repo create abaqus-remote --public --source=. --push \
  --description "Run Python scripts in a running Abaqus/CAE session from WSL"
```

Without `gh`: create an **empty** repo named `abaqus-remote` on github.com (no README, no license),
then:

```bash
git remote add origin https://github.com/seyongpak/abaqus-remote.git
git push -u origin main
```

If you publish your own copy, change the username in README.md's clone URL and commit that (step 6).

## 5. Make a release (a downloadable version)

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
gh release create v1.0.0 --generate-notes      # or: GitHub > Releases > Draft a new release
```

GitHub automatically attaches a .zip of the code to the release, for people who don't use git.

## 6. Updating later

```bash
# edit files, then:
git add -A
git commit -m "Describe what changed"
git push
# for a new version:
git tag -a v1.1.0 -m "v1.1.0" && git push origin v1.1.0 && gh release create v1.1.0 --generate-notes
```

## 7. How other people get it

```bash
git clone https://github.com/seyongpak/abaqus-remote.git
cd abaqus-remote && ./install.sh
# to get your updates later:
git pull && ./install.sh
```

## Useful extras

- `git log --oneline` - history of commits
- `git diff` - what you changed since the last commit
- Issues tab on GitHub - where users can report bugs
- To keep it private while testing, use `--private` instead of `--public` (you can switch later in Settings).
