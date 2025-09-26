{ config, lib, pkgs, ... }:
{
  home.activation = {
    homeActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
      cat <<EOF > $HOME/.npmrc
        prefix=~/.npm
      EOF

      # Check if packages are already installed
      if [[ ! -x "$HOME/.npm/bin/npm-groovy-lint" || \
            ! -x "$HOME/.npm/bin/claude" || \
            ! -x "$HOME/.npm/bin/codex" || \
            ! -x "$HOME/.npm/bin/gemini" || \
            ! -x "$HOME/.npm/bin/happy" ]]; then
        echo "Installing missing npm packages..."
        export PATH="${pkgs.nodejs}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.curl}/bin:$PATH"
        ${pkgs.nodejs}/bin/npm install --global --force \
          npm-groovy-lint \
          @anthropic-ai/claude-code \
          @openai/codex \
          @google/gemini-cli \
          happy-coder
      else
        echo "All npm packages already installed, skipping..."
      fi

      # MCP (Model Context Protocol) servers for Claude Code
      # MCP servers are configured globally, not per-project. The $(pwd) in the command
      # tells the server which directory/project to provide context for when it starts.
      # This allows the IDE assistant to understand the current project structure.
      
      # Check if Serena MCP server is already configured
      NPM_BIN="$HOME/.npm/bin"
      CLAUDE_CLI="$NPM_BIN/claude"
      
      if [[ -x "$CLAUDE_CLI" ]]; then
        export PATH="${pkgs.nodejs}/bin:$NPM_BIN:${pkgs.python313}/bin:$PATH"
        if ! "$CLAUDE_CLI" mcp list 2>/dev/null | grep -q "serena"; then
          echo "Configuring Serena MCP server for Claude Code..."
          "$CLAUDE_CLI" mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project '$(pwd)'
        else
          echo "Serena MCP server already configured, skipping..."
        fi
      else
        echo "Claude CLI not installed yet, skipping MCP server configuration..."
      fi
    '';
  };
}
