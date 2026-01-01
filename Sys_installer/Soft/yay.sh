#!/bin/bash

echo "Этот скрипт установит yay — помощник для AUR (Arch User Repository)."
echo "Требуется установленные пакеты: git и base-devel."
echo

# Вопрос да/нет
while true; do
    read -rp "Хотите начать установку yay? (y/n): " yn
    case $yn in
        [Yy]* )
            echo "Начинаем установку yay..."
            break
            ;;
        [Nn]* )
            echo "Установка отменена."
            exit 0
            ;;
        * )
            echo "Пожалуйста, ответьте y (да) или n (нет)."
            ;;
    esac
done

# Создаём временную директорию
temp_dir=$(mktemp -d)
cd "$temp_dir" || exit 1

# Клонируем репозиторий yay
echo "Клонируем yay из AUR..."
git clone https://aur.archlinux.org/yay.git || {
    echo "Ошибка при клонировании репозитория."
    exit 1
}

cd yay || {
    echo "Не удалось перейти в директорию yay."
    exit 1
}

# Собираем и устанавливаем
echo "Собираем и устанавливаем yay..."
makepkg -si || {
    echo "Ошибка при сборке или установке yay."
    exit 1
}

# Удаляем временную директорию
cd /
rm -rf "$temp_dir"

echo "yay успешно установлен!"
echo "Теперь вы можете использовать команду: yay"