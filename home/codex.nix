{ config, pkgs, ... }:

{
  # Create Codex configuration directory and files
  # https://github.com/openai/codex/blob/main/codex-rs/config.md
  # home.file.".codex/config.toml".text = ''
  #   # OpenAI Codex CLI Configuration

  #   # Model configuration
  #   model = "gpt-4o"
  #   model_provider = "openai"

  #   # Security and approval settings
  #   approval_policy = "untrusted"  # Prompt for untrusted commands
  #   sandbox_mode = "read-only"     # Default sandbox policy

  #   # Reasoning configuration for o-series models
  #   model_reasoning_effort = "medium"
  #   model_reasoning_summary = "auto"

  #   # File editor integration
  #   file_opener = "vscode"

  #   # Environment policy for subprocess execution
  #   [shell_environment_policy]
  #   inherit = "core"  # Only pass core environment variables
  #   ignore_default_excludes = false  # Filter out *KEY*, *TOKEN*, *SECRET*
  #   exclude = ["AWS_*", "AZURE_*", "GCP_*"]  # Additional exclusions

  #   # History settings
  #   [history]
  #   persistence = "save-all"  # Save conversation history

  #   # TUI settings
  #   [tui]
  #   disable_mouse_capture = false  # Enable mouse interaction

  #   # Uncomment for Zero Data Retention organizations
  #   # disable_response_storage = true
  # '';

  # Create global AGENTS.md for personal guidance
  # home.file.".codex/AGENTS.md".text = ''
  #   # Personal Codex Agent Instructions

  #   ## General Guidelines
  #   - Always follow NixOS declarative principles
  #   - Prefer functional programming patterns
  #   - Use proper error handling and logging
  #   - Follow existing code style and conventions

  #   ## NixOS Specific
  #   - Use `pkgs.writeText` for configuration files
  #   - Prefer systemd services over custom scripts
  #   - Always specify package versions when possible
  #   - Use `home-manager` for user-level configurations

  #   ## Development Preferences
  #   - Use meaningful variable names
  #   - Add comments for complex logic
  #   - Write tests when applicable
  #   - Follow security best practices
  # '';
}
