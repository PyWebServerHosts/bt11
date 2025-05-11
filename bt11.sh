#!/bin/bash

MODE_FILE="$HOME/.bt11/.mode"
ADMIN_FILE="$HOME/.bt11/.admin"
LOG_FILE="$HOME/.bt11/bt11.log"

DEFAULT_MODE="termux"
DEFAULT_ADMIN="0"

[[ ! -f "$MODE_FILE" ]] && echo "$DEFAULT_MODE" > "$MODE_FILE"
[[ ! -f "$ADMIN_FILE" ]] && echo "$DEFAULT_ADMIN" > "$ADMIN_FILE"

MODE=$(cat "$MODE_FILE")
KLADMIN=$(cat "$ADMIN_FILE")

log_action() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] CMD: $1 $2 $3 | MODE: $MODE | ADMIN: $KLADMIN" >> "$LOG_FILE"
}

# === STATUS ===
if [[ "$1" == "status" ]]; then
    echo "📦 bt11 Status:"
    echo "   Mode    : $MODE"
    echo "   KLAdmin : $([ "$KLADMIN" == "1" ] && echo 'ENABLED 🔓' || echo 'DISABLED 🔒')"
    exit 0
fi

# === EMERGENCY REMOVE ===
if [[ "$1" == "emgremove" && "$KLADMIN" == "1" ]]; then
    echo "[🔥] WARNING: This will REMOVE `bt11` and all associated files."
    echo "[!] Are you sure you want to continue? Type 'YES' to proceed."

    read answer

    if [[ "$answer" != "YES" ]]; then
        echo "[❌] Aborted. `bt11` is not removed."
        exit 0
    fi

    # Removing .bt11 directory
    echo "[🧨] Removing .bt11 directory from home..."
    rm -rf "$HOME/.bt11"

    # Removing references to bt11 in .bashrc and .zshrc
    echo "[⚠️] Removing bt11 from .bashrc and .zshrc..."
    sed -i '/.bt11/d' "$HOME/.bashrc" 2>/dev/null
    sed -i '/.bt11/d' "$HOME/.zshrc" 2>/dev/null

    # Source bashrc and zshrc again to finalize changes
    source $HOME/.bashrc 2>/dev/null || source $HOME/.zshrc 2>/dev/null

    echo "[✔️] bt11 has been completely removed. Goodbye, hacker!"
    exit 0
fi

# === REMOVE BT11 ===
if [[ "$1" == "remove-bt11" ]]; then
    echo "[🔥] WARNING: This will REMOVE `bt11` from your system and PATH."
    echo "[!] Are you sure you want to continue? Type 'YES' to proceed."

    read answer

    if [[ "$answer" != "YES" ]]; then
        echo "[❌] Aborted. `bt11` is not removed."
        exit 0
    fi

    # Removing .bt11 directory
    echo "[🧨] Removing .bt11 directory from home..."
    rm -rf "$HOME/.bt11"

    # Removing references to bt11 in .bashrc and .zshrc
    echo "[⚠️] Removing bt11 from .bashrc and .zshrc..."
    sed -i '/.bt11/d' "$HOME/.bashrc" 2>/dev/null
    sed -i '/.bt11/d' "$HOME/.zshrc" 2>/dev/null

    # Source bashrc and zshrc again to finalize changes
    source $HOME/.bashrc 2>/dev/null || source $HOME/.zshrc 2>/dev/null

    echo "[✔️] bt11 has been removed from your system and PATH."
    exit 0
fi

# === MODE / ADMIN SET ===
if [[ "$1" == "kl-up" ]]; then
    if [[ "$2" == "termux" || "$2" == "non-termux" ]]; then
        echo "$2" > "$MODE_FILE"
        echo "[✔] Mode set to $2"
        exit 0
    elif [[ "$2" == "kladmin" && ( "$3" == "1" || "$3" == "0" ) ]]; then
        echo "$3" > "$ADMIN_FILE"
        echo "[✔] kladmin set to $3"
        exit 0
    else
        echo "[-] Invalid usage. Use:"
        echo "   bt11 kl-up termux | non-termux"
        echo "   bt11 kl-up kladmin 1 | 0"
        exit 1
    fi
fi

CMD=$1
TYPE=$2
PKG=$3

# === PERMISSION BLOCK ===
if [[ "$MODE" == "non-termux" && "$KLADMIN" != "1" ]]; then
    if [[ "$TYPE" != "apt" ]]; then
        echo "❌ [LOCKED] NON-TERMUX mode only allows 'apt' unless kladmin is enabled."
        log_action "$CMD" "$TYPE" "BLOCKED:$PKG"
        exit 1
    fi
fi

# === PYTHON AUTO-INSTALL FOR TERMUX ===
if [[ "$MODE" == "termux" && "$TYPE" == "python" ]]; then
    if ! command -v python >/dev/null || ! command -v pip >/dev/null; then
        echo "[!] Python or pip missing. Installing via apt..."
        pkg update -y && pkg install -y python
    fi
fi

# === MAIN OPS ===
case "$CMD" in
    inst)
        case "$TYPE" in
            termux)
                echo "[+] Installing Termux pkg: $PKG"
                pkg install -y "$PKG"
                log_action "$CMD" "$TYPE" "$PKG"
                ;;
            apt)
                echo "[+] Installing APT pkg: $PKG"
                sudo apt install -y "$PKG"
                log_action "$CMD" "$TYPE" "$PKG"
                ;;
            python)
                echo "[+] Installing Python pkg: $PKG"
                pip install "$PKG"
                log_action "$CMD" "$TYPE" "$PKG"
                ;;
            *)
                echo "[-] Unknown install type: $TYPE"
                ;;
        esac
        ;;
    uninst)
        case "$TYPE" in
            termux)
                echo "[+] Uninstalling Termux pkg: $PKG"
                pkg uninstall -y "$PKG"
                log_action "$CMD" "$TYPE" "$PKG"
                ;;
            apt)
                echo "[+] Removing APT pkg: $PKG"
                sudo apt remove -y "$PKG"
                log_action "$CMD" "$TYPE" "$PKG"
                ;;
            python)
                echo "[+] Uninstalling Python pkg: $PKG"
                pip uninstall -y "$PKG"
                log_action "$CMD" "$TYPE" "$PKG"
                ;;
            *)
                echo "[-] Unknown uninstall type: $TYPE"
                ;;
        esac
        ;;
    *)
        echo "[-] Unknown command. Try:"
        echo "   bt11 inst termux|apt|python <pkg>"
        echo "   bt11 uninst termux|apt|python <pkg>"
        echo "   bt11 kl-up termux|non-termux"
        echo "   bt11 kl-up kladmin 1|0"
        echo "   bt11 status"
        echo "   bt11 remove-bt11  # To remove bt11 from your system"
        echo "   bt11 emgremove  # To remove bt11 completely (in KLAdmin mode)"
        ;;
esac
