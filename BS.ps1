<#
    
    TODO:
        BUG REPORT:
            - Fix Game over after sinking last ship the computer gets an additional turn
            - Fix computer AI when firing at a vertical ship it shoots at the sides of the ship instead of the consecutive hits. 


    0 DE - Destroyer  = 2
    1 SU - Submarine  = 3
    2 CR - Cruiser    = 3
    3 BA - Battleship = 4
    4 CA - Carrier    = 5

#>
param(
    
    $multiplayer,
    [switch]$DebugMode,
    [switch]$Mute
)
$global:SoundHit = '.\sounds\Hit.wav'
$global:SoundMiss = '.\sounds\Miss.wav'
$global:Victory = '.\sounds\victory.wav'
$global:Defeat = '.\sounds\gameover.wav'

function Set-InitialBoard{
    param(
        [switch]$Random
    )
    $NewBoard = New-Object 'object[,]' 10,10
    $NotPlaced = $true
    $CleanPlacement = $true
    $ships = New-Object psobject @{    
        DE = 2
        SU = 3
        CR = 3
        BA = 4
        CA = 5
    }
    foreach($ship in $ships.keys){
#        write-host "setting ship $ship"

        #Search for clean placement
        while($NotPlaced){
            $Orientation = Get-Random  up,down,left,right
        
            switch ($Orientation){
                'up' {
                    $xdirection = 0
                    $ydirection = -1
                }
                'down' {
                    $xdirection = 0
                    $ydirection = 1
                }
                'left' {
                    $xdirection = -1
                    $ydirection = 0
                }
                'right' {
                    $xdirection = 1
                    $ydirection = 0          
                }
            }
            #Write-Host "o: $Orientation x: $xdirection y: $ydirection"
            #Write-Host "testing placement of $ship"
            $X = Get-Random -Maximum 10
            $Y = Get-Random -Maximum 10  
            #write-host "start point [$x, $y]"
            if($NewBoard[$x,$y] -eq $null){  
                # Test all spots before placing
                for($i=1;$i -lt $ships.$ship;$i++){
                    if(( (($x + ($i * $xdirection))-ge 0)-and(($x + ($i * $xdirection))-lt 10)-and ( (($y + ($i * $ydirection))-ge 0)-and(($y + ($i * $ydirection))-lt 10)) )){
                        if($NewBoard[($x + ($i * $xdirection)),($y + ($i * $ydirection))] -ne $null ){  
                            $CleanPlacement = $false
                            #Write-Host "failed placement of $ship"
                        }
                    }
                    else{
                        $CleanPlacement = $false
                        #Write-Host "went out of bounds on $ship"
                    }
                }
                # If test placement succeeds place the ships assign name of ship.
                if($CleanPlacement){
                    $NewBoard[$x,$y] = $ship
                    #Write-Host "board[$x,$y] set to $ship"
                    for($i=1;$i -lt $ships.$ship;$i++){
                        $NewBoard[($x + ($i * $xdirection)),($y + ($i * $ydirection))] = $ship
                        $NotPlaced = $false
                    }
                }
                else{
                    $CleanPlacement = $true
                }
            }
        }# Close the placement loop for this ship
        $NotPlaced = $true
    } # Start Next ship
    #return the new board
    return ,$NewBoard
}
function test-parity{
        for($y=0;$y-lt 10;$y++){
            for($x=0;$x-lt 10;$x++){
                if($OpponentMap[$x,$y] -eq "P"){
                    Write-Host "P" -NoNewline
                }
                else{
                    Write-Host "O" -NoNewline
                }
            }
            Write-Host " "
        }
}
# Sets board to only attack certain squares based on length of shortest ship.
function Set-ComputerMapParity{
    $SmallestShip = (($PlayerShips | where{$_.sunk -eq $false}).shiplength | measure -Minimum).Minimum
    if($SmallestShip -gt 1){
        $counter = 1
        #Clears previous attack map before setting new one 
        if($SmallestShip -ne 2){
            for($y=0;$y-lt 10;$y++){
                for($x=0;$x-lt 10;$x++){
                    if($OpponentMap[$x,$y] -like "P"){
                        $OpponentMap[$x,$y] = $null
                    }
                }
            }
        }
        #sets all odd numbered squares to P
        for($y=0;$y-lt 10;$y++){
            for($x=0;$x-lt 10;$x++){
                if(!(($x+$counter) % $SmallestShip) -and ($OpponentMap[$x,$y] -eq $null)){
                    $OpponentMap[$x,$y] = "P" 
                }
            
            }
            $counter++
            if($counter -gt $SmallestShip){$counter=1}
        }
    }
}

