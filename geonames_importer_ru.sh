#!/bin/bash

working_dir=$( cd "$( dirname "$0" )" && pwd )
data_dir="$working_dir/data"
zip_codes_dir="$working_dir/data/zip_codes"

# [BEGIN] CONFIGURATION FOR THE SCRIPT
# -------------------------------------

# Geonames URLs
geonames_general_data_repo="http://download.geonames.org/export/dump/"
geonames_postal_code_repo="http://download.geonames.org/export/zip/"

# Default values for database variables.
dbhost="localhost"
dbport=5432
dbname="geonames"
dbusername="postgres"

# Default value for download folder
download_folder="$working_dir/download"

# Default general dumps to download
dumps="allCountries.zip alternateNames.zip hierarchy.zip admin1CodesASCII.txt admin2Codes.txt featureCodes_en.txt timeZones.txt countryInfo.txt"
# By default all postal codes ... You can specify a set of the files located at http://download.geonames.org/export/zip/
postal_codes="allCountries.zip"

#
# The folders configuration used by this application is as follows:
#
# current_dir
#    ├── data                 => Decompressed data used in the import process
#    └── download             => Default folder where downloaded files will be stored temporaly
#
#
#
# [END] CONFIGURATION FOR THE SCRIPT
# -------------------------------------

logo() {
    echo "================================================================================================"
    echo "|                                                                                              |"
    echo "|                          G E O N A M E S    D A T A    I M P O R T E R                       |"
    echo "|                                                                                              |"
    echo "=========================================== v 2.0 =============================================="
}

usage() {
	logo
	echo "Использование: " $0 "-a <action> "
    echo " Где <action> может быть: "
	echo "    download-data: Загружает последние пакеты данных, доступные на GeoNames. Следует использовать дополнительный параметр с каталогом загрузки."
    echo "    create-db: Создает структуру базы данных pgsql без данных."
    echo "    create-tables: Создает таблицы в текущей базе данных. Полезно и удобно, если мы хотим импортировать записи в существующую базу данных."
    echo "    import-dumps: Импортирует данные GeoNames в БД. Необходима работающая база данных для работы."
	echo "    drop-db: Удаляет БД полностью."
    echo "    truncate-db: Удаляет данные GeoNames из БД."
    echo
    exit -1
}

dump_db_params() {
    echo "Используемые параметры базы данных ..."
    echo "Действие: " $action
    echo "UserName: " $dbusername
    echo "DB Host: " $dbhost
    echo "DB Port: " $dbport
    echo "DB Name: " $dbname
}

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

logo
echo "Текущий рабочий каталог:	$working_dir"
echo "Текущий каталог данных:	$data_dir"
echo "Каталог загрузки по умолчанию:	$download_folder"

# Deals with operation mode 2 (Database issues...)
# Parses command line parameters.
while getopts "a:u:p:h:r:n:" opt; 
do
    case $opt in
        a) action=$OPTARG ;;
        u) dbusername=$OPTARG ;;
        h) dbhost=$OPTARG ;;
        r) dbport=$OPTARG ;;
        n) dbname=$OPTARG ;;
    esac
done


