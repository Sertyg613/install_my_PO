#!/bin/bash
set -euo pipefail

# Делаем yay.sh исполняемым, если он рядом
[[ -f "./yay.sh" ]] && chmod +x "./yay.sh"

# ==================== НАСТРОЙКИ ====================
SCRIPT1="./yay.sh"
# SCRIPT2="./другой_скрипт.sh"  # Раскомментировать, если нужен второй скрипт

PACMAN_PKGS=(
    #"hyprland: тайловый менаджер"
    "neofetch:Утилита для красивого системного инфо"
    "btop:Монитор процессов"
    "git:Система контроля версий"
    "gnome-text-editor:Текстовый редактор"
    "curl:Утилита для скачивания файлов"
    "flatpak:Платформа для Flatpak-приложений"
)

AUR_PKGS=(
    "visual-studio-code-bin:Редактор VS Code"
    "firefox:Браузер Firefox"
    "youtube: YouTube"
    "timeshift:Утилита резервного копирования"
    "wine:Запуск Windows-приложений"
    "os-prober:Обнаружение других ОС для GRUB"
    "gparted:Графический редактор разделов"
)

FLATPAK_PKGS=(
    "com.visualstudio.code:Visual Studio Code"
    "org.telegram.desktop:Telegram Desktop"
    "app.twintail.launcher.ttl:Twintail Launcher"
    "md.obsidian.Obsidian:Obsidian (заметки)"
    "com.github.cubitect.cubiomes-viewer:Cubiomes Viewer"
    "com.heroicgameslauncher.hgl:Heroic Games Launcher"
    "de.haeckerfelix.Fragments:Fragments (Torrent-клиент)"
    "com.valvesoftware.Steam:Steam"
    "org.prismlauncher.PrismLauncher:Prism Launcher (Minecraft)"
)

# ===================================================

ask_yes_no() {
    local question="$1"
    while true; do
        read -rp "$question (y/n): " yn
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Ответьте y (да) или n (нет)." ;;
        esac
    done
}

echo "=== Мастер настройки системы ==="
echo

# ==================== ЗАПУСК yay.sh ====================
if [[ -f "$SCRIPT1" ]]; then
    echo "Обнаружен скрипт: $SCRIPT1"
    if ask_yes_no "Запустить установку yay сейчас?"; then
        echo "Запускаем $SCRIPT1..."
        bash "$SCRIPT1"
        echo "$SCRIPT1 завершён."
        echo
    fi
else
    echo "Внимание: Скрипт $SCRIPT1 не найден — пропускаем установку yay."
    echo
fi

# Опциональный второй скрипт
if [[ -v SCRIPT2 && -f "$SCRIPT2" ]]; then
    echo "Обнаружен дополнительный скрипт: $SCRIPT2"
    if ask_yes_no "Запустить его сейчас?"; then
        bash "$SCRIPT2"
        echo "$SCRIPT2 завершён."
        echo
    fi
fi

# ==================== УСТАНОВКА ДРАЙВЕРОВ NVIDIA ====================
echo "Проверяем наличие видеокарты NVIDIA..."
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    echo "Обнаружена видеокарта NVIDIA (сейчас может использоваться открытый драйвер Nouveau)."
    if ask_yes_no "Установить проприетарные драйверы NVIDIA (рекомендуется для игр и производительности)?"; then
        echo "Устанавливаем драйверы NVIDIA..."
        sudo pacman -S --needed nvidia nvidia-utils nvidia-settings lib32-nvidia-utils

        echo "Включаем DRM modeset для NVIDIA..."
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null

        echo "Регенерируем initramfs (чтобы применить blacklist Nouveau)..."
        sudo mkinitcpio -P

        echo "Драйверы NVIDIA установлены и настроены."
        echo "После завершения всего скрипта ОБЯЗАТЕЛЬНО ПЕРЕЗАГРУЗИТЕСЬ!"
        echo
    else
        echo "Пропускаем установку NVIDIA-драйверов (будет использоваться Nouveau)."
        echo
    fi
