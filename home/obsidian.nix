# Obsidian configuration using home.file
# App installed via Homebrew cask, this manages vault configuration files
#
# Obsidian stores configuration in:
# - ~/.config/obsidian/obsidian.json (global vault registry)
# - <vault>/.obsidian/ directory containing:
#   - app.json (editor settings)
#   - appearance.json (theme, fonts, snippets)
#   - core-plugins.json (built-in plugin toggles)
#   - community-plugins.json (list of enabled community plugins)
#   - hotkeys.json (custom keybindings)
#   - graph.json (graph view settings)
#   - daily-notes.json (daily notes plugin settings)
#   - templates.json (templates plugin settings)
#   - types.json (property type definitions)
#   - plugins/<plugin-id>/ (community plugin files)
#   - snippets/ (CSS snippets)
#   - themes/ (theme files)
#
# References:
# - https://help.obsidian.md/configuration-folder
# - https://github.com/fengstats/obsidian-config/blob/main/app.json
# - https://github.com/GrangbelrLurain/.obsidian/blob/master/appearance.json
# - https://github.com/Gauthier13/obsidian-dotfiles
{ config, lib, pkgs, ... }:

let
  # Define your vault path here (relative to home directory)
  # vaultPath = "Documents/ObsidianVault";

  # =============================================================================
  # APP SETTINGS (app.json)
  # Controls editor behavior and file handling
  # =============================================================================
  appSettings = {
    # --- Editor Mode ---
    vimMode = true;
    # livePreview = true;                   # Live preview mode (WYSIWYG-ish editing)
    # defaultViewMode = "source";           # Default view: "source", "preview", or "live"
    # legacyEditor = false;                 # Use legacy CodeMirror 5 editor (deprecated)

    # --- Line Display ---
    # showLineNumber = false;               # Show line numbers in editor
    # readableLineLength = true;            # Limit line length for readability
    # showIndentGuide = true;               # Show vertical indent guides
    # strictLineBreaks = false;             # Require double newline for paragraph break
    # rightToLeft = false;                  # Right-to-left text direction

    # --- Folding ---
    # foldHeading = true;                   # Allow folding headings
    # foldIndent = true;                    # Allow folding indented content

    # --- Tab/Indent Settings ---
    useTab = false;
    tabSize = 2;

    # --- Spellcheck Settings ---
    # spellcheck = false;                   # Enable spellcheck
    # spellcheckLanguages = [ "en" ];       # Languages for spellcheck (e.g., ["en-US" "de"])

    # --- Link Settings ---
    # useMarkdownLinks = false;             # Use [text](link) format (false = [[wikilinks]])
    # alwaysUpdateLinks = true;             # Auto-update links when files move
    # newLinkFormat = "shortest";           # Link format: "shortest", "relative", "absolute"

    # --- Frontmatter/Properties ---
    # showFrontmatter = true;               # Show YAML frontmatter in reading view
    # propertiesInDocument = "visible";     # Properties display: "visible", "hidden", "source"
    # showInlineTitle = true;               # Show inline title at top of document

    # --- File Handling Settings ---
    # newFileLocation = "root";             # Where to create new files: "root", "current", "folder"
    # newFileFolderPath = "";               # Folder path when newFileLocation = "folder"
    # attachmentFolderPath = "./";          # Where to store attachments (e.g., "./attachments")
    # promptDelete = true;                  # Confirm before deleting files
    # trashOption = "system";               # Delete method: "system", "local" (.trash), "none"
    # showUnsupportedFiles = false;         # Show non-markdown files in file explorer
    # userIgnoreFilters = [];               # Folders/files to exclude from indexing

    # --- Editing Behavior ---
    # autoConvertHtml = true;               # Convert HTML to markdown on paste
    # autoPairBrackets = true;              # Auto-close brackets
    # autoPairMarkdown = true;              # Auto-close markdown syntax (**, __, etc.)
    # smartIndentList = true;               # Smart list indentation

    # --- Tab Behavior ---
    # focusNewTab = true;                   # Always focus new tabs when opened

    # --- PDF Export ---
    # pdfExportSettings = {
    #   includeName = true;                 # Include file name in PDF
    #   pageSize = "Letter";                # Page size: "Letter", "A4", etc.
    #   landscape = false;                  # Landscape orientation
    #   margin = "0";                       # Margin size
    #   downscalePercent = 100;             # Downscale percentage
    # };
  };

  # =============================================================================
  # APPEARANCE SETTINGS (appearance.json)
  # Controls visual appearance and theming
  # =============================================================================
  appearanceSettings = {
    # --- Base Theme ---
    # theme = "obsidian";                   # Base theme: "obsidian" (dark), "moonstone" (light), "system"

    # --- Font Settings ---
    # baseFontSize = 16;                    # Base font size in pixels
    # textFontFamily = "";                  # Custom text/reading font (empty = default)
    # monospaceFontFamily = "";             # Custom monospace/code font
    # interfaceFontFamily = "";             # Custom UI/interface font

    # --- Theme Settings ---
    # cssTheme = "";                        # Community theme name (must be installed)
    # accentColor = "";                     # Accent color hex code (e.g., "#7c3aed")

    # --- UI Settings ---
    # translucency = false;                 # Enable window translucency (macOS/Windows)
    # nativeMenus = true;                   # Use native OS menus
    # showViewHeader = true;                # Show header in document views
    # showRibbon = true;                    # Show left ribbon with icons
    # showInlineTitle = true;               # Show inline title in documents (also in app.json)

    # --- CSS Snippets ---
    # enabledCssSnippets = [];              # List of enabled snippet names (without .css)

    # --- Misc ---
    # baseFontSizeAction = true;            # Enable font size adjustment actions
  };

  # =============================================================================
  # CORE PLUGINS (core-plugins.json)
  # Built-in Obsidian plugins that can be toggled on/off
  # Source: home-manager module corePluginsList
  # =============================================================================
  corePlugins = {
    # --- Navigation & Search ---
    # file-explorer = true;                 # File explorer sidebar
    # global-search = true;                 # Search across vault
    # switcher = true;                      # Quick switcher (Cmd/Ctrl+O)
    # command-palette = true;               # Command palette (Cmd/Ctrl+P)
    # bookmarks = true;                     # Bookmark files and searches

    # --- Document Features ---
    # backlink = true;                      # Backlinks panel
    # outgoing-link = true;                 # Outgoing links panel
    # tag-pane = true;                      # Tags panel
    # page-preview = true;                  # Hover preview of links
    # outline = true;                       # Document outline/TOC
    # properties = true;                    # Frontmatter properties view

    # --- Editing Tools ---
    # note-composer = true;                 # Merge and extract notes
    # templates = true;                     # Insert templates
    # slash-command = true;                 # Slash commands in editor
    # footnotes = true;                     # Footnotes support

    # --- Organization ---
    # daily-notes = true;                   # Daily notes feature
    # workspaces = true;                    # Save and load workspaces
    # canvas = true;                        # Canvas visual notes
    # graph = true;                         # Graph view

    # --- Media & Import ---
    # audio-recorder = false;               # Record audio directly
    # markdown-importer = false;            # Import from other formats
    # word-count = true;                    # Word count status bar

    # --- Special ---
    # bases = false;                        # Bases (database-like feature, new)
    # random-note = false;                  # Open random note
    # zk-prefixer = false;                  # Zettelkasten prefixer
    # slides = false;                       # Presentation mode
    # webviewer = false;                    # Web viewer
    # editor-status = true;                 # Editor status bar

    # --- Sync & Publish (requires subscription) ---
    # sync = false;                         # Obsidian Sync
    # publish = false;                      # Obsidian Publish

    # --- Recovery ---
    # file-recovery = true;                 # File recovery/snapshots
  };

  # =============================================================================
  # GRAPH SETTINGS (graph.json)
  # Controls the graph view appearance and behavior
  # =============================================================================
  graphSettings = {
    # --- Filters ---
    # collapse-filter = false;              # Collapse filter section
    # search = "";                          # Search filter query
    # showTags = true;                      # Show tags in graph
    # showAttachments = true;               # Show attachment nodes
    # hideUnresolved = true;                # Hide unresolved links
    # showOrphans = true;                   # Show orphan notes

    # --- Color Groups ---
    # collapse-color-groups = true;         # Collapse color groups section
    # colorGroups = [];                     # List of color group definitions

    # --- Display ---
    # collapse-display = false;             # Collapse display section
    # showArrow = false;                    # Show arrows on links
    # textFadeMultiplier = 0;               # Text fade multiplier (0-1)
    # nodeSizeMultiplier = 1;               # Node size multiplier
    # lineSizeMultiplier = 1;               # Line size multiplier

    # --- Forces (physics simulation) ---
    # collapse-forces = false;              # Collapse forces section
    # centerStrength = 0.5;                 # Center attraction strength
    # repelStrength = 10;                   # Node repel strength
    # linkStrength = 1;                     # Link strength
    # linkDistance = 250;                   # Link distance

    # --- View State ---
    # scale = 1;                            # Zoom scale
    # close = true;                         # Close settings panel
  };

  # =============================================================================
  # DAILY NOTES SETTINGS (daily-notes.json)
  # Core plugin settings for daily notes
  # =============================================================================
  dailyNotesSettings = {
    # folder = "";                          # Folder for daily notes (e.g., "Journal/Daily")
    # format = "YYYY-MM-DD";                # Date format (moment.js format)
    # template = "";                        # Path to template file
    # autorun = false;                      # Open daily note on startup
  };

  # =============================================================================
  # TEMPLATES SETTINGS (templates.json)
  # Core plugin settings for templates
  # =============================================================================
  templatesSettings = {
    # folder = "";                          # Folder containing templates
    # dateFormat = "YYYY-MM-DD";            # Date format for {{date}}
    # timeFormat = "HH:mm";                 # Time format for {{time}}
  };

  # =============================================================================
  # PROPERTY TYPES (types.json)
  # Define custom property types for frontmatter
  # =============================================================================
  typesSettings = {
    # types = {
    #   aliases = "aliases";                # Built-in aliases type
    #   tags = "tags";                      # Built-in tags type
    #   cssclasses = "multitext";           # CSS classes as multitext
    #   # Custom properties:
    #   # status = "text";                  # text, number, checkbox, date, datetime
    #   # priority = "number";
    #   # completed = "checkbox";
    #   # due = "date";
    # };
  };

  # =============================================================================
  # HOTKEYS (hotkeys.json)
  # Custom keyboard shortcuts
  # Format: { "command-id" = [{ modifiers = ["Mod" "Shift"]; key = "p"; }]; }
  # Modifiers: "Mod" (Cmd/Ctrl), "Ctrl", "Meta", "Shift", "Alt"
  # =============================================================================
  hotkeys = {
    # Example: custom shortcuts
    # "editor:toggle-source" = [{ modifiers = [ "Mod" ]; key = "e"; }];
    # "workspace:split-vertical" = [{ modifiers = [ "Mod" "Shift" ]; key = "v"; }];
    # "workspace:split-horizontal" = [{ modifiers = [ "Mod" "Shift" ]; key = "h"; }];
    # "app:go-back" = [{ modifiers = [ "Mod" ]; key = "["; }];
    # "app:go-forward" = [{ modifiers = [ "Mod" ]; key = "]"; }];
  };

  # =============================================================================
  # COMMUNITY PLUGINS (community-plugins.json)
  # List of plugin IDs to enable (plugins must be installed separately)
  # =============================================================================
  # communityPlugins = [
  #   "obsidian-git"                        # Git integration
  #   "obsidian-linter"                     # Markdown linter
  #   "dataview"                            # Database-like queries
  #   "templater-obsidian"                  # Advanced templates
  #   "obsidian-kanban"                     # Kanban boards
  #   "calendar"                            # Calendar view
  #   "obsidian-tasks-plugin"               # Task management
  #   "obsidian-excalidraw-plugin"          # Excalidraw drawings
  #   "obsidian-style-settings"             # CSS variable customization
  #   "omnisearch"                          # Enhanced search
  # ];
  vaultPaths = config.flags.obsidian.vaultPaths;

  appJson = builtins.toJSON appSettings;

  mkVaultFiles = vault: {
    "${vault}/.obsidian/app.json".text = appJson;
    # "${vault}/.obsidian/appearance.json".text = builtins.toJSON appearanceSettings;
    # "${vault}/.obsidian/core-plugins.json".text = builtins.toJSON corePlugins;
    # "${vault}/.obsidian/graph.json".text = builtins.toJSON graphSettings;
    # "${vault}/.obsidian/daily-notes.json".text = builtins.toJSON dailyNotesSettings;
    # "${vault}/.obsidian/templates.json".text = builtins.toJSON templatesSettings;
    # "${vault}/.obsidian/types.json".text = builtins.toJSON typesSettings;
    # "${vault}/.obsidian/hotkeys.json".text = builtins.toJSON hotkeys;
    # "${vault}/.obsidian/community-plugins.json".text = builtins.toJSON communityPlugins;
    # "${vault}/.obsidian/snippets/custom.css".text = ''
    #   /* Custom CSS */
    #   .markdown-preview-view {
    #     font-size: 18px;
    #   }
    # '';
  };
in
{
  home.file = lib.mkMerge (map mkVaultFiles vaultPaths);
}
