/* See LICENSE file for copyright and license details. */

/* interval between updates (in ms) */
const unsigned int interval = 5000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "n/a";

static const char ethernet_iface[] = "eno1";

/* maximum output string length */
#define MAXLEN 2048

/*
 * function            description                     argument (example)
 *
 * cpu_perc            cpu usage in percent            NULL
 * cpu_freq            cpu frequency in MHz            NULL
 * datetime            date and time                   format string (%F %T)
 * disk_free           free disk space in GB           mountpoint path (/)
 * disk_perc           disk usage in percent           mountpoint path (/)
 * disk_total          total disk space in GB          mountpoint path (/")
 * disk_used           used disk space in GB           mountpoint path (/)
 * load_avg            load average                    NULL
 * netspeed_rx         receive network speed           interface name (eth0)
 * netspeed_tx         transfer network speed          interface name (eth0)
 * ram_free            free memory in GB               NULL
 * ram_perc            memory usage in percent         NULL
 * ram_total           total memory size in GB         NULL
 * ram_used            used memory in GB               NULL
 * run_command         custom shell command            command (echo foo)
 * vol_perc            OSS/ALSA volume in percent      mixer file (/dev/mixer)
 */
static const struct arg args[] = {
	/* function				format          argument */
	{ cpu_freq,				"CPU: %s | ",		NULL },
	{ cpu_perc,				"%s%% | ",			NULL },
	{ load_avg,				"LOAD: %s | ",		NULL },

	{ ram_used,				"RAM: %s/",			NULL },
	{ ram_total,			"%s | ",				NULL },

	{ disk_used,			"DISK: %s/",			"/" },
	{ disk_total,			"%s | ",				"/" },

	{ netspeed_rx,		"DN: %s/",				ethernet_iface },
	{ netspeed_tx,		"UP: %s | ",			ethernet_iface },

	{ datetime,				"%s ",					"%a %b %d %H:%M" },
};
