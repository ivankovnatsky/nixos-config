{
  # Force shutdown at 22:30 using launchd (bypasses power assertions)
  local.services.scheduled-shutdown = {
    enable = true;
    hour = 22;
    minute = 30;
  };
}
