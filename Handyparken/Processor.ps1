Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext.exe -enc UTF-8 -layout ${filename} - | Out-String

    $invoiceNumber = ${textContent} -replace "(?s).*Bestellnummer:\W*([A-Z0-9]+).*", '$1'
    $invoiceDate = ${textContent} -replace "(?s).*Gültig ab:\W*([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).*Betrag:\W*([0-9]+,[0-9][0-9]).*", '$1'
    $parkingLocation = ${textContent} -replace "(?s).*Parkscheinautomat:\W*[0-9]+,\W*([A-Za-z.]+).*", '$1'

    if (${textContent} -in ${invoiceNumber}, ${invoiceDate}, ${invoiceAmount}, ${parkingLocation}) {
        Write-Host "Invalid data. Ignoring ${filename}"
        Return
    }

    $index = 0;
    do {
        ${index}++

        $newFilename = "${invoiceDate} 0${index} Rechnung Parken Projektarbeit ${parkingLocation} ${invoiceNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Host "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