case $action in
    download-data)
        echo "ЗАПУСК СКАЧИВАНИЯ ДАННЫХ !!!"
        # Checks if a download folder has been specified otherwise checks if the default download folder
        # exists and if it doesn't then creates it.
        if { [ "$3" != "" ]; } then
            if [ ! -d "$3" ]; then
                echo "Каталога для загрузки временных файлов $3 не существует. Создаём его."
                mkdir -p "$working_dir/$3"
            fi
            # Changes the default download folder to the one specified by the user.
            download_folder="$working_dir/$3"
            echo "Изменён каталог загрузки по умолчанию на $download_folder"
        else
            # Creates default download folder
            if [ ! -d "$download_folder" ]; then
                echo "Каталога для загрузки временных файлов '$download_folder' не существует. Создаём его."
                mkdir -p "$download_folder"
            fi
        fi

        # Dumps General data.
        echo "Скачивание общих файлов"
        if [ ! -d $data_dir ]; then
            echo "Каталога для данных не существует. Создаём его ..."
            mkdir -p $data_dir
        fi
        for dump in $dumps; do
            echo "Загрузка $dump в $download_folder"
            wget -c -P "$download_folder" "$geonames_general_data_repo/$dump"
            if [ ${dump: -4} == ".zip" ]; then
                echo "Распаковка $dump в $data_dir"
                unzip "$download_folder/$dump" -d $data_dir
            else
                if [ ${dump: -4} == ".txt" ]; then
                    mv "$download_folder/$dump" $data_dir
                fi
            fi           
        done

        # Dumps Postal Code data.
        echo "Загрузка информации о почтовых индексах"
        if [ ! -d $zip_codes_dir ]; then
            echo "Каталога с данными о почтовых индексах не существует. Создаём его ..."
            mkdir -p $zip_codes_dir
        fi
        if [ ! -d "$download_folder/zip_codes" ]; then
                echo "Каталога для загрузки временных файлов '$download_folder/zip_codes' не существует. Создаём его."
                mkdir -p "$download_folder/zip_codes"
        fi
        for postal_code_file in $postal_codes; do
            echo "Загрузка $postal_code_file в $download_folder/zip_codes"
            wget -c -P "$download_folder/zip_codes" "$geonames_postal_code_repo/$postal_code_file"
            if [ ${postal_codes: -4} == ".zip" ]; then
                echo "Распаковка файла Почтовых Индексов $postal_code_file в $download_folder/zip_codes"
                unzip "$download_folder/zip_codes/$postal_code_file" -d $zip_codes_dir
            fi
        done
        echo "ЗАГРУЗКА ДАННЫХ ЗАВЕРШЕНА !!!"

        echo "ИЗМЕНЕНИЕ ФАЙЛОВ ДАННЫХ ДЛЯ ИМПОРТА !!!"
        echo "ИЗМЕНЕНИЕ allCountries.txt"
        sed -i 's/\\//g' "$zip_codes_dir/allCountries.txt"
        echo "ИЗМЕНЕНИЕ iso-languagecodes.txt"
        sed -i '1d' "$data_dir/iso-languagecodes.txt"
        echo "ИЗМЕНЕНИЕ timeZones.txt"
        sed -i '1d' "$data_dir/timeZones.txt"
        echo "ИЗМЕНЕНИЕ countryInfo.txt"
        sed -i '1,51d' "$data_dir/countryInfo.txt"
        
        exit 0
    ;;
esac

case "$action" in
    create-db)
        echo "Создание базы данных $dbname..."
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -c "DROP DATABASE IF EXISTS $dbname;"
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -c "CREATE DATABASE $dbname WITH TEMPLATE = template0 ENCODING = 'UTF8';" 
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -d $dbname < "$working_dir/geonames_db_struct.sql"
    ;;

    create-tables)
        echo "Создание таблицы в базе данных $dbname..."
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -d $dbname < "$working_dir/geonames_db_struct.sql"
    ;;

    import-dumps)
        echo "Импортирование дампа GeoNames в базу данных $dbname"
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -d $dbname < "$working_dir/geonames_import_data.sql"
    ;;    

    drop-db)
        echo "Удаление базы данных $dbname"
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -c "DROP DATABASE IF EXISTS $dbname;"
    ;;

    truncate-db)
        echo "Удаление данных GeoNames из базы данных $dbname"
        psql -q -v ON_ERROR_STOP=1 -h $dbhost -p $dbport -U $dbusername -d $dbname < "$working_dir/geonames_truncate_db.sql"
    ;;
esac

if [ $? == 0 ]; then 
	echo "[OK]"
else
	echo "[FAILED]"
fi

exit 0