#display board
function Show-Board($board, $ShipDisplay){
    #Display Header # Row
    write-host "    1  2  3  4  5  6  7  8  9  10"

    #Iterate through each row going down the Y axis.
    for($y=0;$y-lt10;$y++){
        #Write the first Column A-J
        write-host (" " + ([char](65+$y)) + " ") -ForegroundColor DarkGray -NoNewline
        #Cycle through next column 
        for($x=0;$x -lt 10;$x++){
            if($debug){
                $board[$x,$y]
                $currentPosition 
                "X: $x"
                "y: $y"
            }
            #Set Color array {Backcolor/sink, ForColor} to dictate how square is colored.
            $color = switch($board[$x,$y]){
                #Missed shot
                'M' {"white", “white”}
                #Ship - Intact
                'DE' {"DarkGray", "gray"}
                'SU' {"DarkGray", "gray"}
                'CR' {"DarkGray", "gray"}
                'BA' {"DarkGray", "gray"}
                'CA' {"DarkGray", "gray"}
                #Ship - Hit
                'HDE' {"red", "DarkRed"}
                'HSU' {"red", "DarkRed"}
                'HCR' {"red", "DarkRed"}
                'HBA' {"red", "DarkRed"}
                'HCA' {"red", "DarkRed"}  
                #Ship - Sunk
                'XHDE' {"sink", "DarkRed"}
                'XHSU' {"sink", "DarkRed"}
                'XHCR' {"sink", "DarkRed"}
                'XHBA' {"sink", "DarkRed"}
                'XHCA' {"sink", "DarkRed"}                   
                #All untouched squares.
                default {"cyan", “white”}
            }
            if($color[0] -eq "sink"){
                Write-Host -BackgroundColor DarkRed -ForegroundColor Red " X " -NoNewline
            }
            else{
                Write-Host -BackgroundColor $color[0] -ForegroundColor $color[1] " O " -NoNewline
            }
        }
        Write-Host "    " -NoNewline   # spacer to make room for the ship status display.

        switch -regex ($ShipDisplay[$y]){
            #If the line is a ship format the ship display
            " O *" { Write-Host -BackgroundColor DarkGray -ForegroundColor Gray $ShipDisplay[$y]}
            " X *" { Write-Host -BackgroundColor DarkRed  -ForegroundColor Red $ShipDisplay[$y]}
            #If the line is the shipname output it. 
            default {Write-Host $ShipDisplay[$y]}
        }
    }
}

