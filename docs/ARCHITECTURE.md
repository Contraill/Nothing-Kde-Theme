# What the installer changes, and how it comes back

Nothing KDE runs no daemon of its own: it installs Plasma packages and writes settings, and
every change has its way back. Most of it stays in your account; three optional parts need
the administrator password once.

```mermaid
flowchart LR
    install(["./install.sh"])
    uninstall(["./uninstall.sh"])

    subgraph account["Your account: ~/.config, ~/.local/share"]
        packages["Plasma packages<br/>island and dock, 19 widgets, global themes,<br/>Plasma style, colour schemes"]
        layout["Panel layout<br/>plasma-org.kde.plasma.desktop-appletsrc"]
        glassy["Glassy<br/>kdeglobals widget style, kwinrc decoration and blur,<br/>~/.config/Kvantum/Glassy"]
        notify["Notification look<br/>a user copy of Plasma's notifications applet"]
        sounds["Sound theme<br/>~/.local/share/sounds"]
        links["Accent links<br/>Kitty; on request Starship, Fastfetch,<br/>GTK 4, Dolphin"]
    end

    subgraph system["System, through pkexec"]
        boot["Boot animation<br/>Plymouth theme, initramfs"]
        login["Login wallpaper<br/>/etc/plasmalogin.conf.d drop-in"]
        camera["Camera helper<br/>/usr/local/libexec, polkit rule"]
    end

    subgraph kept["Where the previous state is kept"]
        backups["~/.local/share/nothing-plasma/backups<br/>(copied to nothing-kde-backups on uninstall)"]
        journal["~/.config/nothing-kde<br/>state.json: earlier values and file hashes"]
        previous["the earlier Plymouth theme;<br/>/etc/plasmalogin.conf left as it was"]
    end

    install --> packages & glassy & notify & sounds & links
    install -->|"--apply-layout"| layout
    install -->|"--boot-splash, --login-wallpaper,<br/>--privacy-helper install"| system

    layout & notify --> backups
    glassy & links --> journal
    boot & login --> previous

    uninstall -.->|"undoes each, in reverse"| account & system
```

| Change | Undo on its own | The earlier state |
| --- | --- | --- |
| Plasma packages, colour schemes | `./uninstall.sh` | nothing replaced; only our own files |
| Panel layout | restore `plasma-org.kde.plasma.desktop-appletsrc` from the backup | `nothing-plasma/backups/layout-*` |
| Glassy | `./install.sh --appearance disable` | previous style, decoration and blur in `nothing-kde/appearance/state.json` |
| Notification look | `./notification-skin/rollback-native.sh` | `nothing-plasma/backups/native-notifications-*` |
| Sound theme | `./install.sh --sounds use default` | chosen only when no other theme was |
| Accent links, Dolphin | `--accent-links disable all`, `--dolphin restore` | `nothing-kde/accent-links`, `nothing-kde/dolphin` |
| Kitty | `./install.sh --kitty-theme disable` | `nothing-kde/kitty-theme/state.json` |
| Boot animation | `./install.sh --boot-splash remove` | the earlier Plymouth theme, initramfs rebuilt |
| Login wallpaper | `./install.sh --login-wallpaper remove` | `/etc/plasmalogin.conf` is never edited |
| Camera helper | `./install.sh --privacy-helper remove` | nothing replaced |

Three rules hold throughout:

- **Owned files only.** What Glassy, the login wallpaper, Kitty and Dolphin write is recorded
  with its hash; a file you edited afterwards is kept and reported, never overwritten or
  removed. The accent links back up each file before they change it.
- **Packages stay.** On Arch, Glassy installs Kvantum or Aurorae through pacman only when
  missing; elsewhere it takes what is installed, and without them the rest installs without
  Glassy. No step ever removes a package.
- **Uninstall stops when it must.** It refuses to run while the command-line ALSA microphone
  block is on, since the helper that lifts it is removed with the rest.
