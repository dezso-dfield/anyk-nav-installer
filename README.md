# ányk-nav-installer

> **This is not the ÁNYK software itself.**
> ÁNYK (AbevJava) is the **official Hungarian tax form application published by NAV** (Nemzeti Adó- és Vámhivatal — the Hungarian Tax and Customs Authority). This repo contains only an **unofficial installer wrapper** that automates the setup steps needed to get NAV's software running correctly on macOS and Windows.
> The software is downloaded directly from `nav.gov.hu` at install time. Nothing in this repo modifies the application itself.

---

**One-click setup wrapper for ÁNYK (AbevJava) on macOS and Windows.**
Automatically installs the correct Java version, downloads the latest official installer directly from NAV's servers, patches the Apple Silicon compatibility bug, and drops a ready-to-use launcher on your Desktop.

---

## Background — Why this exists

ÁNYK (*Általános Nyomtatványkitöltő*) is the **official Hungarian government tax form software**, published and maintained by NAV (Nemzeti Adó- és Vámhivatal). It is a Java-based desktop application distributed as a JAR installer (`abevjava_install.jar`) and is required for filing certain tax documents in Hungary.

This repo does not host or redistribute the ÁNYK software. It downloads the official installer directly from NAV's own servers (`nav.gov.hu`) the same way you would manually.

Getting it running on a modern Mac — especially Apple Silicon (M1/M2/M3/M4) — involves a chain of non-obvious problems that this installer solves automatically:

### Problem 1 — Wrong install directory

The ÁNYK installer defaults to `/usr/share/abevjava` as its target directory. On macOS, `/usr/share` is a system-protected path that requires root access. The installer silently fails with:

```
Hiba a könyvtár létrehozása során: /usr/share/abevjava
```

**Fix:** The user is guided to change the directory to `~/abevjava` (their home folder), where they have full write permissions.

### Problem 2 — Java version incompatibility

Modern Macs ship with no Java, and if developers have installed Java via Homebrew or other means they typically get Java 17, 21, or 23. ÁNYK requires **Java 8** — the `java.se.ee` module it depends on was removed from Java in version 9.

Running with the wrong Java produces:

```
Error occurred during initialization of boot layer
java.lang.module.FindException: Module java.se.ee not found
```

**Fix:** The installer installs **Azul Zulu JDK 8**, which has native Apple Silicon (ARM64) support — unlike Oracle JDK 8 which is Intel-only.

### Problem 3 — `JAVA_HOME_ABEV` not set in `setenv`

Even after installing Java 8, the ÁNYK launch script (`abevjava_start`) sources a `setenv` file and then invokes `"$JAVA_HOME_ABEV"java`. If `JAVA_HOME_ABEV` is not set, the shell falls back to the system `java` — which is the wrong version.

The `setenv` file shipped by NAV does **not** set this variable on macOS. It only sets:

```sh
MEMORY_OPTS="-Xms128m -Xmx256m"
TUNING_OPTS=
XML_OPTS=-DentityExpansionLimit=128000
```

**Fix:** After installation, the script automatically appends the correct path to `setenv`:

```sh
JAVA_HOME_ABEV="/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home/bin/"
```

It reads the actual install path from `~/.abevjava/abevjavapath.cfg` (written by the ÁNYK installer itself) so the fix works regardless of where the user chose to install.

---

## What the installers do

Both scripts perform the same logical steps end-to-end:

| Step | macOS | Windows |
|------|-------|---------|
| 0 | Request `sudo` once upfront, keep alive for entire session | Auto-elevate via UAC (`Start-Process -Verb RunAs`) |
| 1 | Check/install Homebrew | — |
| 2 | Check/install Azul Zulu JDK 8 (ARM64-native) via `brew install --cask zulu@8` | Check/install Zulu JDK 8 via `winget` or direct MSI download |
| 3 | Download `abevjava_install.jar` from `nav.gov.hu` | Same |
| 4 | Run the JAR installer with Java 8 explicitly | Same |
| 5 | Read install path from `~/.abevjava/abevjavapath.cfg`, patch `setenv` with `JAVA_HOME_ABEV` | Create desktop launcher |
| 6 | Create `~/Desktop/ÁNYK - NAV.command` launcher | Create `ÁNYK - NAV.lnk` desktop shortcut |

