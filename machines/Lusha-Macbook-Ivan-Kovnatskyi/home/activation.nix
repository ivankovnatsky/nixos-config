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
      NPM_BIN="$HOME/.npm/bin"
      CLAUDE_CLI="$NPM_BIN/claude"

      if [[ -x "$CLAUDE_CLI" ]]; then
        export PATH="${pkgs.nodejs}/bin:$NPM_BIN:${pkgs.python313}/bin:$PATH"

        MCP_LIST=$("$CLAUDE_CLI" mcp list --scope user 2>/dev/null || echo "")

        if ! echo "$MCP_LIST" | grep -q "atlassian"; then
          echo "Installing Atlassian MCP server globally (--user scope)..."
          "$CLAUDE_CLI" mcp add --scope user --transport sse atlassian https://mcp.atlassian.com/v1/sse || echo "Atlassian MCP server already exists, skipping..."
        else
          echo "Atlassian MCP server already configured, skipping..."
        fi

        if ! echo "$MCP_LIST" | grep -q "github"; then
          echo "Installing GitHub MCP server globally (--user scope)..."
          "$CLAUDE_CLI" mcp add --scope user --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer ${config.secrets.ghMcpToken}" || echo "GitHub MCP server already exists, skipping..."
        else
          echo "GitHub MCP server already configured, skipping..."
        fi
      else
        echo "Claude CLI not installed yet, skipping MCP server configuration..."
      fi

      # Serena MCP installation disabled
      # if ! echo "$MCP_LIST" | grep -q "serena"; then
      #   echo "Installing Serena MCP server..."
      #   "$CLAUDE_CLI" mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project '$(pwd)'
      # fi
    '';
  };
}
