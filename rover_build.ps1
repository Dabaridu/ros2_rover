docker build -t rover .
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
