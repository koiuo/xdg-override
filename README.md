# xdg-override

Override `xdg-open` behavior. Because the way it already works is not confusing enough.

> [How do you change browser in Slack anyway?][blog]

## What is `xdg-open` and what `xdg-override` does?

`xdg-open` is a GNU/Linux application that "opens" files and URLs in user's preferred application:

For example, open `avatar.png` in the default image viewer
```
~ ❯ xdg-open avatar.png
```

Or open `https://freedesktop.org` URL in the default browser
```
~ ❯ xdg-open "https://freedesktop.org"
```

Most application on GNU/Linux by convention delegate to `xdg-open` when they need to open a file or a URL. This ensures consistent behavior between applications and desktop environments: URLs are always opened in our preferred browser, images are always opened in the same preferred viewer.

However, there are situations when this consistent behavior is not desired: for example, if we need to override default browser just for one application and only temporarily. This is where `xdg-override` helps: it replaces `xdg-open` with itself to alter the behavior without changing system settings.

For example, if our default browser is Firefox, and we want Chromium to be our default browser in Slack messanger, we can launch Slack like this:
```
~ ❯ xdg-override --match "^https?://" chromium slack
```

## How does it work?

Two words: `PATH` manipulation.

You can read the explanation of how `xdg-override` works and about my motivation in my blog post [How do you change browser in Slack anyway?][blog]

## Installation and running

If you use Nix, you can install `xdg-override` from the flake, or you can try it without installation like this 

```
~ ❯ nix run github:koiuo/xdg-override -- --match "^https://" chromium slack
```

For everyone else, place the script anywhere you wish and execute it from there. It does not require any configs, and it only creates some temporary files under `/tmp`.

## Usage

```
~ ❯ xdg-override --help
xdg-override [options...] <app>
  -h, --help
      Show command synopsis.
  -m <regex> <command>, --match <regex> <command>
      Override handling of specific mimetype

Examples

  xdg-override -m "^https?://.*\.youtube.com/" mpv -m "^https?://" firefox thunderbird

Launches thunderbird and
- forces all youtube.com URLs to open in mpv
- forces all other URLs to opened in firefox
```

On top of the script, the flake offers a few library functions to be used in NixOS or home-manager config

`proxyPkg` generates a package which can be installed to the profile to globally override `xdg-open` behavior:

``` Nix
customXdgOpen = xdg-override.lib.proxyPkg { 
  inherit pkgs; 
  nameMatch = [
    { case = "^https?://.*\.youtube.com/"; command = "mpv"; }
    { case = "^https?://open.spotify.com/"; command = "spotify-open"; }
  ];
};

home.packages = [
    ...
    customXdgOpen
    ...
]
```

`wrapPackage` wraps a single package and alters `xdg-open` behavior just for that single application:

``` Nix
customSlack = (xdg-override.lib.wrapPackage { 
  nameMatch = [
    { case = "^https?://open.spotify.com/"; command = "spotify-open"; }
    { case = "^https?://"; command = "firefox"; }
  ];
} pkgs.slack);

home.packages = [
    ...
    customSlack
    ...
]
```

## Further development

The script is more than sufficient for my needs and I don't plan to add new features to it. Nix library might see some improvements, and as an excercise I might do some polishing and automated testing.

That said, don't hesitate to open an issue if you miss something or have a cool idea.

[blog]: https://127001.me/change-browser-in-slack/