else
    echo "Видеокарта NVIDIA не обнаружена — пропускаем."
    echo
fi

# ==================== НАСТРОЙКА FLATHUB ====================
if command -v flatpak >/dev/null 2>&1; then
    if ! flatpak remotes | grep -q flathub; then
        echo "Добавляем репозиторий Flathub..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        echo "Flathub добавлен."
        echo
    fi
else
    echo "Flatpak не установлен — раздел Flatpak будет пропущен."
    echo
fi

# ==================== УСТАНОВКА ПРОГРАММ ====================
echo "Переходим к установке программ."
echo

# Pacman
echo "1. Программы из официальных репозиториев (pacman):"
for i in "${!PACMAN_PKGS[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${PACMAN_PKGS[$i]#*:}"
done
echo
read -rp "Введите номера через пробел (или Enter для пропуска): " pacman_choice

# AUR
echo
echo "2. Программы из AUR (требуется yay):"
if ! command -v yay >/dev/null 2>&1; then
    echo "Внимание: yay не найден! Установка из AUR будет пропущена."
    aur_choice=""
else
    for i in "${!AUR_PKGS[@]}"; do
        printf "%2d) %s\n" "$((i+1))" "${AUR_PKGS[$i]#*:}"
    done
    echo
    read -rp "Введите номера через пробел (или Enter для пропуска): " aur_choice
fi

# Flatpak
echo
echo "3. Программы из Flatpak:"
if command -v flatpak >/dev/null 2>&1; then
    for i in "${!FLATPAK_PKGS[@]}"; do
        printf "%2d) %s\n" "$((i+1))" "${FLATPAK_PKGS[$i]#*:}"
    done
    echo
    read -rp "Введите номера через пробел (или Enter для пропуска): " flatpak_choice
else
    echo "Flatpak не установлен — пропускаем."
    flatpak_choice=""
fi

# Установка из pacman
if [[ -n "${pacman_choice:-}" ]]; then
    if ask_yes_no "Установить выбранные программы из pacman?"; then
        pacman_pkgs=()
        for num in $pacman_choice; do
            idx=$((num-1))
            [[ $idx -ge 0 && $idx -lt ${#PACMAN_PKGS[@]} ]] && pacman_pkgs+=("${PACMAN_PKGS[$idx]%%:*}")
        done
        [[ ${#pacman_pkgs[@]} -gt 0 ]] && sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
    fi
fi

# Установка из AUR
if [[ -n "${aur_choice:-}" ]]; then
    if ask_yes_no "Установить выбранные программы из AUR?"; then
        aur_pkgs=()
        for num in $aur_choice; do
            idx=$((num-1))
            [[ $idx -ge 0 && $idx -lt ${#AUR_PKGS[@]} ]] && aur_pkgs+=("${AUR_PKGS[$idx]%%:*}")
        done
        [[ ${#aur_pkgs[@]} -gt 0 ]] && yay -S --needed --noconfirm "${aur_pkgs[@]}"
    fi
fi

# Установка из Flatpak
if [[ -n "${flatpak_choice:-}" ]]; then
    if ask_yes_no "Установить выбранные программы из Flatpak?"; then
        flatpak_pkgs=()
        for num in $flatpak_choice; do
            idx=$((num-1))
            [[ $idx -ge 0 && $idx -lt ${#FLATPAK_PKGS[@]} ]] && flatpak_pkgs+=("${FLATPAK_PKGS[$idx]%%:*}")
        done
        [[ ${#flatpak_pkgs[@]} -gt 0 ]] && flatpak install flathub "${flatpak_pkgs[@]}" --assumeyes
    fi
fi

echo
echo "Всё завершено. Система готова к работе!"
echo "Если вы устанавливали драйверы NVIDIA — ОБЯЗАТЕЛЬНО ПЕРЕЗАГРУЗИТЕСЬ!"
echo "Рекомендуется перезагрузить компьютер в любом случае."
