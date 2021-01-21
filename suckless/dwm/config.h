/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx	= 0;	/* border pixel of windows */
static const unsigned int snap		= 32;	/* snap pixel */
static const int showbar		= 1;	/* 0 means no bar */
static const int topbar			= 1;	/* 0 means bottom bar */
static const char *fonts[]		= { "Hack Nerd Font:size=9" };
static const char dmenufont[]		= "Hack Nerd Font:size=9";
static const char col_gray1[]		= "#222222";
static const char col_gray2[]		= "#444444";
static const char col_gray3[]		= "#bbbbbb";
static const char col_gray4[]		= "#eeeeee";
/* static const char col_cyan[] 	= "#005577"; */
static const char col_cyan[]		= "#585858";
static const char *colors[][3]		= {
	/*		     fg		bg	   border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class	  instance    title	  tags mask	isfloating   monitor */
	{ "Google-chrome",	NULL,	     NULL,	 1 << 1,       0,	    -1 },
	{ "Chromium",		NULL,	     NULL,	 1 << 1,       0,	    -1 },
	{ "Signal",		NULL,	     NULL,	 1 << 2,       0,	    -1 },
	{ "ViberPC",		NULL,	     NULL,	 1 << 2,       0,	    -1 },
};

/* layout(s) */
static const float mfact	= 0.5;	/* factor of master area size [0.05..0.95] */
static const int nmaster	= 1;	/* number of clients in master area */
static const int resizehints	= 0;	/* 1 means respect size hints in tiled resizals */

static const Layout layouts[] = {
	/* symbol	  arrange function */
	{ "[M]",	  monocle },
	{ "[]=",	  tile },    /* first entry is default */
	{ "><>",	  NULL },    /* no layout function means floating behavior */
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,			KEY,      view,		{.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,		KEY,      toggleview,	{.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,		KEY,      tag,		{.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,	{.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[]	= { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]	= { "st", NULL };

static const char *slockcmd[]		= { "slock", NULL };

static const char *volumedowncmd[]	= { "pamixer", "-d", "5", NULL };
static const char *volumeupcmd[]	= { "pamixer", "-i", "5", NULL };
static const char *volumezerocmd[]	= { "pamixer", "--set-volume", "0", NULL };

static const char *monbrghtnssdowncmd[] = { "brightnessctl", "--device=amdgpu_bl0",	"set", "10%-", NULL };
static const char *monbrghtnssupcmd[]	= { "brightnessctl", "--device=amdgpu_bl0",	"set", "+10%", NULL };

static const char *kbdbrghtnssdowncmd[] = { "brightnessctl", "--device=tpacpi::kbd_backlight", "set", "10%-", NULL };
static const char *kbdbrghtnssupcmd[]	= { "brightnessctl", "--device=tpacpi::kbd_backlight", "set", "+10%", NULL };

static Key keys[] = {
	/* modifier				key				function	argument */
	{ MODKEY,				XK_p,				spawn,		{.v = dmenucmd } },
	{ MODKEY|ShiftMask,			XK_Return,			spawn,		{.v = termcmd } },
	{ MODKEY,				XK_b,				togglebar,	{0} },
	{ MODKEY,				XK_j,				focusstack,	{.i = +1 } },
	{ MODKEY,				XK_k,				focusstack,	{.i = -1 } },
	{ MODKEY,				XK_i,				incnmaster,	{.i = +1 } },
	{ MODKEY,				XK_d,				incnmaster,	{.i = -1 } },
	{ MODKEY,				XK_h,				setmfact,	{.f = -0.05} },
	{ MODKEY,				XK_l,				setmfact,	{.f = +0.05} },
	{ MODKEY,				XK_Return,			zoom,		{0} },
	{ Mod1Mask,				XK_Tab,				view,		{0} },
	{ MODKEY|ShiftMask,			XK_c,				killclient,	{0} },
	{ MODKEY,				XK_m,				setlayout,	{.v = &layouts[0]} },
	{ MODKEY,				XK_t,				setlayout,	{.v = &layouts[1]} },
	{ MODKEY,				XK_f,				setlayout,	{.v = &layouts[2]} },
	{ MODKEY,				XK_space,			setlayout,	{0} },
	{ MODKEY|ShiftMask,			XK_space,			togglefloating,	{0} },
	{ MODKEY,				XK_0,				view,		{.ui = ~0 } },
	{ MODKEY|ShiftMask,			XK_0,				tag,		{.ui = ~0 } },
	{ MODKEY,				XK_comma,			focusmon,	{.i = -1 } },
	{ MODKEY,				XK_period,			focusmon,	{.i = +1 } },
	{ MODKEY|ShiftMask,			XK_comma,			tagmon,		{.i = -1 } },
	{ MODKEY|ShiftMask,			XK_period,			tagmon,		{.i = +1 } },
	TAGKEYS(				XK_1,						0)
	TAGKEYS(				XK_2,						1)
	TAGKEYS(				XK_3,						2)
	TAGKEYS(				XK_4,						3)
	TAGKEYS(				XK_5,						4)
	TAGKEYS(				XK_6,						5)
	TAGKEYS(				XK_7,						6)
	TAGKEYS(				XK_8,						7)
	TAGKEYS(				XK_9,						8)
	{ MODKEY|ShiftMask,			XK_q,				quit,		{0} },

	{ MODKEY|ShiftMask,			XK_l,				spawn,		{.v = slockcmd } },
	
	{ Mod1Mask|ControlMask|ShiftMask,	XK_4,				spawn,		SHCMD("maim -s | xclip -sel c -t image/png") },

	{ 0,					XF86XK_MonBrightnessUp,		spawn,		{.v = monbrghtnssupcmd } },
	{ 0,					XF86XK_MonBrightnessDown,	spawn,		{.v = monbrghtnssdowncmd } },

	{ 0,					XF86XK_KbdBrightnessUp,		spawn,		{.v = kbdbrghtnssupcmd } },
	{ 0,					XF86XK_KbdBrightnessDown,	spawn,		{.v = kbdbrghtnssdowncmd } },

	{ 0,					XF86XK_AudioLowerVolume,	spawn,		{.v = volumedowncmd } },
	{ 0,					XF86XK_AudioRaiseVolume,	spawn,		{.v = volumeupcmd } },
	{ 0,					XF86XK_AudioMute,		spawn,		{.v = volumezerocmd } },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click		event mask	    button	    function	    argument */
	{ ClkLtSymbol,		0,		Button1,	setlayout,	{0} },
	{ ClkLtSymbol,		0,		Button3,	setlayout,	{.v = &layouts[2]} },
	// this is commented out due to notitle patch
	/* { ClkWinTitle,		0,		Button2,	zoom,		{0} }, */
	{ ClkStatusText,	0,		Button2,	spawn,		{.v = termcmd } },
	{ ClkClientWin,		MODKEY,		Button1,	movemouse,	{0} },
	{ ClkClientWin,		MODKEY,		Button2,	togglefloating,	{0} },
	{ ClkClientWin,		MODKEY,		Button3,	resizemouse,	{0} },
	{ ClkTagBar,		0,     		Button1,	view,		{0} },
	{ ClkTagBar,		0,     		Button3,	toggleview,	{0} },
	{ ClkTagBar,		MODKEY,		Button1,	tag,		{0} },
	{ ClkTagBar,		MODKEY,		Button3,	toggletag,	{0} },
};
