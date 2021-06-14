let editorName = "nvim";

in
{
  environment = {
    homeBinInPath = true;

    variables = {
      EDITOR = editorName;
      VISUAL = editorName;
    };
  };
}
