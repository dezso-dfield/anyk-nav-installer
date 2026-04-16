# ányk-nav-installer

> **This is not the ÁNYK software itself.**
> ÁNYK (AbevJava) is the **official Hungarian tax form application published by NAV** (Nemzeti Adó- és Vámhivatal). This repo contains only an **unofficial installer wrapper** that automates the setup steps on macOS, Windows, and Linux.
> The software is downloaded directly from `nav.gov.hu` at install time. Nothing here modifies the application itself.

**One-click setup for ÁNYK on macOS, Windows, and Linux.**
Handles Java 8 installation, downloads the official NAV installer, patches a known Apple Silicon compatibility bug, and creates a desktop launcher — automatically.

---

## Download

👉 **[Latest Release](https://github.com/dezso-dfield/anyk-nav-installer/releases/latest)**

| Platform | File |
|----------|------|
| macOS (Apple Silicon + Intel) | `anyk-nav-installer-mac-vX.X.X.zip` |
| Windows 10 / 11 | `anyk-nav-installer-windows-vX.X.X.zip` |
| Linux (x86_64 + ARM64) | `anyk-nav-installer-linux-vX.X.X.zip` |
| All platforms | `anyk-nav-installer-all-platforms-vX.X.X.zip` |

---

## Quick Start

### macOS
1. Download and unzip `anyk-nav-installer-mac-vX.X.X.zip`
2. Double-click **`anyk_manager.command`**
3. If macOS blocks it: right-click → **Open** → **Open Anyway**
4. Enter your password once — the rest is automatic

### Windows
1. Download and unzip `anyk-nav-installer-windows-vX.X.X.zip`
2. Double-click **`anyk_manager.bat`**
3. Click **Yes** on the UAC prompt — it auto-elevates once

### Linux
1. Download and unzip `anyk-nav-installer-linux-vX.X.X.zip`
2. Run:
```bash
chmod +x anyk_manager.sh && ./anyk_manager.sh
```

> All three managers show a menu: **Install / Update / Uninstall / Launch**

---

## Repository Structure

```
anyk-nav-installer/
│
├── mac/
│   ├── anyk_manager.command   ← Start here on macOS (GUI menu)
│   ├── install.command
│   ├── update.command
│   └── uninstall.command
│
├── windows/
│   ├── anyk_manager.bat       ← Start here on Windows (GUI menu)
│   ├── install.bat
│   ├── update.bat
│   └── uninstall.bat
│
├── linux/
│   ├── anyk_manager.sh        ← Start here on Linux (GUI or terminal menu)
│   ├── install.sh
│   ├── update.sh
│   └── uninstall.sh
│
├── .github/
│   └── workflows/
│       └── release.yml        ← Auto-builds + publishes releases on git tag push
│
├── README.md
└── LICENSE
```

---

## What Each Script Does

### Manager (`anyk_manager`)
Opens a GUI menu (native AppleScript on Mac, PowerShell Forms on Windows, zenity on Linux with terminal fallback). Dispatches to the sub-scripts below.

### Install (`install`)
1. Requests admin/sudo upfront — once, no re-prompts
2. **macOS only:** Installs Homebrew if missing
3. Installs **Azul Zulu JDK 8** — the only Java 8 with native Apple Silicon (ARM64) support
4. Downloads the official ÁNYK installer directly from `nav.gov.hu`
5. Runs the installer GUI (you set the directory, click Next)
6. **Auto-patches `setenv`** with the correct `JAVA_HOME_ABEV` path (see [Why this exists](#why-this-exists))
7. Creates a desktop launcher named **ÁNYK - NAV**

### Update (`update`)
1. Backs up your forms and saved data (`nyomtatvanyok`, `mentesek`, `beallitasok`)
2. Runs the built-in `abevjava_update` if present, otherwise re-downloads from NAV
3. Restores your backed-up data
4. Re-applies the `setenv` fix (update can overwrite it)

### Uninstall (`uninstall`)
1. Confirms before deleting anything
2. Removes the install directory, config folder, and desktop launcher
3. Optionally removes Zulu JDK 8

---

## Why This Exists

Getting ÁNYK running on a modern Mac involves three non-obvious bugs that produce cryptic errors:

### Bug 1 — Wrong install directory

The installer defaults to `/usr/share/abevjava`. macOS has blocked writes to `/usr/share` for years. The installer fails silently with:
```
Hiba a könyvtár létrehozása során: /usr/share/abevjava
```
**Fix:** Install to `~/abevjava` instead.

### Bug 2 — Wrong Java version

ÁNYK requires Java 8. The `java.se.ee` module it depends on was removed in Java 9. Running any newer Java produces:
```
Error occurred during initialization of boot layer
java.lang.module.FindException: Module java.se.ee not found
```
**Fix:** Install Azul Zulu JDK 8 — the only Java 8 distribution with native ARM64 (Apple Silicon) support.

### Bug 3 — `JAVA_HOME_ABEV` not set

Even with Java 8 installed, the launch script (`abevjava_start`) calls `"$JAVA_HOME_ABEV"java`. NAV's own `setenv` file never sets this variable on macOS or Linux, so the script falls back to system Java (wrong version) and fails again.

The shipped `setenv` contains only:
```sh
MEMORY_OPTS="-Xms128m -Xmx256m"
TUNING_OPTS=
XML_OPTS=-DentityExpansionLimit=128000
```

**Fix:** After installation, automatically append to `setenv`:
```sh
JAVA_HOME_ABEV="/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home/bin/"
```
The install path is read from `~/.abevjava/abevjavapath.cfg` (written by the ÁNYK installer itself) so it works regardless of where you chose to install.

---

## Creating a Release

Releases are fully automated via GitHub Actions. To publish a new version:

```bash
# Tag the commit with a semantic version
git tag v1.0.0
git push origin v1.0.0
```

That's it. The workflow in `.github/workflows/release.yml` will:
1. Build four zip archives (mac, windows, linux, all-platforms)
2. Generate release notes automatically
3. Publish a GitHub Release with all four archives attached

**Pre-release tags** (`-beta`, `-rc`) are automatically marked as pre-release:
```bash
git tag v1.1.0-beta && git push origin v1.1.0-beta
```

---

## Requirements

| Platform | Requirements |
|----------|-------------|
| macOS | macOS 11+ (Intel or Apple Silicon). Nothing else needed — the script installs everything. |
| Windows | Windows 10 / 11 (64-bit). PowerShell 5+ (built-in). |
| Linux | Any distro with `curl` and `tar`. `zenity` optional for GUI. |

---

## Troubleshooting

**macOS — "damaged or can't be opened"**
```bash
xattr -dr com.apple.quarantine ~/Downloads/anyk-nav-installer-mac-*/
```

**setenv not patched after install**
```bash
echo "JAVA_HOME_ABEV=\"$(/usr/libexec/java_home -v 1.8)/bin/\"" >> ~/abevjava/setenv
```

**NAV download fails**
The NAV server is occasionally slow. Wait a few minutes and retry. You can also download the JAR manually from [nav.gov.hu](https://nav.gov.hu) and run the installer with:
```bash
cd ~/abevjava && ./abevjava_start
```

**Java 8 not found after install (macOS)**
```bash
brew reinstall --cask zulu@8
```

---

## License

MIT — see [LICENSE](LICENSE).

Not affiliated with or endorsed by NAV (Nemzeti Adó- és Vámhivatal) or Azul Systems.
ÁNYK and AbevJava are trademarks of their respective owners.
