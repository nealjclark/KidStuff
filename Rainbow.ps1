While($true){
    $typing = Read-Host "Type Here"
    if(!$typing){
        1,2,3,4,6,9,10,11,12,12,13,13,13,13,14| ForEach-Object{Write-Host -ForegroundColor $_ "$words"}
        #for($i = 1;$i-lt 16; $i++){Write-Host -ForegroundColor $i "$words"}
    }
    else{
        $words = $typing
        1,2,3,4,6,9,10,11,12,12,13,13,13,13,14| ForEach-Object{Write-Host -ForegroundColor $_ "$words"}
        #for($i = 1;$i-lt 16; $i++){Write-Host -ForegroundColor $i "$words"}
    }
}