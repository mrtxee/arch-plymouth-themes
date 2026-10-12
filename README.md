<!--
Copyright (C) 2026 Mr Txee (mrtxee)
SPDX-License-Identifier: GPL-2.0-only
-->

# arch-plymouth-themes

Minimal Plymouth boot splash themes for Arch Linux: the Arch logo centered on
a black background (matching the systemd-boot look), with an animated spinner
underneath.

Each theme uses the `script` module, so it renders at any resolution and needs
no compiled code. The spinner position and speed are computed; only the animation
artwork differs.

Not affiliated with or endorsed by Arch Linux. "Arch Linux" and the Arch Linux
logo are trademarks of the Arch Linux project -- see [NOTICE](NOTICE).


## Themes

All previews are shown expanded below. Each one plays the exact layout and
timing of its script on a 1280x800 black canvas; click a preview to open the
full-size APNG in a new tab.

The theme name is also the directory name and the argument to the install
commands below.

### arch-boot-spinner

Rotating arc, 24 frames, ~1.6&nbsp;s cycle.

<a href="preview/arch-boot-spinner.apng"><img src="preview/arch-boot-spinner.apng" alt="arch-boot-spinner animated preview" width="640"></a>

### arch-boot-orbital-dot

Thin ring with an orbiting dot, 36 frames, ~1.8&nbsp;s cycle.

<a href="preview/arch-boot-orbital-dot.apng"><img src="preview/arch-boot-orbital-dot.apng" alt="arch-boot-orbital-dot animated preview" width="640"></a>

### arch-boot-dots

Three dots, glow walking left&ndash;right, 9 frames, ~0.9&nbsp;s cycle.

<a href="preview/arch-boot-dots.apng"><img src="preview/arch-boot-dots.apng" alt="arch-boot-dots animated preview" width="640"></a>


## Installation

Every distribution below needs the same two things: the theme directory in the
system theme path, and a rebuilt initramfs -- Plymouth bakes the theme into the
initramfs at build time, so copying files alone changes nothing.

The `.plymouth` descriptors hardcode
`/usr/share/plymouth/themes/<theme>`, so the theme directory name must match the
theme name exactly.

Replace `<theme>` with one of `arch-boot-spinner`, `arch-boot-orbital-dot` or
`arch-boot-dots`.


### Arch Linux

Uses `mkinitcpio`. The `plymouth` hook must be in `HOOKS` in
`/etc/mkinitcpio.conf` or the splash will not appear at all.

```sh
sudo pacman -S plymouth

# copy the theme into the system theme directory
sudo cp -r <theme> /usr/share/plymouth/themes/

# make it the default and rebuild the initramfs
sudo plymouth-set-default-theme -R <theme>
```

If `mkinitcpio.conf` has no `plymouth` hook, add it before rebuilding:

```sh
# /etc/mkinitcpio.conf
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
#                       add plymouth after autodetect, before block:
HOOKS=(base udev autodetect plymouth modconf block filesystems keyboard fsck)

sudo mkinitcpio -P
```

To show kernel messages during boot instead of the splash, press
<kbd>Esc</kbd> (or `Tab`).


### Debian

Uses `update-initramfs`. Plymouth and the theme package come from the
repositories.

```sh
sudo apt update
sudo apt install plymouth

# copy the theme into the system theme directory
sudo cp -r <theme> /usr/share/plymouth/themes/

# set it as the default and rebuild the initramfs
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
    default.plymouth /usr/share/plymouth/themes/<theme>/<theme>.plymouth 100

sudo update-alternatives --set default.plymouth \
    /usr/share/plymouth/themes/<theme>/<theme>.plymouth

sudo update-initramfs -u
```

Then make sure the splash is actually enabled in
`/etc/default/grub` -- without `splash` on the kernel cmdline nothing shows up:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

sudo update-grub
```

`plymouth-set-default-theme -R <theme>` also works on Debian and does the
alternatives update and initramfs rebuild in one step.


### Ubuntu

Uses `update-alternatives` and `update-initramfs`, like Debian. The difference
is that Ubuntu registers the theme under the `default.plymouth` alternatives
link, and the theme priority matters when several themes are installed.

```sh
sudo apt update
sudo apt install plymouth

