#!/bin/sh

# Перечисление переменных
dir_install="/usr/local/bin" # Папка, в которую будет перемещён скрипт

# Функция для вывода справки
show_help() {
    cat << EOF
Использование: $(basename $0) [ОПЦИИ]

Описание: Этот скрипт предназначен для отправки оповещения телеграмм боту в случае, если кто-то зайдёт на сервер посредством модуля PAM (Pluggable Authentication Modules - это модуль для управления аутентификацией и авторизацией пользователей, он отвечает за такие соединения, как, например, SSH). В телеграмм сообщении будет отправлена так же некоторая полезная информация, пригодная для анализа ситуации. Так же бот отправляет сообщение и когда кто-то выходит из SSH сессии.

Опции:
  -h, --help         Показать эту справку и выйти.
  -i, --install      Установить скрипт в систему (выполнять только если скрипт ещё не устновлен).
  -r, --remove       Удалить скрипт из системы.
  -c, --configure    Изменить значения переменных BOT_TOKEN и CHAT_ID, чтобы подключить скрипт к другому боту.

Примеры:
  sudo $(basename $0) -i       Установить скрипт.
  $(basename $0) -h            Вывести справку
  
Краткая инструкция по использованию:
	Для любых действий по измнению, установке и удалению скрипта нужны права суперпользователя. Все поддерживаемые аргументы перечислены в разделе "Опции".
	Для установки скрипта в систему достаточно запустить его с флагом -i, --install и под использованием прав суперпользователя (например, так выглядит команда установки в Ubuntu: $ sudo $(basename $0) -i). После чего скрипт будет перемещён в папку $dir_install/ и скрипту будут выданы права, которые не позволят просматривать и изменять содержимое скрипта пользователям без прав суперпользователя. Это сделано ещё и потому, что в скприпте будут хранится данные Телеграмм бота, которые позволят получить доступ к телеграмм боту кому угодно.
	Команда -i, --install, предназначена только для установки скрипта в систему, на уже установленном скрипте её выполнение бессмысленно. После установки скрипта можно поменять данные телеграмм бота, запустив скрипт с правами суперпользователя и ключом -c (например, $ sudo $dir_install/$(basename "$0") -c). Но есть и другой вариант: открыть скрипт $dir_install/$(basename "$0") в текстовом редакторе (например, командой $ sudo nano $dir_install/$(basename "$0")) и поменять там данные в строчках $(grep -nE '^BOT_TOKEN=' "$0" | cut -d: -f1) и $(grep -nE '^CHAT_ID=' "$0" | cut -d: -f1), конечно, для этого тоже потребяются права суперпользователя.
	Чтобы удалить скрипт достаточно выполнить команду $ sudo $dir_install/$(basename "$0") -r (разумеется, с правами суперпользователя), что приведёт к удалению файла скрипта $dir_install/$(basename "$0") из системы и записи строки автозапуска скрипта session required pam_exec.so seteuid $dir_install/$(basename "$0") из системного файла /etc/pam.d/sshd. Данные действия при желании можно проделать и вручную, в результате чего скрипт будет полностью убран из системы.
	Это окно со справкой можно всегда вызвать командой $ sudo $dir_install/$(basename "$0") -h после установки скрипта, да, и тут тоже нужно запускать с правами суперпользователя, так как скрипт уже недоступен для простых пользователей.
EOF
}

show_instruction_bot() {
    cat << EOF
		Инструкция по созданию бота в Телеграмм:
	1. Открыть Telegram и найти @BotFather. Либо, можно просто его запустить чат с ботом по ссылке: https://telegram.me/botfather
	2. Начать чат с BotFather и следовать инструкциям для создания нового бота. Если написать /start, то бот отправит список поддерживаемых команд. Команда /newbot создаст нового бота, её и нужно ввести.
	3. «Alright, a new bot. How are we going to call it? Please choose a name for your bot.» - это предлагают выбрать имя для бота. Можно ввести любое, но нужно чтобы было уникальное.
	4. «Good. Now let's choose a username for your bot. It must end in 'bot'. Like this, for example: TetrisBot or tetris_bot.» - это предлагают ввести имя пользователя, которое будет использоваться для формирования ссылки на бота. Оно должно состоять из латинских символов, исключены пробелы. И самое главное, три последние буквы должны быть …bot.
	5. Когда бот будет создан, BotFather выдаст токен для доступа к API. Он будет написан в следущей строке после «Use this token access the HTTP API:». Если тапнуть на этот токен, то этот токен будет скопирован в буфер обмена.
	6. Необходимо написать несколько сообщений боту, чтобы скрипт смог извлечь CHAT_ID.
EOF
}

# проверка на root права у пользователя. Круто будет, если проще получится.
isRoot() {
  if [ $(id -u) -ne 0 ]; then
    echo "Скрипт должен запускаться от имени root или другого пользователя с привилегиями суперпользователя. Например, $ sudo "$0" -i"
    exit 1
  fi
}

