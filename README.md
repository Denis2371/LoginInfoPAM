# Описание
Этот скрипт предназначен для отправки оповещения телеграмм боту в случае, если кто-то зайдёт на сервер посредством модуля PAM (Pluggable Authentication Modules - это модуль для управления аутентификацией и авторизацией пользователей, он отвечает за такие соединения, как, например, SSH). В телеграмм сообщении будет отправлена так же некоторая полезная информация, пригодная для анализа ситуации: имя пользователя, наименование системы, IP адреса, название сеанса терминала, время, активные в настоящее время сеансы терминала и так далее.
Кстати, бот отправляет сообщение и когда кто-то выходит из SSH сессии, тоже с подробной информацией.
```sh
Опции:
  -h, --help         Показать справку и выйти.
  -i, --install      Установить скрипт в систему (выполнять только если скрипт ещё не устновлен).
  -r, --remove       Удалить скрипт из системы.
  -c, --configure    Изменить значения переменных BOT_TOKEN и CHAT_ID, чтобы подключить скрипт к другому боту.
```
 Для любых действий по измнению, установке и удалению скрипта нужны права суперпользователя. Все поддерживаемые аргументы перечислены в разделе "Опции".

 Для установки скрипта в систему достаточно запустить его с флагом -i и под использованием прав суперпользователя. После чего скрипт будет перемещён устновлен и скрипту будут выданы права, которые не позволят просматривать и изменять содержимое скрипта пользователям без прав суперпользователя. Это сделано ещё и потому, что в скприпте будут хранится данные Телеграмм бота, которые позволят получить доступ к телеграмм боту кому угодно.
 Команда -i, предназначена только для установки скрипта в систему, на уже установленном скрипте её выполнение бессмысленно. После установки скрипта можно поменять данные телеграмм бота, запустив скрипт с правами суперпользователя и ключом -c, либо можно поменять данные прямо внутри самого установленного скрипта.
	
 Чтобы удалить скрипт достаточно выполнить скрипт с флагом -r (разумеется, с правами суперпользователя), что приведёт к удалению файла скрипта из системы и удалению записи строки автозапуска скрипта из системного файла /etc/pam.d/sshd. Данные действия при желании можно проделать и вручную, в результате чего скрипт будет полностью убран из системы.

 Окно со справкой можно всегда вызвать командой с флагом -h после установки скрипта, но и эту команду тоже нужно запускать с правами суперпользователя, если скрипт уже установлен, так после устновки скрипт не будет доступен для простых пользователей даже для чтения и исполнения.

# Для тех, кому интерсно что это такое вообще и почему оно тут есть и так выглядит
 Скрипт был написан мной только для себя, по фану. Ранее он был вообще проще сильно, устанавливался и конфигурировался только правкой файла, но я решил всё-таки сделать устновку и т.д., дабы упростить жизнь себе. Ну и уж так оно разрослось, что жалко потерять, выложил на GitHub. Возможно, кому-то будет полезно. Ну и я был бы очень рад, если кто-то подскажет какие модификации можно внести в этот скрипт. Как программист я вообще ни о чём, так что буду рад любым подсказкам.
