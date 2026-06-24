echo "SETTING UP GIT IN CONTAINER"
set -x
if [[ -n "$GIT_USER_EMAIL" && -n "$GIT_USER_NAME" ]]; then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
fi
