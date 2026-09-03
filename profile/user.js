// Firefox preferences for this setup.
//
// user.js is applied on every startup, which is what makes it survive Firefox
// rewriting prefs.js on exit. The flip side: values here are reasserted at each
// start, so editing them through about:config will not stick — edit this file.

// --- Required for the customization layer to load at all ---
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("userChromeJS.enabled", true);
user_pref("userChromeJS.persistent_domcontent_callback", true);
user_pref("svg.context-properties.content.enabled", true);

// --- Sidebar and vertical tabs (the whole theme is built around these) ---
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);

// --- Session ---
// Restore the previous session, and keep a deeper history of closed windows and
// tabs than the defaults of 3 and 25.
user_pref("browser.startup.page", 3);
user_pref("browser.sessionstore.max_windows_undo", 10);
user_pref("browser.sessionstore.max_tabs_undo", 50);

// --- Natsumi Browser ---
user_pref("natsumi.browser.type", "firefox");
user_pref("natsumi.glimpse.controls-on-right", false);
user_pref("natsumi.glimpse.enabled", true);
user_pref("natsumi.glimpse.multi", true);
user_pref("natsumi.home.custom-background", true);
user_pref("natsumi.miniplayer.pin-by-default", false);
user_pref("natsumi.miniplayer.scroll-view", true);
user_pref("natsumi.pip.center-scale", false);
user_pref("natsumi.pip.disable-scroll-to-move", false);
user_pref("natsumi.pip.legacy-style", true);
user_pref("natsumi.pip.material", "tinted-haze");
user_pref("natsumi.sidebar.autohide-bottom-toolbar", false);
user_pref("natsumi.sidebar.clear-keep-selected", false);
user_pref("natsumi.sidebar.clear-open-newtab", false);
user_pref("natsumi.sidebar.disable-bottom-toolbar", true);
user_pref("natsumi.startup.sound", "default");
user_pref("natsumi.tabs.disable-crossout-title", false);
user_pref("natsumi.tabs.disable-grayout-unloaded", false);
user_pref("natsumi.tabs.hide-new-tab-button", false);
user_pref("natsumi.tabs.new-tab-on-top", false);
user_pref("natsumi.tabs.pinned-tabs-width", 53);
user_pref("natsumi.tabs.pinned-type", "default");
user_pref("natsumi.tabs.pinned-use-custom-type", false);
user_pref("natsumi.tabs.replace-new-tab", false);
user_pref("natsumi.tabs.type", "clicky");
user_pref("natsumi.tabs.use-custom-type", true);
user_pref("natsumi.theme.accent-color", "system");
user_pref("natsumi.theme.browser-separation", 6);
user_pref("natsumi.theme.classic-preferences", false);
user_pref("natsumi.theme.compact-blur", false);
user_pref("natsumi.theme.compact-long-visibility", false);
user_pref("natsumi.theme.compact-marginless", false);
user_pref("natsumi.theme.compact-sidebar-accent", false);
user_pref("natsumi.theme.compact-smaller-sidebar", false);
user_pref("natsumi.theme.compact-style", "default");
user_pref("natsumi.theme.context-menu-icons", false);
user_pref("natsumi.theme.disable-browser-radius", true);
user_pref("natsumi.theme.disable-sdl2", false);
user_pref("natsumi.theme.font-size-offset", 0);
user_pref("natsumi.theme.gray-out-when-inactive", false);
user_pref("natsumi.theme.icons-alt-back-forward", false);
user_pref("natsumi.theme.icons", "default");
user_pref("natsumi.theme.no-margin", true);
user_pref("natsumi.theme.pinned-toolbar-on-top", true);
user_pref("natsumi.theme.single-toolbar", false);
user_pref("natsumi.theme.soft-glow", true);
user_pref("natsumi.theme.type", "colorful");
user_pref("natsumi.theme.use-legacy-translucency", false);
user_pref("natsumi.urlbar.do-not-float", false);
user_pref("natsumi.welcome.viewed", true);
