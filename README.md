# Cocolani Islands - Server Emulator

This is a custom made server emulator for Cocolani Islands, built as a set of ActionScript extensions running on SmartFoxServer PRO 1.6.6.

---

## Requirements

### SmartFoxServer PRO 1.6.6

You need SmartFoxServer PRO version 1.6.6.

You can find archived copies at:
- https://www.smartfoxserver.com (A free version has a limit of 20 connected clients, but you can bypass that..)

### MySQL Connector/J for Smart Fox Server
  If you don't have it then download it from here: https://dev.mysql.com/downloads/connector/j/
  select version mysql-connector-java-5.1.49 and platform should be "Platform Independent"
  then put it inside ``SmartFoxServerPRO_1.6.6\Server\lib``


### XAMPP (Old Version)

The game PHP code requires an old version of XAMPP to match the original environment.
So you should use a version that is **XAMPP 1.x** (PHP 5.x compatible).


You can download old XAMPP releases from:
https://sourceforge.net/projects/xampp/files

---

## Setup

### 1. Install XAMPP

Install XAMPP. Start Apache and MySQL services from the XAMPP Control Panel.

### 2. Import the Database

1. Open phpMyAdmin at `http://localhost/phpmyadmin`
2. Create a new database named `cocolani_battle`
3. Import the file `cocolani_battle.sql` into that database

### 3. Configure the Server

1. Copy `Config_template.xml` to `Server/config.xml`
2. Edit `Server/config.xml` if you need to change the server IP or port or db info.
3. By default the server listens on all interfaces (`*`) on port **9339**

### 4. Place the Extensions

The extension files under `/src/*.as` must be in the correct location inside the SmartFoxServer extensions folder. They are already placed at:

```
Server/sfsExtensions/cocolani/src/*.as
```

SmartFoxServer will load them automatically based on the zone configuration in `config.xml`.
Change the `confing.xml` if you want to change the path.

### 5. Start the Server

Run the server by double-clicking:

```
start.bat
```

This is located in the root of the `SmartFoxServerPRO_1.6.6` folder. It changes into the `Server/` directory and launches `Server/start.bat`, which starts SmartFoxServer using the bundled JRE.

A console window will open. The server is ready when you see the startup messages without errors.

---

## Extension Files

| File | Description |
|---|---|
| `main.as` | Core extension, handles movement, chat, and main commands |
| `cocolani.as` | Main island/world logic |
| `home.as` | Player home/house logic |
| `gameManager.as` | Manages minigame sessions |
| `gamesRoom.as` | Games room handling |
| `battleGame1.as` | Battle minigame logic |
| `puzzle_handler.as` | Puzzle minigame logic |
| `raceController.as` | Tube ride logic |
| `jungle_temple.as` | Jungle Temple scene logic |
| `admin.as` | Admin panel commands and moderation tools |

---

## Notes
- This was made in a rush (about 2 weeks), expect bugs but I tested the emulator very well from tutorial stage to solving puzzels and battling. if you find any bugs, feel free to open an issue.
- The database is already populated with all the data the server needs
- I highly recommend upgrading the XAMPP & PHP version if you are going live with this.
- The server port is **9339** by default. Make sure no firewall is blocking it if you are going live with this.
- The extensions are written in ActionScript 2 (server-side JS-like scripting used by SmartFoxServer).
- Database credentials are configured inside `config.xml` under the database connection section and in ``db.php`` in the game php files.
- Add ``-Dfile.encoding=UTF-8`` to ``Server/start.bat`` if you want to use Arabic in Smart Fox Server.
## Credits
- Cyborg
- Kyelo (ksahamad)
