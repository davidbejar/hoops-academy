/// Records the last URL instead of navigating (tests / non-web builds).
Uri? lastEndSessionRedirect;

void redirectBrowserTo(Uri url) => lastEndSessionRedirect = url;
