# Installing NitroWebExpress on a server that already runs other sites

This guide is for an Ubuntu server (22.04 or 24.04) that already hosts several
projects behind Apache2 and Tomcat. The installer, `bash/NWE.ubuntu-install.sh`,
is built to add NitroWebExpress (NWE) next to them without changing what they do.
Plain first-time setup on an empty machine is in `INSTALL.readme`.

NWE has two parts. You can install either or both:

| Part | What it is | Where it goes |
|------|------------|---------------|
| `metal` | The telnet/TCP server platform (`Main`) as a systemd service named `jwstf` | `/opt/jwstf`, config in `/etc/jwstf`, data in `/var/lib/jwstf`, logs in `/var/log/jwstf` |
| `webapp` | The JSP/servlet module frontends, one WAR each, plus an Apache reverse proxy | Your existing Tomcat's `webapps/`, and one new file in `/etc/apache2/conf-available/` |

## What the installer will not do

- It will not edit any of your Apache vhosts or existing config files.
- It will not replace or remove a Tomcat webapp it did not install itself.
- It will not restart Tomcat unless you ask (`--restart-tomcat`), and it reloads Apache gracefully instead of restarting it.
- It will not install packages unless you pass `--install-deps`.
- It will not change your system Java (`update-alternatives` is never touched).
- It will not touch MySQL or create databases.

Everything it does install is recorded in `/var/lib/jwstf/install-manifest`, and
uninstall removes only what is listed there.

## 1. Before you start

**Requirements**

- Root access (`sudo`) and systemd.
- A JDK 25. On Ubuntu 22.04 and 24.04 the package is `openjdk-25-jdk` from the `universe` repository. It runs only the NWE service, so your other applications can keep their own Java.
- For the `webapp` part: **Tomcat 10 or newer**. The modules use `jakarta.*`, so Tomcat 9 is refused. Ubuntu packages Tomcat 10 (`tomcat10`). A Tomcat 11 unpacked under `/opt` works too.
- For the Apache proxy: Apache2 with the Debian/Ubuntu layout (`/etc/apache2`).

**Get the code.** The repository history is large, so take a shallow clone:

```bash
git clone --depth 1 https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21.git
cd Java.Web.Server.Telnet.Front.Java.21
```

**Find out what is already on the box** so the plan makes sense to you:

```bash
systemctl list-units '*tomcat*' apache2 --no-legend       # services
ls /var/lib/tomcat*/webapps /opt/*tomcat*/webapps 2>/dev/null   # existing contexts
grep -RhE '^\s*(ProxyPass|Alias|DocumentRoot)' /etc/apache2/sites-enabled /etc/apache2/conf-enabled
ss -ltn                                                    # ports in use
```

**Ports.** The `metal` service opens the ports enabled in
`configuration/nwe-config.xml` (49152 and the 49xxx range, 2000, 20000, 5512,
6682, 7743, 7744 and others). If anything already listens on one of them the
install stops and names the port. Either free it, disable that service in
`nwe-config.xml`, or pass `--ignore-port-conflicts`. The installer does not open
firewall ports.

## 2. Look before you install

`plan` is read-only. It runs every detection step and prints what `install` would do:

```bash
sudo bash bash/NWE.ubuntu-install.sh plan --mode both
```

Read the output for these lines:

- **Tomcat.** It lists the Tomcat it found, its HTTP port and `appBase`. If you run more than one Tomcat it stops and asks you to choose. Re-run with `--tomcat-base`, for example `--tomcat-base /var/lib/tomcat10`. For a manual install add `--tomcat-home` and `--tomcat-service` if they differ.
- **`[skip] /name: ... already exists in Tomcat`.** That context belongs to someone else and is left alone.
- **`[warn] /name: ... Deploying to Tomcat only`.** Apache already maps that path (a `ProxyPass`, `Alias` or similar) or a directory of that name exists under a DocumentRoot. The WAR is still deployed to Tomcat, but no Apache mapping is added, so your existing site keeps serving that path.
- **Ports in use**, and whether a JDK 25 was found.

