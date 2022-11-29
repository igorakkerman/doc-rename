$VerbosePreference = "Continue"

Get-ChildItem -filter *.pdf  | Where-Object {$_.LastWriteTime -ge "2022-10-01"} | ForEach-Object <# -Parallel #> {

    $filename = $_.Name
    
    $textContent = pdftotext -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "Patreon") {
        Write-Output "Not from Patreon. Ignoring ${filename}"
        Return
    }

    if ( ${textContent} -cmatch "(?s).*CREATOR\s+([^\n^\r]+).*") {
        $creator = $matches[1]

        Write-Verbose "Creator: $creator"
    }

    if ( ${textContent} -cmatch "(?s).*Invoice #:\s+([^\s]+).*") {
        $invoiceNumber = $matches[1]
    }

    if ( ${textContent} -cmatch "(?s).*Invoice date:\s+(\d{1,2})/(\d{1,2})/(\d{2}).*") {
        $invoiceDay = $matches[2] -replace '^(\d)$','0$1'
        $invoiceMonth = $matches[1] -replace '^(\d)$','0$1'
        $invoiceYear = "20$($matches[3])"

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}

        Write-Verbose "Invoice date: $invoiceDate"
    }
    
    if ( ${textContent} -cmatch "(?s).*EUR.+EUR\s+(\d+)\.(\d{2}).*") { 
        $invoiceAmount = "$($matches[1]),$($matches[2])"

        Write-Verbose "Invoice amount: $invoiceAmount"
    }
    
    # Write-Output "${filename}: ${invoiceNumber} ${invoiceDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid invoice data. Ignoring ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Rechnung ${creator} ${invoiceNumber} ${invoiceAmount}€.pdf"

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

New-Item -ItemType Directory -Force signature | Out-Null
Move-Item *.ads signature
