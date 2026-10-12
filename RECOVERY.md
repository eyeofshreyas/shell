# Recovery guide

Work branch: `developer` (never `main`, it mirrors upstream). Known-good checkpoint: tag `stable-2026-10-12`.

## 1. Shell crashed or looks broken: restart

```
pkill quickshell
cd /mnt/Windows/CODEING/PROJECTS/shell
direnv reload                # rebuilds plugin and sets CAELESTIA_LIB_DIR / QML2_IMPORT_PATH
quickshell -n -p . > /tmp/qs.log 2>&1 &
grep -aE 'ERROR|Failed' /tmp/qs.log
```

## 2. Roll back to the stable checkpoint

```
git status                    # stash or commit anything you want to keep first
git stash -u
git checkout stable-2026-10-12     # inspect only
git checkout developer && git reset --hard stable-2026-10-12   # discards later commits
```

Safer: `git checkout -b fix-from-stable stable-2026-10-12`.

## 3. Common failures

| Symptom | Fix |
|---|---|
| `Quickshell was built against Qt X but system has Qt Y` / random crashes after `pacman -Syu` | `paru -S --rebuild quickshell-git qt6-m3shapes-git`, then `rm -rf build && direnv reload` |
| `module "M3Shapes" is not installed` | `paru -S qt6-m3shapes-git` |
| Icons or sidebar glyphs blank | `paru -S ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd && fc-cache -f`, restart shell |
| CMake: `aubio` not found | `sudo pacman -S aubio` |
| CMake: `cava` not found | `paru -S libcava` |
| Plugin build is broken or stale | `rm -rf build && direnv reload` |
| Launcher cannot start apps | `paru -S app2unit` |
| External-monitor brightness does nothing | `paru -S ddcutil` |
| No temperature readings | `sudo pacman -S lm_sensors` |
| Calendar says `auth failed: Failed to get token` | Re-authenticate the `gws` CLI |

## 4. Install everything in one go

```
sudo pacman -S aubio
paru -S libcava qt6-m3shapes-git quickshell-git app2unit ddcutil lm_sensors \
        ttf-material-symbols-variable ttf-rubik-vf ttf-cascadia-code-nerd
```

## 5. Logs

- Live log if started as above: `/tmp/qs.log`
- Quickshell keeps logs under `/run/user/1000/quickshell/by-id/*/log.qslog`