function Start-ComputerTurn{
    $up = "OB"
    $down = "OB"
    $left = "OB"
    $right = "OB"
    $x = 0
    $y = 0 
    $Attacked = $false
    $attackX = $null
    $attackY = $null
    $streak = $false
    #if there is a hit check surrounding spaces
    if($OpponentMap -like "H*"){
        while(($x -lt 10) -and (!$Attacked)){
            $y=0
            While(($y -lt 10) -and (!$Attacked)){
                # Search for a hit 
                if($OpponentMap[$x,$y] -like "H*"){
                    #check up $y-1
                    if($y -gt 0){
                        $up = $OpponentMap[$x,($y-1)]                             
                    }
                    #check Down $y+1
                    if($y -lt 9){
                        $down = $OpponentMap[$x,($y+1)]                             
                    }
                    #check Left $x-1
                    if($x -gt 0){
                        $left = $OpponentMap[($x-1),$y]
                    }
                    #check Right
                    if($x -lt 9){
                        $right = $OpponentMap[($x+1),$y]
                    }

                    #check for streaks 
                    if ($up -like "H*" -and ((!$down -or ($down -eq "P")) -and ($down -ne "OB") )){
                        $attackX = $x
                        $attackY = $y+1
                        $streak = $true
                    }
                    elseif ($down -like "H*" -and ((!$up -or ($up -eq "P")) -and ($up -ne "OB") )){
                        $attackX = $x
                        $attackY = $y-1
                        $streak = $true
                    }
                    elseif ($left -like "H*" -and ((!$right -or ($right -eq "P")) -and ($right -ne "OB") )){
                        $attackX = $x+1
                        $attackY = $y
                        $streak = $true
                    }
                    elseif ($right -like "H*" -and ((!$left -or ($left -eq "P")) -and ($left -ne "OB") )){
                        $attackX = $x-1
                        $attackY = $y
                        $streak = $true
                    }

                    #perform Attack if streak attack opened space. else find another open spot to attack. 
                    if ($streak){
                        [string]$ConvertedY = [char]($attackY + 65)
                        $ConvertedX = $attackX + 1
                        $global:opponentAttack = ($ConvertedY + "$ConvertedX")
                        $global:OpponentResults = Check-OpponentAttack ($ConvertedY + "$ConvertedX")
                        $Attacked = $true
                    }
                    else{
                        if((!$up -or ($up -eq "P")) -and ($up -ne "OB")){
                            $attackX =$x
                            $attackY = ($y - 1)
                            [string]$ConvertedY = [char]($attackY + 65)
                            $ConvertedX = $attackX + 1
                            $global:opponentAttack = ($ConvertedY + "$ConvertedX")
                            $global:OpponentResults = Check-OpponentAttack ($ConvertedY + "$ConvertedX")
                            $Attacked = $true
                        }
                        elseif((!$left -or ($left -eq "P")) -and ($left -ne "OB")){
                            $attackX =$x-1
                            $attackY = $y
                            [string]$ConvertedY = [char]($attackY + 65)
                            $ConvertedX = $attackX + 1
                            $global:opponentAttack = ($ConvertedY + "$ConvertedX")
                            $global:OpponentResults = Check-OpponentAttack ($ConvertedY + "$ConvertedX")
                            $Attacked = $true
                        }
                        elseif((!$right -or ($right -eq "P")) -and ($right -ne "OB")){
                            $attackX =$x+1
                            $attackY = $y
                            [string]$ConvertedY = [char]($attackY + 65)
                            $ConvertedX = $attackX + 1
                            $global:opponentAttack = ($ConvertedY + "$ConvertedX")
                            $global:OpponentResults = Check-OpponentAttack ($ConvertedY + "$ConvertedX")
                            $Attacked = $true
                        }
                        elseif((!$down -or ($down -eq "P")) -and ($down -ne "OB")){
                            $attackX =$x
                            $attackY = $y+1
                            [string]$ConvertedY = [char]($attackY + 65)
                            $ConvertedX = $attackX + 1
                            $global:opponentAttack = ($ConvertedY + "$ConvertedX")
                            $global:OpponentResults = Check-OpponentAttack ($ConvertedY + "$ConvertedX")
                            $Attacked = $true
                        }
                    }

                }
                $y++
            }
            $x++
        }

    }#close There is a hit ship not sunk yet.
    Else{
        
        do{
            $x = Get-Random -Maximum 10
            $y = Get-Random -Maximum 10
        }until($OpponentMap[$x,$y] -eq "P")
        
        [string]$Convertedy = [char]($y + 65)
        $ConvertedX = $x + 1
        $global:opponentAttack = ($ConvertedY + "$ConvertedX")
        $global:OpponentResults = Check-OpponentAttack ($ConvertedY + "$ConvertedX")
    }



}
function Check-OpponentAttack([string]$row, $x){

    $CurrentHit = $null
    $sunk = $null
    $Result =$null
    $player = New-Object -TypeName System.Media.SoundPlayer


    if($x -eq $null){
        $y = ($row.ToUpper())[0]
        $x = [int]$row.Substring(1)
    }
    else{
        $y = $row.ToUpper()
    }
    $AdjustedX = $x - 1
    $AdjustedY = ([byte][char]$y) - 65
    if (!((($AdjustedX -ge 0)-and($AdjustedX -lt 10)) -and (($AdjustedY -ge 0)-and($AdjustedY -lt 10)))){
        Return "Invalid Re-Enter!"   
    }
    if (($PlayerBoard[$AdjustedX,$AdjustedY] -like "H*") -or (($OpponentMap[$AdjustedX,$AdjustedY] -like "M") -or ($PlayerBoard[$AdjustedX,$AdjustedY] -like "X*"))){
        Return "Already Tried that one!"
    }

    if($PlayerBoard[$AdjustedX,$AdjustedY]){
        # Load Current atack. 
        $CurrentHit = $PlayerBoard[$AdjustedX,$AdjustedY] 
        # Mark a Hit on the player map and the opponents ships
        $PlayerBoard[$AdjustedX,$AdjustedY] = "H" + $PlayerBoard[$AdjustedX,$AdjustedY]
        $OpponentMap[$AdjustedX,$AdjustedY] = $PlayerBoard[$AdjustedX,$AdjustedY]
        $player.SoundLocation = $global:SoundHit
        $player.Load()
        $player.Play()
        if(!($PlayerBoard -like "$CurrentHit")){
            $sunk = $CurrentHit
            #Set all pieces of boat to sunk. (mark with X)
            for($i=0;$i-lt10;$i++){
                for($j=0;$j-lt 10;$j++){
                    if($PlayerBoard[$i,$j] -like "*$CurrentHit"){
                        $PlayerBoard[$i,$j] = "X" + $PlayerBoard[$i,$j]
                        $OpponentMap[$i,$j] = $PlayerBoard[$i,$j]
                        $player.SoundLocation = $global:SoundHit
                        $player.Load()
                        $player.Play()
                    }
                }
            }
        }
    }
    else{
        $OpponentMap[$AdjustedX,$AdjustedY] = "M"
        $PlayerBoard[$AdjustedX,$AdjustedY] = "M"
        $player.SoundLocation = $global:SoundMiss
        $player.Load()
        $player.Play()
    }

    if($sunk){       
        switch($sunk){
            'DE' { $MyShipDisplay[1] = " X  X ";$PlayerShips[0].sunk = $true;Set-ComputerMapParity; return "Your Opponent Sunk your destroyer!"}
            'SU' { $MyShipDisplay[3] = " X  X  X ";$PlayerShips[1].sunk = $true;Set-ComputerMapParity; return "Your Opponent sunk your Submarine!" } 
            'CR' { $MyShipDisplay[5] = " X  X  X ";$PlayerShips[2].sunk = $true;Set-ComputerMapParity; return "Your Opponent sunk your Cruiser!"    }
            'BA' { $MyShipDisplay[7] = " X  X  X  X ";$PlayerShips[3].sunk = $true;Set-ComputerMapParity; return "Your Opponent sunk your Battleship!" }
            'CA' { $MyShipDisplay[9] = " X  X  X  X  X ";$PlayerShips[4].sunk = $true;Set-ComputerMapParity; return "Your Opponent sunk your Carrier!"   }
        }

    }
    return 
} #Close Check-OpponentAttack