# Установлен ли скприпт ранее? Нужно проверить!
isInstall() {
  if [ -f "$dir_install"/$(basename "$0") ]; then
    echo "Скрипт уже установлен в "$dir_install"/$(basename "$0"). После установки скрипта можно поменять данные телеграмм бота, запустив скрипт с правами суперпользователя и ключом -c (например, $ sudo "$dir_install"/$(basename "$0") -c)."
    exit 1
  fi
}

isPAM() {
  if [ ! -f "/etc/pam.d/sshd" ]; then
    echo "В системе не найден файл /etc/pam.d/sshd. Скрипт предназначен для работы с модулем PAM (Pluggable Authentication Modules). Как варант, установите SSH сервер. Например, можно поставить openssh-server (в Ubuntu это выполняется командой $ sudo apt install openssh-server)."
    exit 1
  fi
}

# Функция для установки скрипта
install_script() {
isRoot
isPAM
isInstall

# Присвоение данных для использования бота (BOT_TOKEN и CHAT_ID)
show_instruction_bot
read -p "Токен бота: " BOT_TOKEN

# Алгоритм получения CHAT_ID
 CHAT_ID=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates" | jq '.result[] | .message.chat.id')
# Если вдруг не написали боту сообщение, то скирпт будет ждать, когда напишут.
if [ -z "$CHAT_ID" ]; then
echo "Ожидается получение CHAT_ID… Для этого нужно написать боту собщение. Как только CHAT_ID будет получен, скрипт продолжит свою работу…"
while [ -z "$CHAT_ID" ]; do
    # Парсим ответ и извлекаем CHAT_ID
    CHAT_ID=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates" | jq '.result[] | .message.chat.id')
    sleep 10  # Пауза между запросами, поставил 10 секунд, но, возможно, можно ставить и другие значения.
done
fi

sed "s/BOT_TOKEN_data/$BOT_TOKEN/g; s/CHAT_ID_data/$CHAT_ID/g" "$0" > "/usr/local/bin/$(basename "$0")"

chmod +x "$dir_install"/$(basename "$0")
chmod 700 "$dir_install"/$(basename "$0")
chown root:root "$dir_install"/$(basename "$0")

echo "У бота BOT_TOKEN=$BOT_TOKEN и CHAT_ID=$CHAT_ID. Эти значения теперь будут храниться в файле "$dir_install"/$(basename "$0") на строчках $(grep -nE '^BOT_TOKEN=' "$0" | cut -d: -f1) и $(grep -nE '^CHAT_ID=' "$0" | cut -d: -f1). Так нужно для использования бота скриптом. Все, кто сможет открыть файл и прочитать значения BOT_TOKEN и CHAT_ID - смогут тоже использовать бота.
Отмечу, что только пользователь с правами root сможет просматривать, изменять и исполнять данный файл "$dir_install"/$(basename "$0"). Чтобы другой пользователь мог просмотреть содержимое файла "$dir_install"/$(basename "$0"), ему потребуется переключиться на учетную запись root (например, с помощью команды sudo) или иметь специальные привилегии, предоставленные администратором системы."

echo "session required pam_exec.so seteuid "$dir_install"/$(basename "$0")" >> /etc/pam.d/sshd

echo "Скрипт автооповещения установлен в "$dir_install"/$(basename "$0"), а файл $(readlink -f "$0") был удалён. Для внесения изменений в скрипт (например, добавление другого токена бота) теперь нужно заупускать скрипт с правами суперпользователя и ключом -c (например, $ sudo $dir_install/$(basename "$0") -c). Более подробно обо всех функциях можно узнать, выполнив команду $ sudo "$dir_install"/$(basename "$0") -h. Удаление скрипта выполняется командой $ sudo "$dir_install"/$(basename "$0") -r."

# Ну, удаляю уже сам скрипт, так как он был скопирован в нужную папку.
rm -rf "$0"
}

# Функция для удаления скрипта
remove_script() {
isRoot
	rm -rf "/usr/local/bin/$(basename "$0")"
	sed -i "/session required pam_exec.so seteuid \/usr\/local\/bin\/"$(basename "$0")"/d" /etc/pam.d/sshd
	echo "Скрипт был удалён"
}