# copy the theme into the system theme directory
sudo cp -r <theme> /usr/share/plymouth/themes/

# register and select it (priority 100)
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
    default.plymouth /usr/share/plymouth/themes/<theme>/<theme>.plymouth 100

sudo update-alternatives --set default.plymouth \
    /usr/share/plymouth/themes/<theme>/<theme>.plymouth

# rebuild every initramfs, not just the running kernel
sudo update-initramfs -u -k all
```

Then enable the splash in `/etc/default/grub`:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

sudo update-grub
```

If a proprietary NVIDIA driver is installed, the splash may drop to a black
screen because the framebuffer is not modeset. Add
`nvidia_drm.modeset=1` to the cmdline and rebuild:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia_drm.modeset=1"
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf

sudo update-initramfs -u -k all
sudo update-grub
```


### Verifying

```sh
# list themes Plymouth can actually see
plymouth-set-default-theme -l
```

If your theme is not listed, the directory name does not match the `Name=` key
in its `.plymouth` descriptor.

To preview without rebooting:

```sh
sudo plymouthd && sudo plymouth show-splash && sleep 3 && sudo plymouth quit
```


## Tuning the animation

Both knobs live at the top of each `.script` file:

```js
frame_count = 24;   // number of spin-*.png frames
spin_div    = 4;    // frames skipped between steps
```

The `script` plugin has no timer: `on_refresh` is called on every redraw, and
the frame advances once every `spin_div` redraws. At a 60 Hz display a
`spin_div` of 4 yields ~15 fps. **Larger `spin_div` means slower animation.**

The spinner is placed 3/7 of the way from the bottom of the logo to the bottom
of the screen:

```js
spinner_sprite.SetY(logo_bottom + (Window.GetHeight() - logo_bottom) * 3.0 / 7);
```


## Regenerating previews

The APNG files in `preview/` are generated, not hand-made. They replay the
exact layout and timing of the scripts on a 1280x800 black canvas:

```sh
./tools/make-preview.sh
```

Requires ImageMagick 7 (`magick`) and `ffmpeg` with the APNG encoder.


## Layout

```
arch-boot-spinner/       theme: descriptor + script + spin-*.png
arch-boot-orbital-dot/   each also carries LICENSE and LICENSES/
arch-boot-dots/
preview/                 generated animated previews (APNG), 1280x800
tools/make-preview.sh    preview renderer
LICENSE                  GNU GPL v2, full text (whole repository)
LICENSES/                REUSE license files for binary assets
REUSE.toml               licensing for files that cannot carry a header
NOTICE                   asset provenance and trademark notice
```

Every `.script` and `.plymouth` file carries an `GPL-2.0-only` tag. The
`.plymouth` descriptors additionally expose a `Comment=` key, which is the
conventional place for author metadata in Plymouth themes. Plymouth reads only
`ModuleName`, `ImageDir` and `ScriptFile` from these files, so the extra keys
are inert -- `#` comments are supported by Plymouth's own key-file parser, and
`Comment=` is simply ignored.


## License

GPL-2.0-only -- see [LICENSE](LICENSE). Every `.script` file carries an
`SPDX-License-Identifier: GPL-2.0-only` tag.

The Arch Linux logo shipped as `splash-arch.png` is third-party trademarked
artwork and is not covered by this license; see [NOTICE](NOTICE).

### Per-theme license files

Each theme directory also carries its own copies, so that a single theme can be
copied or packaged on its own -- GPL v2 section 1 requires giving recipients "a
copy of this License along with the Program":

```
arch-boot-dots/LICENSE                                  GPL-2.0 full text
arch-boot-orbital-dot/LICENSE
arch-boot-spinner/LICENSE
arch-boot-*/LICENSES/GPL-2.0-only.txt                   same text, SPDX-named
arch-boot-*/LICENSES/LicenseRef-Arch-Logo-Trademark.txt splash-arch.png terms
```

These are redundant for repository-wide compliance and are ignored by the REUSE
tool. Plymouth is unaffected: the script plugin reads only the `ImageDir` and
`ScriptFile` keys and never enumerates the theme directory.

## Author

Mr Txee (mrtxee)