# Will pause game for opponents turn to complete 
function wait-myturn($multiplayer){
    sleep -Seconds 3
    Start-ComputerTurn
    $turn++


    
}

function Check-Attack([string]$row, $x){
    $player = New-Object -TypeName System.Media.SoundPlayer
    if (!$row){
        Return "Invalid Re-Enter!" 
    }
    $CurrentHit = $null
    $sunk = $null
    $Result =$null
    if($x -eq $null){
        $y = ($row.ToUpper())[0]
        $x = [int]$row.Substring(1)
    }
    else{
        $y = $row.ToUpper()
    }
    $AdjustedX = $x - 1
    $AdjustedY = ([byte][char]$y) - 65
    if (!((($AdjustedX -ge 0)-and($AdjustedX -lt 10)) -and (($AdjustedY -ge 0)-and($AdjustedY -lt 10)))){
        Return "Invalid Re-Enter!"   
    }
    if (($OpponentBoard[$AdjustedX,$AdjustedY] -like "H*") -or (($PlayerMap[$AdjustedX,$AdjustedY] -eq "M") -or ($OpponentBoard[$AdjustedX,$AdjustedY] -like "X*"))){
        Return "Already Tried that one!"
    }

    if($OpponentBoard[$AdjustedX,$AdjustedY]){
        # Load Current atack. 
        $CurrentHit = $OpponentBoard[$AdjustedX,$AdjustedY] 
        # Mark a Hit on the player map and the opponents ships
        $OpponentBoard[$AdjustedX,$AdjustedY] = "H" + $OpponentBoard[$AdjustedX,$AdjustedY]
        $PlayerMap[$AdjustedX,$AdjustedY] = $OpponentBoard[$AdjustedX,$AdjustedY]
        $player.SoundLocation = $global:SoundHit
        $player.Load()
        $player.Play()

        if(!($OpponentBoard -like "$CurrentHit")){
            $sunk = $CurrentHit
            #Set all pieces of boat to sunk. (mark with X)
            for($i=0;$i-lt10;$i++){
                for($j=0;$j-lt 10;$j++){
                    if($OpponentBoard[$i,$j] -like "*$CurrentHit"){
                        $OpponentBoard[$i,$j] = "X" + $OpponentBoard[$i,$j]
                        $PlayerMap[$i,$j] = $OpponentBoard[$i,$j]
                        $player.SoundLocation = $global:SoundHit
                        $player.Load()
                        $player.Play()
                    }
                }
            }
        }
    }
    else{
        $PlayerMap[$AdjustedX,$AdjustedY] = 'M'
        $OpponentBoard[$AdjustedX,$AdjustedY] = 'M'
        $player.SoundLocation = $global:SoundMiss
        $player.Load()
        $player.Play()
    }

    if($sunk){
        
        switch($sunk){
            'DE' { $OpponentShipDisplay[1] = " X  X ";$OpponentShips[0].sunk = $true; return "You sunk my destroyer!"}
            'SU' { $OpponentShipDisplay[3] = " X  X  X ";$OpponentShips[1].sunk = $true; return "You sunk my Submarine!" } 
            'CR' { $OpponentShipDisplay[5] = " X  X  X ";$OpponentShips[2].sunk = $true; return "You sunk my Cruiser!"    }
            'BA' { $OpponentShipDisplay[7] = " X  X  X  X ";$OpponentShips[3].sunk = $true; return "You sunk my Battleship!" }
            'CA' { $OpponentShipDisplay[9] = " X  X  X  X  X ";$OpponentShips[4].sunk = $true; return "You sunk my Carrier!"   }
        }
    }
    return 
}
function Get-BoardDisplay{
    param(
    [switch]$defeated
    )
    if(!$DebugMode){clear}

    # Title display
    write-host "_________         __    __  .__           ________.__    .__        "
    write-host "\_____   \_____ _/  |__/  |_|  |   ____  /   ____/|  |__ |__|_____  "
    write-host " |   |  _/\__  \\   __\   __\  | _/ __ \ \____  \ |  |  \|  \____ \ "
    write-host " |   |   \ / __ \|  |  |  | |  |_\  ___/ /       \|   Y  \  |  |_> >"
    write-host " |_____  /(____  /__|  |__| |____/\___  >______  /|___|  /__|   __/ "
    write-host "       \/      \/                     \/       \/      \/   |__|    `n"

    Write-Host "Current Turn: $turn"        
    #Display attack map.
    #If Player1 loses display where shops are on opponent board. else display regular board with hidden ships. 
    if($defeated){
        Show-Board $OpponentBoard $OpponentShipDisplay
    }
    else{
        Show-Board $PlayerMap $OpponentShipDisplay
    }
    #Indicate players 2 activities. 
     if($global:GCconfig.tag){
        Write-Host ($global:GCconfig.tag) -ForegroundColor $global:GCconfig.color -NoNewline
     }
     else{
        Write-Host "Your opponent" -NoNewline
     }
     Write-Host " has attacked. " -NoNewline 
     Write-Host $global:opponentAttack -ForegroundColor Red -NoNewline
     Write-Host $global:OpponentResults
    #display Local players board
    Show-Board $PlayerBoard $MyShipDisplay


}