# Изменение переменных BOT_TOKEN и CHAT_ID, хотя, возможно, можно будет использовать и для других каких-то настроек.
configure_script() {
isRoot

show_instruction_bot
read -p "Токен бота (BOT_TOKEN): " BOT_TOKEN
read -p "Идентификатор чата (CHAT_ID) (можно пропустить, нажав, Enter, если неизвестно): " CHAT_ID

# Если вдруг не написали боту сообщение, то скирпт будет ждать, когда напишут.
if [ -z "$CHAT_ID" ]; then
echo "Ожидается получение CHAT_ID… Для этого нужно написать боту собщение. Как только CHAT_ID будет получен, скрипт продолжит свою работу…"

while [ -z "$CHAT_ID" ]; do
    # Парсим ответ и извлекаем CHAT_ID
    CHAT_ID=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates" | jq '.result[] | .message.chat.id')
    sleep 10  # Пауза между запросами, поставил 10 секунд, но, возможно, можно ставить и другие значения.
done
fi

sed -i "s/^BOT_TOKEN=.*/BOT_TOKEN=\"${BOT_TOKEN}\"/" "$0"
sed -i "s/^CHAT_ID=.*/CHAT_ID=\"${CHAT_ID}\"/" "$0"

echo "Теперь BOT_TOKEN=$BOT_TOKEN, а CHAT_ID=$CHAT_ID. Эти данные по прежнему храниться в файле "$dir_install"/$(basename "$0") на строчках $(grep -nE '^BOT_TOKEN=' "$0" | cut -d: -f1) и $(grep -nE '^CHAT_ID=' "$0" | cut -d: -f1). Так нужно для использования бота скриптом. Все, кто сможет открыть файл и прочитать значения BOT_TOKEN и CHAT_ID - смогут тоже использовать бота.
Отмечу, что только пользователь с правами root сможет просматривать, изменять и исполнять данный файл "$dir_install"/$(basename "$0"). Чтобы другой пользователь мог просмотреть содержимое файла "$dir_install"/$(basename "$0"), ему потребуется переключиться на учетную запись root (например, с помощью команды sudo) или иметь специальные привилегии, предоставленные администратором системы."
}

# Основная функция для работы с Telegram API
send_telegram_data() {

# !!!!!Присвоение данных для использования бота!!!!!
# Быть может и есть како-то более безопасный способ хранения этих данных, но я его не знаю.
BOT_TOKEN="BOT_TOKEN_data"
CHAT_ID="CHAT_ID_data"
# !!!!!Данные для использования бота!!!!!
# !!!!!Все, кто их узнает, смогут использовать бота!!!!!

# IP=$(curl -s https://api.ipify.org) альтернативный вариант
IP=$(echo $SSH_CONNECTION | awk '{print $3}')
PORT=$(echo $SSH_CONNECTION | awk '{print $4}')
# IP_user=$(echo $SSH_CONNECTION | awk '{print $1}') для получения адреса решил, что тут лучше использовать $PAM_RHOST
# PORT_user=$(echo $SSH_CONNECTION | awk '{print $2}') решил вообще пока не использовать эту команду.
# PORT_user=$(grep "Accepted publickey for" /var/log/auth.log | tail -n 1 | grep -Po 'port \K\S*') альтернативная команда получения порта
IPinfo=$(curl -s http://ipinfo.io/$IP/json | jq '.hostname, .city, .region, .country, .org')
IPinfo_user=$(curl -s http://ipinfo.io/$PAM_RHOST/json | jq '.hostname, .city, .region, .country, .org')
SESSION_ID=$(who am i | awk '{print $2}')

# Проверяем тип события PAM
if [ "$PAM_TYPE" = "open_session" ]; then
    LOGIN="вошёл в систему"
	AboutLog=$(grep "Accepted .* for" /var/log/auth.log | tail -n 1)
	LOGIN2="входе"
	LOGIN3="подключившегося"
elif [ "$PAM_TYPE" = "close_session" ]; then
    LOGIN="вышел из системы"
	AboutLog=$( grep "closed session for user\|session closed for user\|session closed" /var/log/auth.log | tail -n 1)
	LOGIN2="выходе"
	LOGIN3="отключившегося"
fi

# Формируем сообщение
MESSAGE="Пользователь $PAM_USER $LOGIN $(hostname) с адресом $IP:$PORT через терминал $PAM_TTY посредством службы $PAM_SERVICE.

Предположительно, информация о $LOGIN2:
<pre>$AboutLog</pre>

Предположительно, местоположение $LOGIN3 (http://ipinfo.io/$PAM_RHOST/):
<pre>$IPinfo_user
$PAM_RHOST</pre>

Информация об активных пользователях: <pre>$(w)</pre>

Дата формирования сообщения:
<pre>$(date), по местному времени ($(TZ='Europe/Moscow' date))</pre>"

# Выполняем запрос к Telegram API
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE&parse_mode=HTML" > /dev/null

# Не буду я отправлять файл, наверное
#FILE_PATH='/var/log/auth.log'
#curl -s -F document="@$FILE_PATH" -F chat_id="$CHAT_ID" https://api.telegram.org/bot$BOT_TOKEN/sendDocument > /dev/null
}

# Выполнение скрипта, ранее было лишь перечисление функций.

# Проверяем количество аргументов
if [ $# -gt 1 ]; then
    echo "Ошибка: Допускается только один аргумент."
    show_help
    exit 1
fi

# Обрабатываем единственный аргумент
case "$1" in
    "")
		# Если не было передано никаких аргументов, выполняем основную функцию
        send_telegram_data
        exit 0
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    -i|--install)
        install_script
        exit 0
        ;;
	-c|--configure)
        configure_script
        exit 0
        ;;
	-r|--remove)
        remove_script
        exit 0
        ;;
	*)
        echo "Ошибка: Неправильный аргумент: $1"
        show_help
        exit 1
        ;;
esac
