<div>

[**简体中文**](README_zh_CN.md)

</div>

## FlClash

[![Downloads](https://img.shields.io/github/downloads/LM-Firefly/FlClash/total?style=flat-square&logo=github)](https://github.com/LM-Firefly/FlClash/releases/)[![Last Version](https://img.shields.io/github/release/LM-Firefly/FlClash/all.svg?style=flat-square)](https://github.com/LM-Firefly/FlClash/releases/)[![License](https://img.shields.io/github/license/LM-Firefly/FlClash?style=flat-square)](LICENSE)

[![Channel](https://img.shields.io/badge/Telegram-Channel-blue?style=flat-square&logo=telegram)](https://t.me/FlClash)

A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.

on Desktop:

<p style="text-align: center;">
    <img alt="desktop" src="snapshots/desktop.gif">
</p>

on Mobile:

<p style="text-align: center;">
    <img alt="mobile" src="snapshots/mobile.gif">
</p>

## Features

✈️ Multi-platform: Android, Windows, macOS and Linux

💻 Adaptive multiple screen sizes, Multiple color themes available

💡 Based on Material You Design, [Surfboard](https://github.com/getsurfboard/surfboard)-like UI

☁️ Supports data sync via WebDAV

✨ Support subscription link, Dark mode

## Use

### Linux

⚠️ Make sure to install the following dependencies before using them

```bash
    sudo apt-get install libayatana-appindicator3-dev
    sudo apt-get install libkeybinder-3.0-dev
```

### Android

Support the following actions

```bash
    com.follow.clash.action.START
  
    com.follow.clash.action.STOP
  
    com.follow.clash.action.CHANGE
```

## Download

<a href="https://github.com/LM-Firefly/FlClash/releases"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" width="200px"/></a>

## Build

1. Update submodules

   ```bash
   git submodule update --init --recursive
   ```
2. Install `Flutter` and `Golang` environment
3. Build Application

   - android

     1. Install  `Android SDK` ,  `Android NDK`
     2. Set `ANDROID_NDK` environment variables
     3. Run Build script

        ```bash
        dart .\setup.dart android
        ```
   - windows

     1. You need a windows client
     2. Install  `Gcc`，`Inno Setup`
     3. Run build script

        ```bash
        dart .\setup.dart windows --arch <arm64 | amd64>
        ```
   - linux

     1. You need a linux client
     2. Run build script

        ```bash
        dart .\setup.dart linux --arch <arm64 | amd64>
        ```
   - macOS

     1. You need a macOS client
     2. Run build script

        ```bash
        dart .\setup.dart macos --arch <arm64 | amd64>
        ```

## Star

The easiest way to support developers is to click on the star (⭐) at the top of the page.

<p style="text-align: center;">
    <a href="https://api.star-history.com/svg?repos=LM-Firefly/FlClash&Date">
        <img alt="start" width=50% src="https://api.star-history.com/svg?repos=LM-Firefly/FlClash&Date"/>
    </a>
</p>