$OpponentMap = New-Object 'object[,]' 10,10
$OpponentBoard = Set-InitialBoard
$PlayerMap = New-Object 'object[,]' 10,10
$PlayerBoard = Set-InitialBoard
$inprogress = $true
$PlayerShips = @(
    [PSCustomObject]@{
        Name = "Destroyer"
        Abrv = "DE"
        ShipLength = 2
        sunk = $false
    }
    [PSCustomObject]@{
        Name = "Submarine"
        Abrv = "SU"
        ShipLength = 3
        sunk = $false
    }

    [PSCustomObject]@{
        Name = "Cruiser"
        Abrv = "CR"
        ShipLength = 3
        sunk = $false
    }

    [PSCustomObject]@{
        Name = "Battleship"
        Abrv = "BA"
        ShipLength = 4
        sunk = $false
    }
    [PSCustomObject]@{
        Name = "Carrier"
        Abrv = "CA"
        ShipLength = 5
        sunk = $false
    }
)

$OpponentShips = @(
    [PSCustomObject]@{
        Name = "Destroyer"
        Abrv = "DE"
        ShipLength = 2
        sunk = $false
    }
    [PSCustomObject]@{
        Name = "Submarine"
        Abrv = "SU"
        ShipLength = 3
        sunk = $false
    }

    [PSCustomObject]@{
        Name = "Cruiser"
        Abrv = "CR"
        ShipLength = 3
        sunk = $false
    }

    [PSCustomObject]@{
        Name = "Battleship"
        Abrv = "BA"
        ShipLength = 4
        sunk = $false
    }
    [PSCustomObject]@{
        Name = "Carrier"
        Abrv = "CA"
        ShipLength = 5
        sunk = $false
    }
)

