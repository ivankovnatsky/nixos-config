{ ... }:

let editorName = "nvim";

in {
  environment.variables = {
    EDITOR = editorName;
    VISUAL = editorName;
  };
}
