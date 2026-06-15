# Data source cache for tool/import.dart

Raw dictionary downloads. Re-fetch with the commands below (Git Bash),
then run `dart run tool/import.dart` from the project root.

Note: `ftp.edrdg.org` has a certificate mismatch over HTTPS — use plain
HTTP for the EDRDG files.

```sh
cd tool/cache

# KANJIDIC2 (kanji meanings/readings/JLPT) — EDRDG, CC BY-SA
curl -sSL -o kanjidic2.xml.gz http://www.edrdg.org/kanjidic/kanjidic2.xml.gz
gzip -dkf kanjidic2.xml.gz

# KanjiVG (stroke paths/order) — Ulrich Apel, CC BY-SA 3.0
curl -sSL -o kanjivg.xml.gz https://github.com/KanjiVG/kanjivg/releases/download/r20250816/kanjivg-20250816.xml.gz
gzip -dkf kanjivg.xml.gz && mv kanjivg-20250816.xml kanjivg.xml

# KRADFILE (kanji -> component decomposition) — EDRDG licence; EUC-JP!
curl -sSL -o kradfile.gz http://ftp.edrdg.org/pub/Nihongo/kradfile.gz
gzip -dkf kradfile.gz
iconv -f EUC-JP -t UTF-8 kradfile > kradfile.utf8

# JMdict, English glosses (vocabulary) — EDRDG, CC BY-SA
curl -sSL -o jmdict_e.gz http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz
gzip -dkf jmdict_e.gz && mv jmdict_e jmdict_e.xml
```

jmdict_e.xml is ~62 MB decompressed; consider committing only the .gz
(GitHub warns on files over 50 MB).
