# Server Healthcheck CLI

Lekki skrypt diagnostyczny w Bashu do szybkiej weryfikacji stanu serwera Linux (procesor, pamięć RAM, dysk, sieć i podstawowe bezpieczeństwo).

---

## Moduły diagnostyczne

1. **CPU & Load:**
   * Czas pracy i średnie obciążenie (*Load Average*) z polecenia `uptime`.
   * Liczba dostępnych rdzeni/wątków CPU (`nproc`).
   * 3 procesy zużywające najwięcej procesora (`ps aux`).

2. **Pamięć RAM i Jądro:**
   * Zużycie pamięci fizycznej oraz przestrzeni wymiany Swap (`free -h`).
   * Inspekcja logów jądra pod kątem zabicia procesów przez mechanizm OOM Killer (`dmesg`).

3. **Przestrzeń Dyskowa i I-węzły:**
   * Zajętość głównego systemu plików (`df -h`).
   * Kontrola puli i-węzłów (`df -i`) pod kątem wyczerpania tablicy deskryptorów plików.

4. **Sieć i Porty:**
   * Lista otwartych portów i nasłuchujących procesów (`ss -tuln`).
   * Aktywne serwery DNS w `/etc/resolv.conf`.

5. **Bezpieczeństwo:**
   * Wykrywanie kont z uprawnieniami roota (`UID 0` w `/etc/passwd`).
   * Weryfikacja uprawnień do kluczowych plików systemowych (`/etc/passwd`, `/etc/shadow`, `/etc/sudoers`).

---

## Uruchomienie

### 1. Bezpośrednio na serwerze:
```bash
chmod +x server-healthcheck.sh
./server-healthcheck.sh
```

### 2. W kontenerze Docker (izolowane środowisko testowe):
```bash
docker compose run --rm healthcheck
```

### 3. Automatyzacja co 5 minut (Systemd Timer):
Zamiast przestarzałego crona, wdrożenie cyklicznego uruchamiania realizowane jest przez jednostkę `systemd timer`:

```bash
# Kopiowanie plików jednostek systemd
sudo cp server-healthcheck.sh /usr/local/bin/
sudo cp systemd/server-healthcheck.* /etc/systemd/system/

# Przeładowanie i uruchomienie timera
sudo systemctl daemon-reload
sudo systemctl enable --now server-healthcheck.timer

# Sprawdzenie statusu i harmonogramu
systemctl list-timers | grep healthcheck

# Podgląd logów z wykonań
journalctl -u server-healthcheck.service -n 50
```

---

## Przykładowy raport

```text
Raport diagnostyczny serwera: srv-app-01 (dev) - 2026-10-05 19:42:40

=== 1. Procesor i obciążenie systemu ===
Czas pracy i Load Average:
 19:42:40 up  4:07,  0 users,  load average: 0.14, 0.18, 0.12

Liczba rdzeni CPU:
Liczba rdzeni: 20

Top 3 procesy według użycia CPU:
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
dev            1 88.0  1.5 2423756 120480 pts/0  Sl   19:42   0:00 app-service

=== 2. Pamięć RAM i logi jądra ===
Stan pamięci fizycznej i Swap:
               total        used        free      shared  buff/cache   available
Mem:           7.6Gi       2.1Gi       5.1Gi       3.6Mi       548Mi       5.5Gi
Swap:          2.0Gi          0B       2.0Gi

Sprawdzenie OOM Killera (zabijanie procesów z braku RAM):
Ocena: [OK] Brak incydentów OOM Killer (system stabilny).

=== 3. Przestrzeń dyskowa i inody ===
Zajętość dysku głównego (GB):
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   15G   35G   30% /

Ocena: [OK] Dysk w normie (30% zajętości).

Limit i-węzłów (indeksów plików):
Filesystem     Inodes IUsed  IFree IUse% Mounted on
/dev/sda1     3276800 85000 3191800   3% /

=== 4. Sieć i porty nasłuchujące ===
Otwarte porty (nasłuchujące usługi TCP i UDP):
Netid   State   Recv-Q   Send-Q     Local Address:Port      Peer Address:Port   
tcp     LISTEN  0        128        0.0.0.0:22              0.0.0.0:*           
tcp     LISTEN  0        511        0.0.0.0:80              0.0.0.0:*           

Skonfigurowane serwery DNS (/etc/resolv.conf):
nameserver 1.1.1.1
nameserver 8.8.8.8

=== 5. Szybki audyt bezpieczeństwa ===
Użytkownicy z uprawnieniami roota (UID 0 w /etc/passwd):
Konta: root
Ocena: [OK] Tylko konto 'root' posiada UID 0.

Uprawnienia do plików krytycznych:
-rw-r--r-- 1 root root   1374 Oct  1 19:46 /etc/passwd
-rw-r----- 1 root shadow  775 Oct  1 21:53 /etc/shadow
-r--r----- 1 root root   1800 Jan 21  2026 /etc/sudoers

Podsumowanie: Wszystkie testy zaliczone [OK].
```

---

## Struktura projektu

```text
.
├── server-healthcheck.sh           # Główny skrypt diagnostyczny
├── systemd/
│   ├── server-healthcheck.service  # Definicja usługi oneshot
│   └── server-healthcheck.timer    # Cykliczny harmonogram (co 5 minut)
├── Dockerfile                      # Środowisko testowe w kontenerze Ubuntu
├── docker-compose.yml              # Konfiguracja uruchomieniowa Dockera
├── .gitignore                      # Ignorowanie plików tymczasowych
└── README.md                       # Dokumentacja projektu
```