Set-ComputerMapParity
$turn = 0
$DestroyedShips = 0
$OpponentShipDisplay = @("DESTROYER", " O  O ", "SUBMARINE", " O  O  O ", "CRUISER", " O  O  O ", "BATTLESHIP", " O  O  O  O ", "CARRIER", " O  O  O  O  O ")
$MyShipDisplay = @("DESTROYER", " O  O ", "SUBMARINE", " O  O  O ", "CRUISER", " O  O  O ", "BATTLESHIP", " O  O  O  O ", "CARRIER", " O  O  O  O  O ")
$attack = ""
$global:opponentAttack = ""
$global:OpponentResults = ""


#main game loop
    Get-BoardDisplay
while($inprogress){
    #Request action for from player 2
    #wait-myturn
    #$turn++
    #Get-BoardDisplay
    
    #Used for testing 
    if($DebugMode){
        Write-Host "Testing"
        Show-Board $OpponentBoard $MyShipDisplay
    }
    
    $PlayerShipsLeft = $PlayerShips | Where {$_.sunk -eq $false}

    if(!$PlayerShipsLeft){
        #Display all ships on board if player loses.
        Get-BoardDisplay -defeated
        Write-Host "You have been "
        Write-Host -ForegroundColor Red "DEFEATED!!!"
        Write-Host "GAME OVER" -ForegroundColor Yellow
        $player = New-Object -TypeName System.Media.SoundPlayer
        $player.SoundLocation = $global:Defeat
        $player.Load()
        $player.Play()
        $PlayerShips
        pause
        $inprogress = $false
    }
    else{
        wait-myturn
        $turn++
        Get-BoardDisplay
        $PlayerShipsLeft = $PlayerShips | Where {$_.sunk -eq $false}

        Write-Host $AttackResult
        # This Player Attacks
        if($AttackResult -like "You Sunk*"){
            $DestroyedShips ++
        }
        if($DestroyedShips -ge 5){
            write-Host -ForegroundColor Green "----- YOU WON!!!-----"
            $player = New-Object -TypeName System.Media.SoundPlayer
            $player.SoundLocation = $global:Victory
            $player.Load()
            $player.PlayLooping()
            Pause
            $inprogress = $false
        }else{
           
            do{
                $attack = (Read-Host "`nWhere do you want to attack? (ex: a2)").Trim()
                $AttackResult = Check-Attack $attack 
                if(($AttackResult -notlike "Already*") -and ($AttackResult -notlike "Invalid*")){
                    Get-BoardDisplay
                }
                Write-Host $AttackResult

            }until((!$AttackResult) -or (($AttackResult -notlike "Already*") -and ($AttackResult -notlike "Invalid*")))
            $turn++
            Get-BoardDisplay       
        }
        
    }
}
