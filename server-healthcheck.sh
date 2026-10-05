#!/usr/bin/env bash
set -euo pipefail

EXIT_CODE=0

print_header() {
    echo -e "\n=== $1 ==="
}

check_cpu() {
    print_header "1. Procesor i obciążenie systemu"
    
    echo "Czas pracy i Load Average:"
    uptime

    echo -e "\nLiczba rdzeni CPU:"
    echo "Liczba rdzeni: $(nproc)"

    echo -e "\nTop 3 procesy według użycia CPU:"
    ps aux --sort=-%cpu | head -n 4
}

check_memory() {
    print_header "2. Pamięć RAM i logi jądra"

    echo "Stan pamięci fizycznej i Swap:"
    free -h

    echo -e "\nSprawdzenie OOM Killera (zabijanie procesów z braku RAM):"
    if dmesg -T 2>/dev/null | grep -i oom; then
        echo "Ocena: [CRITICAL] Wykryto zabicie procesu przez OOM Killer w logach!"
        EXIT_CODE=2
    else
        echo "Ocena: [OK] Brak incydentów OOM Killer (system stabilny)."
    fi
}

check_disk() {
    print_header "3. Przestrzeń dyskowa i inody"

    echo "Zajętość dysku głównego (GB):"
    df -h /

    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$DISK_USAGE" = "/" ]; then
        DISK_USAGE=$(df -h / | awk 'NR==2 {print $4}' | tr -d '%')
    fi
    
    if [ "$DISK_USAGE" -ge 90 ]; then
        echo -e "\nOcena: [CRITICAL] Dysk zapełniony w ${DISK_USAGE}% (powyżej 90%)!"
        EXIT_CODE=2
    elif [ "$DISK_USAGE" -ge 80 ]; then
        echo -e "\nOcena: [WARN] Dysk zapełniony w ${DISK_USAGE}% (powyżej 80%)!"
        [ "$EXIT_CODE" -lt 1 ] && EXIT_CODE=1
    else
        echo -e "\nOcena: [OK] Dysk w normie (${DISK_USAGE}% zajętości)."
    fi

    echo -e "\nLimit i-węzłów (indeksów plików):"
    df -i /
}

check_network() {
    print_header "4. Sieć i porty nasłuchujące"

    echo "Otwarte porty (nasłuchujące usługi TCP i UDP):"
    ss -tuln

    echo -e "\nSkonfigurowane serwery DNS (/etc/resolv.conf):"
    grep "nameserver" /etc/resolv.conf
}

check_security() {
    print_header "5. Szybki audyt bezpieczeństwa"

    echo "Użytkownicy z uprawnieniami roota (UID 0 w /etc/passwd):"
    ROOT_USERS=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
    echo "Konta: $ROOT_USERS"
    
    if [ "$ROOT_USERS" = "root" ]; then
        echo "Ocena: [OK] Tylko konto 'root' posiada UID 0."
    else
        echo "Ocena: [CRITICAL] Wykryto nieautoryzowane konta z UID 0: $ROOT_USERS"
        EXIT_CODE=2
    fi

    echo -e "\nUprawnienia do plików krytycznych:"
    ls -l /etc/passwd /etc/shadow /etc/sudoers 2>/dev/null || true
}

main() {
    echo "Raport diagnostyczny serwera: $(hostname) ($(whoami)) - $(date '+%Y-%m-%d %H:%M:%S')"

    check_cpu
    check_memory
    check_disk
    check_network
    check_security

    echo ""
    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "Podsumowanie: Wszystkie testy zaliczone [OK]."
    elif [ "$EXIT_CODE" -eq 1 ]; then
        echo "Podsumowanie: Wykryto ostrzeżenia [WARN]."
    else
        echo "Podsumowanie: Wykryto błędy krytyczne [CRITICAL]!"
    fi

    exit "$EXIT_CODE"
}

main
