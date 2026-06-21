# install or update
if [ -d ~/.config/opencode/superpowers ]; then
  cd ~/.config/opencode/superpowers && git pull
else
  git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers
fi
mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills
rm -f ~/.config/opencode/plugins/superpowers.js
rm -rf ~/.config/opencode/skills/superpowers
ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js ~/.config/opencode/plugins/superpowers.js
ln -s ~/.config/opencode/superpowers/skills ~/.config/opencode/skills/superpowers
echo "Restart OpenCode to activate Superpowers."
