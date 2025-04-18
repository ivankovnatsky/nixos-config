{
  # Configure permissions for top-level storage directories using systemd-tmpfiles
  # Since access control is hierarchical, securing the parent directories is sufficient
  systemd.tmpfiles.rules = [
    # Adjust permissions on existing directories (z = adjust permissions only, doesn't create or delete)
    "z /storage/Data 0700 ivan users - -"
    "z /storage/Sources 0700 ivan users - -"
  ];
}
