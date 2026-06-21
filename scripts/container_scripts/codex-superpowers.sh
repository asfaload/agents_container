git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
mkdir -p ~/.agents/skills
rm -f ~/.agents/skills/superpowers
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
echo "Restart Codex CLI to activate Superpowers."
