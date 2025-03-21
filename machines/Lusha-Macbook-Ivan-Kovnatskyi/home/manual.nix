{
  home = {
    file.".config/manual".text = ''
      npm --global install \
        npm-groovy-lint \
        @anthropic-ai/claude-code
    '';
  };
}
