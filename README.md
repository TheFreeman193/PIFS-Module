# Profile (Fingerprint) Selector For Play Integrity Fix

## Development will continue after the holidays -TF

```text
     * | *  
   \        /
 *     /\     *
 -   <    >   -
  /   \/\/   \
       /\    
      /\*\  
     /\/\*\  
    /*/\/\/\   
   /\O\/\*\/\  
  /\*\/\*\/\/\ 
 /\O\/\/*/\/O/\   _8_
  _8_  ||   _8_  |_|_|
 |_|_| ||  |_|_| |_|_|
 |_|_| ||  |_|_|
```

This Magisk/KernelSU module makes swapping out your device profile for the [Play Integrity Fix](https://github.com/chiteroman/PlayIntegrityFix) or [PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) modules simple.

When installed, the module defaults to using the latest profile from the [Xiaomi.EU](https://xiaomi.eu) project, and keeps this up-to-date.

If you'd like to swap it out with one of the profiles from the [PIFS collection](https://github.com/TheFreeman193/PIFS), you can do so in your favourite terminal emulator (I recommend Termux!):

```sh
su -c pifs
```

This provides a simple menu for choosing which custom profile to use, or reverting back to the Xiaomi&#046;EU one.

## Credits

- [APK Patcher](https://github.com/osm0sis/APK-Patcher/) (for extracting Xiaomi&#046;EU profile) - [osm0sis](https://github.com/osm0sis/)
- [Xiaomi&#046;EU profile](https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/) - [Xiaomi.EU Project](https://xiaomi.eu)
- [PIFS collection](https://github.com/TheFreeman193/PIFS/) - [TheFreeman193](https://github.com/TheFreeman193/)

These sources may have their own license terms for modifying and redistributing their code.
Please check this before publishing derivations!

The contents of this repository are covered by the permissive [MIT license](LICENSE).
