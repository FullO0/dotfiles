// Common base preferences for all Firefox profiles
// Generated for .dotfiles Firefox framework

// Enable custom CSS stylesheets (userChrome.css & userContent.css)
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Enable compact density mode option in UI customization
user_pref("browser.compactmode.show", true);

// Performance & GPU Acceleration
user_pref("layers.acceleration.force-enabled", true);
user_pref("gfx.webrender.all", true);
user_pref("general.smoothScroll", true);

// Privacy & Telemetry Hardening
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("experiments.activeExperiment", false);
user_pref("experiments.supported", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);

// Disable Pocket & Sponsored Shortcuts on New Tab
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
