#!/bin/bash
# prepare-asterisk-for-docker.sh
# Script to prepare Asterisk files for Docker build on EC2

set -e

echo "=== Preparing Asterisk files for Docker build ==="

# Create build directory
BUILD_DIR="$HOME/asterisk-docker-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== Copying Asterisk binaries ==="
# Copy main binaries (check multiple locations)
if [ -f /usr/sbin/asterisk ]; then
    echo "Using Asterisk from /usr/sbin"
    sudo cp /usr/sbin/asterisk ./asterisk
    sudo cp /usr/sbin/safe_asterisk ./safe_asterisk
elif [ -f /usr/local/sbin/asterisk ]; then
    echo "Using Asterisk from /usr/local/sbin"
    sudo cp /usr/local/sbin/asterisk ./asterisk
    sudo cp /usr/local/sbin/safe_asterisk ./safe_asterisk
else
    echo "ERROR: Asterisk binary not found!"
    exit 1
fi

echo "=== Copying Asterisk modules ==="
# Create modules directory structure
mkdir -p ./asterisk_modules/modules

# Copy modules directory (check multiple locations)
if [ -d /usr/lib/asterisk ]; then
    echo "Using modules from /usr/lib/asterisk"
    # Copy all modules directly to asterisk_modules/modules (not nested)
    if [ -d /usr/lib/asterisk/modules ]; then
        sudo cp -r /usr/lib/asterisk/modules/* ./asterisk_modules/modules/
    fi
    # Copy any other files/directories from /usr/lib/asterisk (like asterisk subdirectory if it exists)
    for item in /usr/lib/asterisk/*; do
        if [ -d "$item" ] && [ "$(basename "$item")" != "modules" ]; then
            sudo cp -r "$item" ./asterisk_modules/
        elif [ -f "$item" ]; then
            sudo cp "$item" ./asterisk_modules/
        fi
    done
elif [ -d /usr/local/lib/asterisk ]; then
    echo "Using modules from /usr/local/lib/asterisk"
    # Copy all modules directly to asterisk_modules/modules (not nested)
    if [ -d /usr/local/lib/asterisk/modules ]; then
        sudo cp -r /usr/local/lib/asterisk/modules/* ./asterisk_modules/modules/
    fi
    # Copy any other files/directories from /usr/local/lib/asterisk
    for item in /usr/local/lib/asterisk/*; do
        if [ -d "$item" ] && [ "$(basename "$item")" != "modules" ]; then
            sudo cp -r "$item" ./asterisk_modules/
        elif [ -f "$item" ]; then
            sudo cp "$item" ./asterisk_modules/
        fi
    done
else
    echo "ERROR: Asterisk modules directory not found!"
    exit 1
fi

# Ensure res_pjsip.so is present (critical dependency)
if [ ! -f ./asterisk_modules/modules/res_pjsip.so ]; then
    echo "WARNING: res_pjsip.so not found in modules directory!"
    echo "Attempting to find and copy it..."
    if [ -f /usr/lib/asterisk/modules/res_pjsip.so ]; then
        sudo cp /usr/lib/asterisk/modules/res_pjsip.so ./asterisk_modules/modules/
        echo "✓ Copied res_pjsip.so from /usr/lib/asterisk/modules"
    elif [ -f /usr/local/lib/asterisk/modules/res_pjsip.so ]; then
        sudo cp /usr/local/lib/asterisk/modules/res_pjsip.so ./asterisk_modules/modules/
        echo "✓ Copied res_pjsip.so from /usr/local/lib/asterisk/modules"
    else
        echo "ERROR: res_pjsip.so not found anywhere!"
        exit 1
    fi
fi

echo "=== Copying Asterisk libraries ==="
# Copy libraries (check multiple locations)
if ls /usr/lib/libasteriskssl.so* >/dev/null 2>&1; then
    echo "Using libraries from /usr/lib"
    sudo cp /usr/lib/libasteriskssl.so* ./
    sudo cp /usr/lib/libasteriskpj.so* ./
elif ls /usr/local/lib/libasteriskssl.so* >/dev/null 2>&1; then
    echo "Using libraries from /usr/local/lib"
    sudo cp /usr/local/lib/libasteriskssl.so* ./
    sudo cp /usr/local/lib/libasteriskpj.so* ./
else
    echo "ERROR: Asterisk libraries not found!"
    exit 1
fi

echo "=== Copying XML documentation ==="
# Copy XML documentation (check multiple locations)
if [ -d /var/lib/asterisk/documentation ]; then
    echo "Using XML docs from /var/lib/asterisk/documentation"
    sudo cp -r /var/lib/asterisk/documentation ./xml_docs
elif [ -d /usr/local/var/lib/asterisk/documentation ]; then
    echo "Using XML docs from /usr/local/var/lib/asterisk/documentation"
    sudo cp -r /usr/local/var/lib/asterisk/documentation ./xml_docs
elif [ -d /usr/share/asterisk/documentation ]; then
    echo "Using XML docs from /usr/share/asterisk/documentation"
    sudo cp -r /usr/share/asterisk/documentation ./xml_docs
elif [ -d /usr/local/share/asterisk/documentation ]; then
    echo "Using XML docs from /usr/local/share/asterisk/documentation"
    sudo cp -r /usr/local/share/asterisk/documentation ./xml_docs
else
    echo "WARNING: No XML documentation found"
    mkdir -p xml_docs
fi

echo "=== Copying sound files ==="
# Copy sound files (check multiple locations)
if [ -d /var/lib/asterisk/sounds ]; then
    echo "Using sound files from /var/lib/asterisk/sounds"
    sudo cp -r /var/lib/asterisk/sounds ./sounds
elif [ -d /usr/share/asterisk/sounds ]; then
    echo "Using sound files from /usr/share/asterisk/sounds"
    sudo cp -r /usr/share/asterisk/sounds ./sounds
elif [ -d /usr/local/share/asterisk/sounds ]; then
    echo "Using sound files from /usr/local/share/asterisk/sounds"
    sudo cp -r /usr/local/share/asterisk/sounds ./sounds
else
    echo "WARNING: No sound files found"
    mkdir -p sounds
fi

echo "=== Copying MOH files ==="
# Copy MOH files (check multiple locations)
if [ -d /var/lib/asterisk/moh ]; then
    echo "Using MOH files from /var/lib/asterisk/moh"
    sudo cp -r /var/lib/asterisk/moh ./moh
elif [ -d /usr/share/asterisk/moh ]; then
    echo "Using MOH files from /usr/share/asterisk/moh"
    sudo cp -r /usr/share/asterisk/moh ./moh
elif [ -d /usr/local/share/asterisk/moh ]; then
    echo "Using MOH files from /usr/local/share/asterisk/moh"
    sudo cp -r /usr/local/share/asterisk/moh ./moh
else
    echo "WARNING: No MOH files found"
    mkdir -p moh
fi

echo "=== Setting proper ownership ==="
# Set proper ownership
sudo chown -R $USER:$USER .

echo "=== Verifying files ==="
echo "Files in build directory:"
ls -la

echo "=== Checking file sizes ==="
du -sh asterisk
du -sh asterisk_modules/
du -sh xml_docs/
du -sh sounds/
du -sh moh/

echo "=== Verifying key modules ==="
# Check for res_pjsip.so (critical)
if [ -f asterisk_modules/modules/res_pjsip.so ]; then
    echo "✓ res_pjsip.so found"
    ls -lh asterisk_modules/modules/res_pjsip.so
else
    echo "⚠ ERROR: res_pjsip.so not found!"
    exit 1
fi

# Check for res_pjsip_session.so
if [ -f asterisk_modules/modules/res_pjsip_session.so ]; then
    echo "✓ res_pjsip_session.so found"
    ls -lh asterisk_modules/modules/res_pjsip_session.so
else
    echo "⚠ WARNING: res_pjsip_session.so not found"
fi

# Check for res_srtp.so
if [ -f asterisk_modules/modules/res_srtp.so ]; then
    echo "✓ res_srtp.so found"
else
    echo "⚠ WARNING: res_srtp.so not found"
fi

# Check for codec_opus.so
if [ -f asterisk_modules/modules/codec_opus.so ]; then
    echo "✓ codec_opus.so found"
else
    echo "⚠ WARNING: codec_opus.so not found (install it if you need Opus support)"
fi

echo "=== Preparation complete ==="
echo "Ready to build Docker image with: docker build -f Dockerfile.ec2 -t asterisk-cention:production ."

