Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext -enc Latin1  ${filename} - | Out-String

    $invoiceNumber = ${textContent} -replace "(?s).*`nM[0-9]+ ([0-9]+).*", '$1'
    $invoiceDate =   (${textContent} -replace "(?s).*`nM[0-9]+ [0-9]+ ([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1')
    $invoiceAmount = (${textContent} -replace "(?s).*Betr.ge \(EUR\).*?([0-9]+,[0-9][0-9])`r`n`r`n.*", '$1')

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Host "Ignoring   ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Rechnung ${invoiceNumber} ${invoiceAmount}€.pdf"

    Write-Host "'${filename}' becomes '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}
