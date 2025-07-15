{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    codex
  ];

  # Create Codex configuration directory and files
  home.file.".codex/config.toml".text = ''
    # OpenAI Codex CLI Configuration
    
    # Security settings
    ask_for_approval = "untrusted"  # Prompt for untrusted commands
    sandbox = "read-only"           # Default sandbox policy
    
    # Disable response storage for Zero Data Retention (ZDR) if needed
    # disable_response_storage = true
    
    # Model configuration
    model = "gpt-4o"  # Default model to use
    
    # Logging configuration
    # log_level = "info"
  '';

  # Create global AGENTS.md for personal guidance
  home.file.".codex/AGENTS.md".text = ''
    # Personal Codex Agent Instructions
    
    ## General Guidelines
    - Always follow NixOS declarative principles
    - Prefer functional programming patterns
    - Use proper error handling and logging
    - Follow existing code style and conventions
    
    ## NixOS Specific
    - Use `pkgs.writeText` for configuration files
    - Prefer systemd services over custom scripts
    - Always specify package versions when possible
    - Use `home-manager` for user-level configurations
    
    ## Development Preferences
    - Use meaningful variable names
    - Add comments for complex logic
    - Write tests when applicable
    - Follow security best practices
  '';
}
