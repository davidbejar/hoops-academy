// Hoops Academy login theme: the look chosen in the app (ADR-0022 amendment).
//
// keycloak.v2 follows the browser's dark mode (darkMode=true in theme.properties).
// The app has its own choice (light, dark or system), kept in the app's storage on
// another origin, so the app sends it with the sign-in request as `hoops_theme`.
// This script applies it and keeps it for the follow-up pages of the same sign-in
// (wrong password, new password), whose addresses no longer carry the parameter.
//
// Rules
//  - only the two literal values light and dark are ever applied; `system`, a
//    missing or any other value follows the browser, as before;
//  - nothing read from the address is written into the page: the value only
//    decides whether one fixed class is on <html>;
//  - sessionStorage of this tab only; no cookie, nothing kept after the tab closes.
(function () {
  'use strict';

  var PARAMETER = 'hoops_theme';
  var STORAGE_KEY = 'hoops.loginTheme';
  var DARK_CLASS = 'pf-v5-theme-dark';

  function known(value) {
    return value === 'light' || value === 'dark' ? value : null;
  }

  function chosen() {
    try {
      var sent = new URLSearchParams(window.location.search).get(PARAMETER);
      if (sent === null) return known(window.sessionStorage.getItem(STORAGE_KEY));
      var theme = known(sent);
      if (theme) window.sessionStorage.setItem(STORAGE_KEY, theme);
      else window.sessionStorage.removeItem(STORAGE_KEY);
      return theme;
    } catch (e) {
      // Storage blocked: follow the browser.
      return null;
    }
  }

  var theme = chosen();
  if (!theme) return;

  var root = document.documentElement;
  function apply() {
    var dark = theme === 'dark';
    if (root.classList.contains(DARK_CLASS) !== dark) root.classList.toggle(DARK_CLASS, dark);
  }

  apply();
  // keycloak.v2's own script sets the class from the browser's preference, at
  // load and whenever that preference changes: hold the chosen look against it.
  new MutationObserver(apply).observe(root, { attributes: true, attributeFilter: ['class'] });
})();