---

## Requirements

### macOS
- macOS 11 Big Sur or later (Intel or Apple Silicon)
- Internet connection
- No pre-existing Java or Homebrew required — the script installs what's needed

### Windows
- Windows 10 or Windows 11 (64-bit)
- Internet connection
- PowerShell 5+ (included in all supported Windows versions)

---

## Usage

### macOS

1. Download `install_abevjava_mac.command`
2. Double-click it in Finder
3. If macOS blocks it: right-click → **Open** → **Open Anyway**
4. Enter your password once when prompted
5. When the ÁNYK installer GUI opens, set the directory to:
   ```
   /Users/YOUR_USERNAME/abevjava
   ```
6. Click **Tovább** → **Befejez**
7. The script patches the config and creates `ÁNYK - NAV.command` on your Desktop

After installation, launch ÁNYK by double-clicking **ÁNYK - NAV.command** on your Desktop, or from Terminal:

```bash
cd ~/abevjava && ./abevjava_start
```

### Windows

1. Download `install_abevjava_windows.bat`
2. Double-click it — it will automatically re-launch itself as Administrator
3. Click **Yes** on the UAC prompt
4. When the ÁNYK installer GUI opens, set the directory to:
   ```
   C:\Users\YOUR_USERNAME\abevjava
   ```
5. Click **Tovább** → **Befejez**
6. An **ÁNYK - NAV** shortcut is created on your Desktop

---

## File structure after install

```
~/abevjava/
├── abevjava_start       # Main launch script (macOS/Linux)
├── abevjava_start.bat   # Main launch script (Windows)
├── abevjava.jar         # Main application
├── boot.jar             # Boot loader
├── setenv               # Environment config (patched by this installer)
├── cfg.enyk             # ÁNYK config
├── nyomtatvanyok/       # Downloaded form templates
└── lib/                 # Java libraries
```

---

## Troubleshooting

**"damaged or can't be opened" on macOS**
```bash
xattr -dr com.apple.quarantine ~/Downloads/install_abevjava_mac.command
```

**App still uses wrong Java after install**
Check that `setenv` contains the `JAVA_HOME_ABEV` line:
```bash
grep JAVA_HOME_ABEV ~/abevjava/setenv
```
If missing, run:
```bash
echo "JAVA_HOME_ABEV=\"$(/usr/libexec/java_home -v 1.8)/bin/\"" >> ~/abevjava/setenv
```

**Download fails (NAV server unreachable)**
The NAV download server can occasionally be slow or unavailable. Wait a few minutes and try again. You can also download the JAR manually from [nav.gov.hu](https://nav.gov.hu/nyomtatványok/letöltések) and run:
```bash
cd ~/abevjava && JAVA_HOME=$(/usr/libexec/java_home -v 1.8) ./abevjava_start
```

**Java 8 not found after Zulu install (macOS)**
```bash
/usr/libexec/java_home -v 1.8
```
If this returns nothing, try:
```bash
brew reinstall --cask zulu@8
```

---

## Technical notes

- The ÁNYK download endpoint does not include a filename in its `Content-Disposition` header, so the JAR is saved to `/tmp/abevjava_install.jar` and cleaned up after installation.
- The `sudo` keepalive on macOS works by running `sudo -n true` every 50 seconds in a background subshell. The PID is captured and killed via `trap ... EXIT` so it is always cleaned up.
- On Windows, the batch file uses `Start-Process -Verb RunAs` to re-invoke itself elevated. The first invocation exits immediately after triggering the elevated copy — there is no visible double-window.
- Zulu JDK 8 was chosen over Oracle JDK 8 specifically because Oracle's JDK 8 does not provide ARM64 native binaries. Zulu 8 is fully ARM64-native and passes all ÁNYK compatibility checks.

---

## License

MIT — see [LICENSE](LICENSE).
This project is not affiliated with or endorsed by NAV or Azul Systems.

---

## Contributing

Pull requests welcome. If NAV changes their download URL or the ÁNYK installer behaviour changes in a future release, please open an issue.
