#!/bin/bash
# Download Tesseract language data files for OCR
# Source: https://github.com/tesseract-ocr/tessdata (Apache 2.0 License)

TESSDATA_DIR="$(cd "$(dirname "$0")/../android/app/src/main/assets/tessdata" && pwd)"
mkdir -p "$TESSDATA_DIR"

BASE_URL="https://github.com/tesseract-ocr/tessdata/raw/main"

# Languages to download
LANGUAGES=(
    "eng"       # English
    "chi_sim"   # Simplified Chinese
    "chi_tra"   # Traditional Chinese
    "jpn"       # Japanese
    "kor"       # Korean
)

echo "Downloading tessdata to: $TESSDATA_DIR"

for lang in "${LANGUAGES[@]}"; do
    if [ -f "$TESSDATA_DIR/${lang}.traineddata" ]; then
        echo "  [skip] ${lang}.traineddata already exists"
    else
        echo "  [downloading] ${lang}.traineddata ..."
        curl -sL "${BASE_URL}/${lang}.traineddata" -o "$TESSDATA_DIR/${lang}.traineddata"
        if [ $? -eq 0 ] && [ -s "$TESSDATA_DIR/${lang}.traineddata" ]; then
            size=$(du -h "$TESSDATA_DIR/${lang}.traineddata" | cut -f1)
            echo "  [ok] ${lang}.traineddata ($size)"
        else
            echo "  [FAIL] ${lang}.traineddata download failed"
            rm -f "$TESSDATA_DIR/${lang}.traineddata"
        fi
    fi
done

echo ""
echo "Done. Total size:"
du -sh "$TESSDATA_DIR"