Because the module names are short (`/chat`, `/library`, `/calendar`, ...),
clashes with your other projects are likely. To put every NWE module under its
own prefix instead (so `/chat` becomes `/nwe-chat`), add `--context-prefix nwe-`
to every command in this guide.

You can also deploy only some modules: `--modules ae6e66,emeter,futures`
(names are the context names without the prefix).

## 3. Install

Typical install on a shared server, with the NWE service and the webapps:

```bash
sudo bash bash/NWE.ubuntu-install.sh install --mode both --install-deps --context-prefix nwe-
```

Common variations:

| Goal | Command |
|------|---------|
| Only the service, no web part | `... install --mode metal --install-deps` |
| Only the webapps, into a specific Tomcat | `... install --mode webapp --tomcat-base /var/lib/tomcat10` |
| Webapps without touching Apache | `... install --mode webapp --no-apache` |
| Install the service but start it later | `... install --mode metal --no-start` |
| Your JDK 25 is not in the usual place | `... install --java-home /opt/jdk-25` |
| Restart Tomcat when it cannot hot-deploy | `... install --mode webapp --restart-tomcat` |

`--install-deps` only installs what is missing: JDK 25 (and Tomcat 10 or Apache2
if none exists). Leave it out to have the installer report instead.

What happens, in order:

1. **Java.** It finds a JDK 25 or installs one (with `--install-deps`).
2. **Ports.** It checks the NWE ports (metal).
3. **Build.** It compiles the sources with JDK 25 into the staged install (the repository does not carry compiled classes).
4. **Service.** It creates the `jwstf` system user and `/opt/jwstf`. The compiled classes are root-owned and read-only. The rest of the tree belongs to `jwstf`. It installs, enables and starts `jwstf.service`.
5. **Config.** It seeds `/etc/jwstf` (never overwriting files you edited; newer shipped defaults appear as `*.dist` next to them) and points the app's Tomcat settings at the Tomcat it found, but only if they still hold the shipped defaults.
6. **WARs.** Each module becomes a WAR, copied into Tomcat's `appBase` under a temporary name and then renamed, so Tomcat never sees a half-written file. Tomcat's `autoDeploy` unpacks it. Other applications are not restarted.
7. **Apache.** It enables `proxy`, `proxy_http` and `alias` if they are not already loaded, writes `/etc/apache2/conf-available/jwstf-proxy.conf`, enables it, and runs `apache2ctl configtest`. If the test fails it removes its file and leaves Apache as it was. Otherwise Apache is reloaded gracefully.

## 4. Finish the setup by hand

These steps are deliberately left to you because they touch secrets and shared services.

1. **Database password.** Edit `/etc/jwstf/nwe-credentials` and replace `NWE_DB_PASS=CHANGE_ME`. Chat and Emeter read it.
2. **MySQL login for the service.** Copy the example and fill it in:
   ```bash
   sudo cp /etc/jwstf/authentication/mysql.auth.xml.example /etc/jwstf/authentication/mysql.auth.xml
   sudo chown root:jwstf /etc/jwstf/authentication/mysql.auth.xml
   sudo chmod 640 /etc/jwstf/authentication/mysql.auth.xml
   sudoedit /etc/jwstf/authentication/mysql.auth.xml
   ```
3. **Databases.** If you use the database-backed modules, create their databases yourself. The helper scripts are `bash/MySQL.setup.sh` and `modules/*/servlets/setup-db.sh`. Read them first on a server that already runs MySQL.
4. **Publishing directory.** NWE publishes files to the `<apache-root>` directory in `nwe-config.xml` (default `/var/www/html/nwe`). If that directory already exists and the service user cannot write to it, NWE falls back to `/opt/jwstf/nwe-files`. To let it use the Apache directory, re-run the install with `--grant-apache-root`. That adds an access-control entry for the service user on that one directory only.
5. **Restart the service** after editing the files above: `sudo systemctl restart jwstf`.

