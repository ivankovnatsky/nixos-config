{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "iam-policy-json-to-terraform";
  version = "341b6001a94bdec6b49868798e59b1a5f5e8c457";

  src = fetchFromGitHub {
    owner = "ivankovnatsky";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-tiGCY74++vnqrfJEMtQwTLe33tDsH5s2UpmBMX4P21s=";
  };

  vendorSha256 = "sha256-nnrqZ6NaxIQWfXC1RvxkuelFQLxAvMNhKraELJenZcw=";

  meta = with lib; {
    description = "Small tool to convert an IAM Policy in JSON format into a Terraform aws_iam_policy_document ";
    homepage = "https://github.com/flosell/iam-policy-json-to-terraform";
    changelog = "https://github.com/flosell/iam-policy-json-to-terraform/releases/tag/${version}";
    license = licenses.afl20;
    maintainers = [ maintainers.ivankovnatsky ];
  };
}
