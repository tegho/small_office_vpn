TOC:
<!-- TOC -->

- [Пакет setup-montana](#%D0%BF%D0%B0%D0%BA%D0%B5%D1%82-setup-montana)
- [Пакет setup-nevada](#%D0%BF%D0%B0%D0%BA%D0%B5%D1%82-setup-nevada)
- [Пакет setup-ohio](#%D0%BF%D0%B0%D0%BA%D0%B5%D1%82-setup-ohio)
- [Избирательная предача трафика split-tunneling](#%D0%B8%D0%B7%D0%B1%D0%B8%D1%80%D0%B0%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D0%B0%D1%8F-%D0%BF%D1%80%D0%B5%D0%B4%D0%B0%D1%87%D0%B0-%D1%82%D1%80%D0%B0%D1%84%D0%B8%D0%BA%D0%B0-split-tunneling)
- [Клиентские сертификаты](#%D0%BA%D0%BB%D0%B8%D0%B5%D0%BD%D1%82%D1%81%D0%BA%D0%B8%D0%B5-%D1%81%D0%B5%D1%80%D1%82%D0%B8%D1%84%D0%B8%D0%BA%D0%B0%D1%82%D1%8B)
- [Клиентские конфиги OpenVpn](#%D0%BA%D0%BB%D0%B8%D0%B5%D0%BD%D1%82%D1%81%D0%BA%D0%B8%D0%B5-%D0%BA%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D0%B8-openvpn)

<!-- /TOC -->

# Пакет setup-montana

    Пакет выполняет настройку сервера montana.ajalo.com (сервер PKI).

    Во время первой установки выполняется скрипт `/root/pki-montana/first-run.sh`, который создает зашифрованный контейнер с инфраструктурой PKI в файле `/root/pki-montana/pki-montana.bin`, генерирует случайные пароли для доступа к контейнеру и для закрытого ключа корневого сертификата, создает и экспортирует ключи и сертификаты для всех серверов в проекте ajalo. PKI создается с поддержкой CRL. Сертификат CA имеет CN="Montana vpn CA".

> **После завершения развертывания пароли следует сохранить в надежном месте и удалить файлы с сервера PKI:**
> 
> ```bash
> /root/pki-montana/pki_password
> /root/pki-montana/ca_key_password
> ```

> **Следующие сертификаты понадобятся для развертывания других серверов. Необходимо сохранить их в надежном месте и удалить после завершения развертывания:**
> 
> ```bash
> /root/pki-montana/server-vpn.zip
> /root/pki-montana/prometheus-client.zip
> ```

    Для поддержания в актуальном состоянии DNS записи montana.ajalo.com, используется пакет ddns-afraid-org. Конфигурационный файл `/etc/ddns-afraid-org.d/montana.ajalo.com.conf` следует заполнить вручную после установки, вписав ключ обновления DNS.

    Для мониторинга работы устанавливаются агенты prometheus-nginx-exporter и prometheus-node-exporter. Порты агентов не выставляются в сеть напрямую, а проксируются с помощью nginx, который также выполняет функции контроля доступа. Информация prometheus-nginx-exporter доступна по внешней ссылке https://montana.ajalo.com/prometheus-nginx и prometheus-node-exporter доступен по ссылке https://montana.ajalo.com/prometheus-node Для доступа клиент должен авторизоваться с помощью сертификата, который генерируется при установке PKI "Montana vpn CA". Хотя это делает данные мониторинга доступными любому держателю сертификата VPN, тем не менее сужает круг доступа до доверенных пользователей, а также упрощает установку и избавляет от необходимости поддерживать отдельный PKI.

    Также nginx используется для публикации CRL, который доступен по адресу http://montana.ajalo.com/crl Важно отметить, что nginx публикует CRL, а также сам его использует. Файл расположен в двух местах, что следует учитывать при его перегенерации:

```bash
/var/www/crl-pki-montana/crl.pem
/etc/nginx/pki-montana/crl.pem
```

    Для удобства перегенерации CRL можно взять за основу скрипт `/root/pki-montana/new-crl.sh` , однако его следует скорректировать с учетом расположения ключей доступа.

>     Необходимо перегенерировать CRL каждые 180 дней или менее, иначе устаревший CRL отклоняется сервером и клиентский сертификат не может пройти проверку.

    Для контроля трафика используется ipset и iptables. При установке создается сервис `iptables.service`. Сервис стартует автоматичеки при каждом перезапуске машины и выполняет скрипт `/etc/iptables/filter.sh`, содержащий инструкции ipset и iptables.

    Резервное копирование выполняется с помощью пакета backup-to-ssh. При установке создается конфигурация для резервного копирования каталогов `/etc` и `/root/pki-montana` . Ключи SSH следует добавить вручную после установки

```bash
/usr/share/backup-to-ssh/import-ssh-priv.sh /root/pki-key
rm -f /root/pki-key
```

# Пакет setup-nevada

    Пакет выполняет настройку сервера nevada.ajalo.com (сервер VPN).

    Сервер VPN поддерживает подключение клиентов по OpenVpn и IKEV2/IPSEC с авторизацией по сертификату, маршрутизирует клиентский трафик а также предлагает DNS сервис. DNS сервис отвечает на рекурсивные запросы клиентов и обслуживает домен `.nevada`, в котором содержатся актуальные записи с внутренними адресами клиентов. OpenVpn слушает нестандартный TCP порт 993, что в некоторых ситуациях помогает маскировать трафик ценой незначительных потерь производительности.

    Для поддержания в актуальном состоянии DNS записи nevada.ajalo.com, используется пакет ddns-afraid-org. Конфигурационный файл `/etc/ddns-afraid-org.d/nevada.ajalo.com.conf` следует заполнить вручную после установки, вписав ключ обновления DNS.

    При развертывании сервера необходимо установить сертификаты, сгенерированные на этапе установки PKI. В этом поможет скрипт `/usr/share/setup-nevada/import-zip.sh`, который распределяет ключи и сертификаты по нужным каталогам:

```bash
/usr/share/setup-nevada/import-zip.sh /root/server-vpn.zip
rm -f /root/server-vpn.zip
systemctl restart strongswan openvpn-server@vpn1 nginx
```

    Для мониторинга работы устанавливаются агенты prometheus-nginx-exporter и prometheus-node-exporter, а также в виде docker контейнеров устанавливаются агенты мониторинга openvpn и strongswan. Порты агентов не выставляются в сеть напрямую, а проксируются с помощью nginx, который также выполняет функции контроля доступа. Информация prometheus-nginx-exporter доступна по внешней ссылке https://nevada.ajalo.com/prometheus-nginx, prometheus-node-exporter доступен по ссылке https://nevada.ajalo.com/prometheus-node Данные агентов мониторинга VPN доступны по адесам https://nevada.ajalo.com/prometheus-openvpn и https://nevada.ajalo.com/prometheus-ipsec Для доступа клиент должен авторизоваться с помощью сертификата, который генерируется при установке PKI "Montana vpn CA". Хотя это делает данные мониторинга доступными любому держателю сертификата VPN, тем не менее сужает круг доступа до доверенных пользователей, а также упрощает установку и избавляет от необходимости поддерживать отдельный PKI.

    При планировании распределения приватных IP адресов компании предлагается  для сервисов VPN использовать блок 192.168.192.0/22, где:

- 192.168.192.1/32 - адрес VPN сервера. В текущей реализации используется только для взаимодействия с клиентами VPN, однако позволяет без труда интегрировать сервер в подсеть компании (например в 192.168.192.0/24)

- 192.168.193.0/24 - подсеть клиентов strongswan.

- 192.168.194.0/24 - подсеть клиентов openvpn.

- 192.168.195.0/24 - зарезервировано для расширения.

    При подключении или отключении VPN клиента strongswan и openvpn выполняют скрипт `/usr/libexec/vpn-client-learn/learn.sh`, который унифицирует данные о клиенте от обоих сервисов. Унифицированные данные передаются скриптам в каталоге `/etc/vpn-client-learn.d`, которые выполняются по очереди. Например `20-dns-register.sh` обновляет записи прямой (`.nevada`) и обратной зоны DNS сервера bind9, установленного на этой машине. Таким образом для пользователя c CN="user2" при подключении создается DNS A запись `user2-vpn.nevada` и PTR запись соответствующая его ip адресу. При отключении пользователя записи могут удаляться с небольшой задержкой, обусловленной внутренними алгоритмами VPN сервиса. Скрипты можно использовать например для модификации правил iptables или аналогичных задач.

    Маршрутизация трафика клиентов по умолчанию предполагает передачу всего клиентского трафика через сервер VPN. Межклиентский трафик разрешен. Избирательная передача клиентского трафика описана в разделе **split-tunneling**.

    Сервисы strongswan, openvpn и nginx по разному работают с CRL. Так strongswan читает URL CRL из сертификата и обычно проверяет на лету, но может использовать дополнительно и локальный файл CRL. В то же время openvpn и nginx могут работать только с локальным CRL и не проверяют URL из сертификата вовсе. Для стабильной работы используется сервис `montana-crl.service`, который запускается каждые 10 минут, загружает CRL для каждого сервиса и в случае успеха записывает текущее время для экспорта агентом мониторинга

```bash
/etc/swanctl/x509crl/pki-montana.pem
/etc/openvpn/pki-montana/crl.pem
/etc/nginx/pki-montana/crl.pem
/var/lib/prometheus/node-exporter/montana-crl.prom    
```

    Для контроля трафика используется ipset и iptables. При установке создается сервис `iptables.service`. Сервис стартует автоматичеки при каждом перезапуске машины и выполняет скрипт `/etc/iptables/filter.sh`, содержащий инструкции ipset и iptables.

    Резервное копирование выполняется с помощью пакета backup-to-ssh. При установке создается конфигурация для резервного копирования каталога `/etc`. Ключи SSH следует добавить вручную после установки

```bash
/usr/share/backup-to-ssh/import-ssh-priv.sh /root/vpn-key
rm -f /root/vpn-key
```

# Пакет setup-ohio

    Пакет выполняет настройку сервера ohio.ajalo.com (сервер мониторинга).

    Сервер мониторинга использует prometheus и alertmanager для контроля функционирования всех серверов проекта ajalo и уведомляет администратора по электронной почте при обнаружении нештатных ситуаций. Для отправки почты используется exim4 в роли смартхоста с авторизацией клиентов по паролю. В текущей реализации работа смартхоста ограничена приемом писем с локального хоста, что делает отправку уведомлений alertmanager проще и открывает перспективу для развития. Кроме того, на сервер по SSH загружаются резервные копии с других серверов.

    Для поддержания в актуальном состоянии DNS записи ohio.ajalo.com, используется пакет ddns-afraid-org. Конфигурационный файл `/etc/ddns-afraid-org.d/ohio.ajalo.com.conf` следует заполнить вручную после установки, вписав ключ обновления DNS.

    При развертывании сервера необходимо установить сертификаты, сгенерированные на этапе установки PKI. В этом поможет скрипт `/usr/share/setup-ohio/import-zip.sh`, который распределяет ключи и сертификаты по нужным каталогам:

```bash
/usr/share/setup-ohio/import-zip.sh /root/prometheus-client.zip
rm -f /root/prometheus-client.zip
systemctl nginx
```

    Для мониторинга работы сервера устанавливаются агенты prometheus-nginx-exporter и prometheus-node-exporter. Порты агентов не выставляются в сеть напрямую, а проксируются с помощью nginx, который также выполняет функции контроля доступа. Информация prometheus-nginx-exporter доступна по внешней ссылке https://ohio.ajalo.com/prometheus-nginx, prometheus-node-exporter доступен по ссылке https://ohio.ajalo.com/prometheus-node Веб интерфейс prometheus доступен по адесу https://ohio.ajalo.com/prometheus Для доступа клиент должен авторизоваться с помощью сертификата, который генерируется при установке PKI "Montana vpn CA". Хотя это делает данные мониторинга доступными любому держателю сертификата VPN, тем не менее сужает круг доступа до доверенных пользователей, а также упрощает установку и избавляет от необходимости поддерживать отдельный PKI.

    При этом сертификат для проверки подлинности самого веб-сервера автоматически не генерируется и должен быть создан вручную

```bash
apt install -y certbot-snap-assist
certbot certonly --non-interactive --agree-tos --standalone --email admin@ajalo.com --domain ohio.ajalo.com
systemctl restart nginx
```

    Критерии реагирования alertmanager:

- неответ любого объекта мониторинга

- менее 10% свободной RAM в течении 2 минут

- интенсивный своп в течении 2 минут

- CPU занят более чем на 80% в течении 2 минут

- свободное место на любом диске менее 10%

- свободные иноды на любом диске менее 30%

- nginx unhandled connections > 10%

- Сервис openvpn или strongswan не поднят

- последняя успешная загрузка CRL с PKI более 21 минуты назад

- последняя успешная отправка резервной копии более 24 часов +15 минут назад

    При развертывании сервера необходимо подготовить файл конфигурации, например `/root/mail.secrets` следующего образца:

```bash
fromname="InfoBot"
from="my-informer-bot@yandex.ru"
smarthost="smtp.yandex.ru"
smarthost_port="587"
passwd="SecretYandexPassword"
adminmail="admin-real-email@aol.com"
```

    В этом примере для пересылки почты используется смартхост яндекс и уведомления будут отправлены от имени `my-informer-bot@yandex.ru` на действующий адрес администратора `admin-real-email@aol.com`. Настройку смартхоста выполняется запуском

```bash
/usr/share/setup-ohio/config-mail.sh /root/mail.secrets
rm -f /root/mail.secrets
```

Повторный запуск `config-mail.sh` не меняет никаких настроек, поэтому в следующий раз изменение параметров придется выполнять вручную.

    Сервис `montana-crl.service` запускается каждые 10 минут и загружает CRL для каждого сервиса. В случае успеха записывает текущее время для экспорта агентом мониторинга

```bash
/etc/prometheus/pki-montana/crl.pem
/etc/nginx/pki-montana/crl.pem
/var/lib/prometheus/node-exporter/montana-crl.prom    
```

    Для контроля трафика используется ipset и iptables. При установке создается сервис `iptables.service`. Сервис стартует автоматичеки при каждом перезапуске машины и выполняет скрипт `/etc/iptables/filter.sh`, содержащий инструкции ipset и iptables.

    Резервное копирование выполняется с помощью пакета backup-to-ssh. При установке создается конфигурация для резервного копирования каталога `/etc`. Ключи SSH следует добавить вручную после установки

```bash
/usr/share/backup-to-ssh/import-ssh-priv.sh /root/office-key
rm -f /root/office-key
```

    Для приема резервных копий с других серверов в ОС автоматически добавляются пользователи:

```bash
remotebackup-pki
remotebackup-vpn
remotebackup-office
```

    Резервные копии хранятся в домашних каталогах. Назначение открытых SSH ключей этим пользователям удобно выполнять скриптом

```bash
/usr/share/setup-ohio/import-ssh-pub.sh /root/office-key.pub remotebackup-office
/usr/share/setup-ohio/import-ssh-pub.sh /root/pki-key.pub remotebackup-pki
/usr/share/setup-ohio/import-ssh-pub.sh /root/vpn-key.pub remotebackup-vpn
```

# Избирательная предача трафика (split-tunneling)

    После развертывания серверов в стандартной конфигурации, пользователи VPN при подключении получают возможность передавать весь свой трафик через VPN сервер. Разделение трафика возможно дополнительно настроить по адресу сети назначения, например для обмена по VPN трафиком только между пользователями и внутренними ресурсами компании, или для предотвращения маршрутизации клиентских обращений к собственной локальной сети.

    Для openvpn это не представляет сложности, поскольку протокол предлагает возможность отправлять клиенту с сервера записи таблицы маршрутов и DNS сервера для этого подключения. Это поддерживается клиентами linux, windows, android, apple?. Со стороны vpn сервера такие настройки могут быть заданы группам клиентов или персонально через конфигурацию CCD в каталоге `/etc/openvpn/nevada-ccd` (подробнее см документацию openvpn). Кроме того, для apple любые сетевые настройки можно задавать профилями конфигурации mobileconfig если они поддерживаются в ОС. При необходимости запретить использование клиентом каких-либо диапазонов, можно использовать динамическую конфигурацию брандмауэра средствами скриптов в каталоге `/etc/vpn-client-learn.d`.

    Для протокола IPSEC все сложнее, поскольку наиболее популярные клиенты вообще не поддерживают получение от сервера параметров настройки VPN подключения. В android strongswan такие настройки можно делать только прописывая маршруты вручную. В стандартном клиенте windows IPSEC подключение следует создавать скриптом или править существующее чем-то вроде

```powershell
Set-VpnConnection "nevada" -SplitTunneling 1
Add-VpnConnectionRoute -ConnectionName "nevada" -DestinationPrefix "192.168.192.0/22" -PassThru
```

поскольку задать эти параметры в GUI невозможно. Итд.

    Это руководство не охватывает тонкости конфигурации split-tunneling. Из-за упомянутых особенностей такая настройка во многом ложится на администратора и техподдержку. При большом или динамично меняющемся штате для сохранения ресурсов IT персонала такая задача требует четкого формулирования, разработку протоколов взаимодействия между сотрудниками и, возможно, разработки дополнительного клиентского ПО.

# Клиентские сертификаты

    Сервер PKI позволяет работать с клиентскими сертификатами не имея их закрытого ключа. При добавлении нового пользователя закрытый ключ в целях безопасности остается на стороне клиента, а на сервер передается только запрос на генерацию сертификата. После обработки запроса администратор отправляет клиенту новый сертифика, который не содержит секретной информации.

    В пользовательском запросе важное значение имеют алгоритм P-384 (sha512) и CN (Common name). CN должен быть задан без пробелов и спецсимволов, поскольку будет использован в DNS записях и в файловой системе VPN сервера. Кроме того, CN должен быть уникальным для каждого пользователя, администратору следует это контролировать.

> Администратору следует внимательно проверять корректность пользовательских запросов перед подписанием.

    Полученный от клиента запрос администратор загружает в PKI, подписывает и выгружает ответ для передачи обратно клиенту. Подробнее см описание утилиты  crypto-pki.

    Ввиду особенностей работы easy-rsa, на которой построен наш PKI, процедура перевыпуска может быть затруднена или невозможна. Рекомендуется вместо перевыпуска генерировать новый сертификат и отзывать старый.

    Для создания ключей в windows 10 в проекте ajalo разработана графическая утилита [cert_helper_win-0.2.zip](https://tegho.github.io/small_office_vpn/apt-repo/cert_helper_win-0.2.zip) Утилита написана на powershell и запускается прилагаемым `cert_helper.bat` для упрощения обхода политики запуска скриптов в windows. Однако следует учитывать, что при первом запуске все равно срабатывает windows defender о чем следует предупредить пользователя и техподдержку. Обычно генерацию можно было бы выполнить утилитами certreq и certutil, но в процессе потребуется активное использование командной строки и работа с файлами, что в комплексе может быть сложно для подавляющего числа пользователей.

    Утилита crypto-pki экспортирует корневой сертификат вместе с ответом на пользовательский запрос о выдаче нового сертификата.

    В android и apple ОС выпуск клиентского сертификата не тестировался. Пользователю следует переносить ключ, предварительно выпустив его на другом компьютере с linux или windows.

# Клиентские конфиги OpenVpn

    OpenVpn клиенты поддерживают добавление соединения посредством импорта конфигов. Администратор передает пользователю не только сертификат, но и конфиг для упрощения настройки. Пользовательский сертификат с ключом, CA сертификат и tls-auth ключ могут быть упомянуты в виде ссылок на файлы или в виде base64 в окружении соответствующих тегов. Пользовательский ключ и сертификат можно также указать в конфиге по отпечатку, однако это работает только для windows (apple?).

    Подробнее о создании шаблонов конфигов в описании пакета crypto-pki.

    При передаче конфига клиенту следует обратить внимание на защищенность канала передачи. Очевидно, что конфиг содержащий закрытые ключи не следует передавать по открытому каналу связи.

    Компроментация ключей tls-auth, содержащиеся в конфиге, может повлечь за собой DDOS атаки на сервер и, соответственно, отказ в обслуживании клиентов. Для исправления ситуации придется менять ключи tls-auth и перенастраивать всех клиентов компании, что приведет к длительному простою и большим трудозатратам. Таким образом, компроментации tls-auth стоит избегать, передавая конфиги только безопасным способом.