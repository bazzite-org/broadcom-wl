set -e

PATCHES=${1:-pkgbuild}

apply() {
        echo "##### $1"
        set -e
        git am --whitespace=fix --3way --ignore-space-change --ignore-whitespace < "$PATCHES/$1"
}

recom() {
        local patchfile="$PATCHES/$1"
        echo "##### $1"
        # List of fuzz levels to try (start lowest). Adjust as needed.
        for fuzz in 0 1 2 3; do
                echo "==> Trying fuzz=$fuzz"
                # Clean uncommitted changes from previous attempt
                git reset --hard
                # -N: ignore already applied hunks, helps if parts are upstream
                # Avoid -f so we can detect failure via exit status
                if patch -p1 -N -F"$fuzz" < "$patchfile"; then
                        echo "Applied with fuzz=$fuzz"
                        git add -u
                        git commit -m "Recommit $1 (fuzz=$fuzz)"
                        return 0
                else
                        echo "Failed with fuzz=$fuzz"
                fi
        done
        git add -u
        git commit -m "Recommit $1"
}

git am --abort || true
git reset --hard start

recom 001-null-pointer-fix.patch
recom 002-rdtscl.patch
recom 003-linux47.patch
recom 004-linux48.patch
recom 005-debian-fix-kernel-warnings.patch
recom 006-linux411.patch
apply 007-linux412.patch
recom 008-linux415.patch
recom 009-fix_mac_profile_discrepancy.patch
recom 010-linux56.patch
recom 011-linux59.patch
apply 012-linux517.patch
recom 013-linux518.patch
apply 014-linux414.patch
apply 015-linux600.patch
recom 016-linux601.patch
recom 017-linux612.patch
apply 018-linux613.patch
recom 019-linux614.patch
apply 020-linux615.patch
recom 021-linux617.patch