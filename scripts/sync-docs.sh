#!/bin/sh
set -eu

DOCS_DIR="docs"
HTML_FILE="these_brieuc.html"
QMD_FILE="these_brieuc.qmd"
DOCX_FILE="these_brieuc.docx"
PDF_FILE="these_brieuc.pdf"
HTML_ASSETS_DIR="these_brieuc_files"

mkdir -p "${DOCS_DIR}"
rm -f "${DOCS_DIR}/styles.css"
cp "${HTML_FILE}" "${DOCS_DIR}/"
cp "${QMD_FILE}" "${DOCS_DIR}/"
cp "${DOCX_FILE}" "${DOCS_DIR}/"
cp "${PDF_FILE}" "${DOCS_DIR}/"

if [ -d "${HTML_ASSETS_DIR}" ]; then
  rm -rf "${DOCS_DIR}/${HTML_ASSETS_DIR}"
  cp -R "${HTML_ASSETS_DIR}" "${DOCS_DIR}/"
fi

cat > "${DOCS_DIR}/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Stats Thèse Brieuc</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f6f7f9;
      --card: #ffffff;
      --text: #18222c;
      --muted: #5b6773;
      --line: #d7dde4;
      --accent: #12324a;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      font-family: Georgia, "Times New Roman", serif;
      background: var(--bg);
      color: var(--text);
    }
    main {
      width: min(560px, 100%);
      padding: 32px 28px;
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 16px;
    }
    h1 {
      margin: 0 0 10px;
      font-size: 1.8rem;
      font-weight: 600;
    }
    p {
      margin: 0 0 24px;
      color: var(--muted);
      line-height: 1.5;
    }
    nav {
      display: grid;
      gap: 12px;
    }
    a {
      display: block;
      padding: 14px 16px;
      border: 1px solid var(--line);
      border-radius: 12px;
      color: var(--accent);
      text-decoration: none;
      background: #fff;
    }
    a:hover,
    a:focus {
      border-color: #9eb0c0;
      background: #fbfcfd;
    }
    .meta {
      font-size: 0.95rem;
    }
  </style>
</head>
<body>
  <main>
    <h1>Stats Thèse Brieuc</h1>
    <p>Choisissez le format à consulter ou à télécharger.</p>
    <nav aria-label="Formats du rapport">
      <a href="these_brieuc.html">Affichage web (HTML)</a>
      <a href="these_brieuc.pdf" download="these_brieuc.pdf">Fichier PDF</a>
      <a href="these_brieuc.docx" download="these_brieuc.docx">Fichier DOCX</a>
      <a href="these_brieuc.qmd" download="these_brieuc.qmd">Code R source</a>
    </nav>
  </main>
</body>
</html>
EOF
