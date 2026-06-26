# Sync-Marketing-Mess

Scripts to download and process the PF Concept marketing data feeds (product +
print data) and extract image filename lists from them.

## Data feeds

Two JSON feeds are downloaded from `https://www.pfconcept.com/portal/datafeed/`:

| Feed | File | Approx size | Format docs |
|------|------|-------------|-------------|
| Print data | `printdata_cse1_fi_v3.json` | ~9 MB (minified) | [printdata_model.md](printdata_model.md) |
| Product catalogue | `productfeed_en_v3.json` | ~189 MB (pretty-printed) | [productfeed_model.md](productfeed_model.md) |

> The `.json` feeds and their `.bak` backups are **git-ignored** — regenerate them
> with the download scripts.

## Scripts

Every script has a Windows (PowerShell, `.ps1`) and a Linux/macOS (Bash, `.sh`)
version. The Bash versions are tested on CentOS Stream 9 (GNU grep/sed/coreutils).

### Download the feeds

Downloads both feeds, validates each as JSON, and keeps the previous copy as
`<file>.bak`. A temp file is used so a failed download never corrupts the existing
data; one feed failing does not stop the others.

```bash
# Windows
./download_json_files.ps1
# Linux / macOS
./download_json_files.sh
```

Override the URL list with `-Urls` (PowerShell) or positional arguments (Bash).

### Extract print image filenames

Extracts every `.jpg` from the `imagePrintLine` fields in the print feed →
`imageprintlines.txt` (unique, sorted, one per line).

```bash
# Windows
./extract-imageprintlines.ps1
# Linux / macOS
./extract-imageprintlines.sh
```

### Extract product image filenames

Extracts every filename from the `imageData` slots in the product feed →
`imagedata_filenames.txt` (unique, sorted, one per line).

```bash
# Windows
./extract-imagedata.ps1
# Linux / macOS
./extract-imagedata.sh
```

All extract scripts **stream** their input (no full-file load into memory) and
accept optional input/output path arguments.

### Scan for missing images

Checks whether every filename in a generated image list exists in each **target**
directory listed in a locations CSV (columns `type,target,source`). Missing files
are reported, along with whether they exist in the matching **source** directory.
With `--fix`, files missing from target but present in source are copied across
(`/bin/cp -p`, bypassing the CentOS `cp='cp -i'` alias). Linux/macOS only.

```bash
# Print images  (imageprintlines.txt vs imageprintlines_locations.csv)
./scanmissing-imageprintlines.sh          # report only
./scanmissing-imageprintlines.sh --fix    # copy missing files from source

# Product images  (imagedata_filenames.txt vs imagedata_locations.csv)
./scanmissing-imagedata.sh                # report only
./scanmissing-imagedata.sh --fix          # copy missing files from source
```

Add `--verbose` to also report files that **are** present in the target (with
their size). Both accept optional `[csv-file] [filelist]` positional arguments and
exit non-zero if any file is missing from both target and source (or a copy failed).

## Typical workflow

```bash
./download_json_files.sh          # fetch both feeds
./extract-imageprintlines.sh      # -> imageprintlines.txt
./extract-imagedata.sh            # -> imagedata_filenames.txt
./scanmissing-imageprintlines.sh  # check print images against target dirs
./scanmissing-imagedata.sh        # check product images against target dirs
```

On Linux, make the scripts executable first:

```bash
chmod +x *.sh
```

## Repository contents

| File | Purpose |
|------|---------|
| `download_json_files.ps1` / `.sh` | Download both data feeds |
| `extract-imageprintlines.ps1` / `.sh` | Print-feed `imagePrintLine` image list |
| `extract-imagedata.ps1` / `.sh` | Product-feed `imageData` image list |
| `scanmissing-imageprintlines.sh` | Check print images against target dirs (`--fix` to copy) |
| `scanmissing-imagedata.sh` | Check product images against target dirs (`--fix` to copy) |
| `printdata_model.md` | Print feed format reference |
| `productfeed_model.md` | Product feed format reference |
| `imageprintlines_locations.csv` | Print-image target/source directory map |
| `imagedata_locations.csv` | Product-image target/source directory map |
| `imageprintlines.txt` | Generated print image list |
| `imagedata_filenames.txt` | Generated product image list |
