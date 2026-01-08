#!/bin/bash

# Author : luke.yang (2024-09-17)
# This script performs daily backups of the xrcloud and haio databases
# It deletes files older than 7 days, except for weekly and monthly backup files.
# Weekly backup: Files from Monday, older than 60 days.
# Monthly backup: Files from the 1st of each month.

# 이 스크립트는 xrcloud와 haio 데이터베이스를 매일 백업합니다.
# 생성된 지 7일이 지난 파일 중 주간 백업 및 월간 백업 파일을 제외하고 삭제합니다.
# 주간 백업: 60일 이전의 월요일에 생성된 파일.
# 월간 백업: 매월 1일에 생성된 파일.

# Define backup function (백업 함수 정의)
backup_dir() {
    SRC_DIR="$1"  # Source directory to back up (백업할 소스 디렉토리)
    DEST_DIR="$2"  # Destination directory for backups (백업이 저장될 디렉토리)
    TIMESTAMP=$(date +"%Y%m%d")  # Use current date for file name (현재 날짜로 파일명 지정)
    BACKUP_FILE="$DEST_DIR/backup_$(basename "$SRC_DIR")_$TIMESTAMP.tar.gz"

    # Ensure the backup destination directory exists, create if not (백업 디렉토리 확인 및 생성)
    mkdir -p "$DEST_DIR"

    # Create the backup file (백업 파일 생성)
    tar -czf "$BACKUP_FILE" -C "$(dirname "$SRC_DIR")" "$(basename "$SRC_DIR")"
    echo "Backup created: $BACKUP_FILE" >> "$LOG_FILE"

    # Delete backup files older than 7 days, except those created on Mondays or the 1st of any month
    # 7일이 넘은 파일 중 월요일 또는 매월 1일에 생성된 파일은 삭제하지 않음
    find "$DEST_DIR" -name "backup_*.tar.gz" | while read -r file; do
        file_date=$(echo "$file" | sed -E 's/.*backup_.*_([0-9]{8}).tar.gz/\1/')
        file_day_of_week=$(date -d "$file_date" +%u)
        file_day_of_month=$(date -d "$file_date" +%d)

        # Skip files older than 7 days that were created on a Monday or on the 1st of the month
        # 7일이 지난 파일 중 월요일(요일=1)이나 1일(날짜=01)에 생성된 파일은 제외
        if [[ $(($(date +%s) - $(date -d "$file_date" +%s))) -gt 604800 && "$file_day_of_week" != 1 && "$file_day_of_month" != 01 ]]; then
            echo "Deleting: $file" >> "$LOG_FILE"
            rm -f "$file"
        fi
    done

    # Delete backup files older than 60 days, except those created on the 1st of any month
    # 60일이 넘은 파일 중 매월 1일에 생성된 파일은 삭제하지 않음
    find "$DEST_DIR" -name "backup_*.tar.gz" | while read -r file; do
        file_date=$(echo "$file" | sed -E 's/.*backup_.*_([0-9]{8}).tar.gz/\1/')
        file_day_of_month=$(date -d "$file_date" +%d)

        # Skip files older than 60 days that were created on the 1st of the month
        # 60일이 지난 파일 중 1일에 생성된 파일은 제외
        if [[ $(($(date +%s) - $(date -d "$file_date" +%s))) -gt 5184000 && "$file_day_of_month" != 01 ]]; then
            echo "Deleting: $file" >> "$LOG_FILE"
            rm -f "$file"
        fi
    done
}

# Set home directory (홈 디렉토리 설정)
BACKUP_DIR="/mnt/xrcloud-prod-ko/backup"
mkdir -p "$BACKUP_DIR"
# backup
mkdir -p "$BACKUP_DIR/haio-db"
mkdir -p "$BACKUP_DIR/xrcloud-db"
# 로그 파일 설정
LOG_FILE="$BACKUP_DIR/db_backup.log"

# Record timestamp in log file (로그 파일에 시간 기록)
echo "Backup started at $(date)" >> "$LOG_FILE"

backup_dir "/app/haio/db" "$BACKUP_DIR/haio-db"  # Haio backup
backup_dir "/app/xrcloud/db" "$BACKUP_DIR/xrcloud-db"  # XRCLOUD backup

# Record completion in log file (로그 파일에 백업 완료 기록)
echo "Backup completed at $(date)" >> "$LOG_FILE"
