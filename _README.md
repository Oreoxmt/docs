# Steps

1. Update the `_doc.md` and update all internal links using:

    Search: `\(/.*?([^/]*?)\.md(#(?:.*?))?\)`
    Replace: `(https://docs.pingcap.com/$1$2)`

2. Update the `_doc-tables.html`
3. Generate docx:

    ```
    pandoc --reference-doc=custom-pdf-reference.docx _doc.md -o _doc.docx
    pandoc --reference-doc=custom-pdf-reference.docx _doc-tables.html -o _doc-tables.docx
    ```