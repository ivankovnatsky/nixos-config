{ config, ... }:
{
  systemd.services.zigbee2mqtt.after = [ "mosquitto.service" ];
  # https://www.reddit.com/r/Zigbee2MQTT/comments/1ihh67u/slzb07_not_recognized_version_12_is_not_supported/
  # https://smlight.tech/flasher/#SLZB-07
  # https://smlight.tech/manual-slzb-07/

  # Add udev rule for persistent device naming
  services.udev.extraRules = ''
    # SMLIGHT SLZB-07 Zigbee device with serial number acc96c324273ed11a4156aeefdf7b791
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", ATTRS{serial}=="acc96c324273ed11a4156aeefdf7b791", SYMLINK+="zigbee_adapter", SYMLINK+="ttyUSB0"
  '';

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      advanced = {
        channel = 25;
        device_options.legacy = false;
        homeassistant_legacy_entity_attributes = false;
        homeassistant_legacy_triggers = false;
        legacy_api = false;
        legacy_availability_payload = false;
        last_seen = "ISO_8601";
        transmit_power = 20;
      };
      availability.enabled = true;
      devices = "devices.yaml";
      frontend = {
        enabled = true;
        host = config.flags.beeIp;
        port = 8081;
      };
      groups = "groups.yaml";
      homeassistant = {
        enabled = true;
        experimental_event_entities = true;
        status_topic = "homeassistant/status";
      };
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://127.0.0.1:1883";
        version = 5;
      };
      permit_join = false;
      serial = {
        adapter = "ember";
        baudrate = 115200;
        port = "/dev/zigbee_adapter";
      };
      version = 4;
    };
  };
}
