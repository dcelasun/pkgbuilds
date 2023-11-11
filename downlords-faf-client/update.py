import requests
import subprocess
import re
import os

# Configuration time! ^_^
GITHUB_USER = "FAForever"
GITHUB_REPO = "downlords-faf-client"
PKGBUILD_PATH = "PKGBUILD"
TEST_MODE = False  # Remember to switch to True for a test run!

# Function to get the latest version~ OwO
def get_latest_version():
    if TEST_MODE:
        return "2023.11.0"  # Just a pretend version for testing!
    response = requests.get(f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/releases/latest")
    return response.json()["tag_name"].lstrip("v")

# Function to calculate those sneaky checksums! >:3
def calculate_checksum(path_or_url):
    if TEST_MODE:
        return "dummychecksum"  # Just a placeholder, teehee!
    
    # Is it a URL or a local file? Hmm...
    if path_or_url.startswith("http://") or path_or_url.startswith("https://"):
        cmd = f"curl -Ls {path_or_url} | sha256sum"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.split()[0]
    else:
        # It's a local file! Let's open it up!
        with open(path_or_url, 'rb') as file:
            return subprocess.run(["sha256sum"], stdin=file, text=True, capture_output=True).stdout.split()[0]

# Function to update our PKGBUILD! Yay! \(^o^)/
def update_pkgbuild(content, latest_version, new_checksums):
    # Updating the version~ UwU
    content = re.sub(r'pkgver=[^\n]+', f'pkgver={latest_version}', content)

    # Update _pkgver and _filename, very important! o.o
    _pkgver = latest_version.replace('.', '_')
    content = re.sub(r'_pkgver=[^\n]+', f'_pkgver={_pkgver}', content)
    content = re.sub(r'_filename="[^"]+"', f'_filename="faf_unix_{_pkgver}.tar.gz"', content)

    # Let's get those checksums in line! >:3
    checksum_str = "sha256sums=(" + " ".join([f"'{cs}'" for cs in new_checksums]) + ")\n"
    content = re.sub(r'sha256sums=\([^\)]+\)', checksum_str, content)

    return content

# Main script starts here! Adventure time! >w<
latest_version = get_latest_version()

# Reading the current PKGBUILD, let's see what we got! :D
with open(PKGBUILD_PATH, 'r') as file:
    pkgbuild_content = file.read()

# What's our current version? OwO
current_version = re.search(r'pkgver=([0-9.]+)', pkgbuild_content).group(1)

# Time for some magic! ✨
if current_version != latest_version:
    print(f"New version detected: {latest_version} UwU")
    print(f"Current version is just a smol bean: {current_version}")

    # These are our precious files! Handle them with care! UwU
    source_urls = [
        f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/download/v{latest_version}/faf_unix_{latest_version.replace('.', '_')}.tar.gz",
        "https://github.com/FAForever/downlords-faf-client/raw/develop/src/media/appicon/128.png",
        './DownlordsFafClient.desktop',  # Local file, handle with love <3
        './downlords-faf-client'         # Another local treasure! ^_^
    ]

    # Checksum calculation time! Math is fun! OwO
    new_checksums = [calculate_checksum(url) for url in source_urls]

    # Update the PKGBUILD with our new findings! ^-^
    updated_content = update_pkgbuild(pkgbuild_content, latest_version, new_checksums)

    # Writing the updated content back to PKGBUILD! Here we go!
    with open(PKGBUILD_PATH, 'w') as file:
        file.write(updated_content)

    print("PKGBUILD is all updated and shiny! Version", latest_version, "with new checksums! UwU")
else:
    print("No new version detected. Current version is still super kawaii: ", current_version)

# Script end! Great job! (^_^)/