## 5. Check that it worked

```bash
sudo bash bash/NWE.ubuntu-install.sh status       # what the installer recorded
systemctl status jwstf                            # service
journalctl -u jwstf -n 50                         # service log
sudo apache2ctl configtest                        # Apache config is valid
ls /var/lib/tomcat10/webapps/*.war                # WARs that were placed (path depends on your Tomcat)
curl -I http://127.0.0.1/nwe-ae6e66/              # through Apache (use your prefix)
curl -I http://127.0.0.1:8080/nwe-ae6e66/         # straight to Tomcat (use your Tomcat port)
telnet localhost 49152                            # NWE main prompt
```

Then confirm your existing sites still respond as they did before. If a module
page returns a 500 error, the usual cause is a missing database (step 4.3), not
the install.

## 6. Day-two operations

**Upgrade.** Pull the new code and run the same `install` command again. It is
safe to repeat. Your edited config and your data are kept, WARs the installer owns are
replaced, and the previous application directory is kept as `/opt/jwstf.prev`.
Use `--rebuild` to force a fresh compile.

**Limit the proxy to one site.** `jwstf-proxy.conf` is enabled server-wide, so
every virtual host on the machine will answer on the NWE paths. To serve them on
one site only, disable it and include it inside that site's vhost:

```bash
sudo a2disconf jwstf-proxy
# inside the <VirtualHost> you want:
#     Include /etc/apache2/conf-available/jwstf-proxy.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

Re-running `install` enables the file server-wide again, so repeat this after
each upgrade, or add `--no-apache` to upgrades and refresh the file by hand.

**Remove everything the installer added:**

```bash
sudo bash bash/NWE.ubuntu-install.sh uninstall            # keeps /etc/jwstf, /var/lib/jwstf, /var/log/jwstf
sudo bash bash/NWE.ubuntu-install.sh uninstall --purge    # deletes those too
```

Uninstall removes the service and unit file, `/opt/jwstf`, the WARs and unpacked
folders it deployed, and its Apache file (then reloads Apache). It leaves the
`jwstf` user, the Apache modules it enabled, any packages installed with
`--install-deps`, and everything else on the server. It refuses to run without
its manifest.

## 7. Troubleshooting

| Symptom | Likely cause and fix |
|---------|----------------------|
| `Several Tomcat installs found` | Pass `--tomcat-base DIR` to pick one. |
| `javax.* namespace (Tomcat 9)` | The modules need Tomcat 10+. Use `--mode metal`, or install Tomcat 10. |
| `No JDK 25+ found` | Run with `--install-deps`, enable `universe` (`sudo add-apt-repository universe && sudo apt-get update`), or pass `--java-home`. |
| `Ports in use by something else` | Free the port, disable that service in `nwe-config.xml`, or pass `--ignore-port-conflicts`. |
| `/name ... already exists in Tomcat` | Not yours to overwrite. Use `--context-prefix` for a side-by-side copy. |
| `Tomcat has autoDeploy off` | WARs are in place but not loaded. Restart Tomcat when convenient, or re-run with `--restart-tomcat`. |
| `apache2ctl configtest failed; our change was rolled back` | Read the printed error. Another file likely defines the same `Location` or conflicts with a loaded module. Apache was left unchanged. |
| `jwstf` starts then stops | `journalctl -u jwstf -n 100`. Check the database files from section 4 and any port clash. |
| A module page shows a 500 error | The module's database or credentials are not set up yet (section 4). |
| Apache returns 404 or 503 for a module path | Tomcat has not unpacked it yet, or the context was skipped. Run `status` and check Tomcat's logs. |

Run `bash bash/NWE.ubuntu-install.sh help` for the full option list.
