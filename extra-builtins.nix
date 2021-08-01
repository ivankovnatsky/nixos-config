{ exec, ... }: {
  bw = name: exec [ ./nix-bw.sh name ];
}
