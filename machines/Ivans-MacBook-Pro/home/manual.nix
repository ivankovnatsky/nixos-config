{
  home = {
    file.".config/manual".text = ''
      npm --global install \
        @anthropic-ai/claude-code
    '';
  };
}
