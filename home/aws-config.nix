let
  awsConfigText = builtins.readFile ../.secrets/config/aws;
in
{
  home.file = {
    ".aws/config" = {
      text = awsConfigText;
    };
  };
}
