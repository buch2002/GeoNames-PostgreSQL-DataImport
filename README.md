Импорт данных с GeoNames в БД PostgreSQL
===================

- - - - 

Создание и поддержание актуальной копии списка стран, городов, областей в БД. Одной из крупнейших и наиболее широко используемых баз геоданных в части названий и координат различных мест. Исходные данные от GeoNames доступны по условиям лицензии Creative Commons.

# GeoNames-PostgreSQL-DataImport #

### Shell Script для импорта данных с geonames.org в базу данных PostgreSQL. ###

Этот проект, является форком проекта <a href="https://github.com/AGPDev/GeoNames-PostgreSQL-DataImport" target="_blank">GeoNames PostgreSQL DataImport</a> пользователя <a href="https://github.com/AGPDev" target="_blank">Anderson Guilherme Porto</a> который адаптировал версию под PostgreSQL.

Для файлов geonames_importer.sh и geonames_importer_ru.sh установить бит исполнения коммандой:
```sh
$ chmod +х geonames_importer*.sh
```

Все выводимые сообщения файла geonames_importer_ru.sh для удобства переведены на русский язык

Перед запуском отредактируйте пункты под свои нужды:
```sh
dbhost="localhost"
dbport=5432
dbname="geonames"
dbusername="postgres"
```

Использование: geonames_importer.sh -a "action"

Где "action" может быть:

- **download-data** Загружает последние пакеты данных, доступные на GeoNames. Следует использовать дополнительный параметр с каталогом загрузки.
- **create-db** Создает структуру базы данных pgsql без данных.
- **create-tables** Создает таблицы в текущей базе данных. Полезно и удобно, если мы хотим импортировать записи в существующую базу данных.
- **import-dumps** Импортирует данные GeoNames в БД. Необходима работающая база данных для работы.
- **drop-db** Удаляет БД полностью.
- **truncate-db** Удаляет данные GeoNames из БД.

Например, для скачивания свежей версии данных GeoNames, используйте такую комманду:
```sh
$ geonames_importer.sh -a download-data
```
