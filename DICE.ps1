function Display-Roll{
<#
    .DESCRIPTION 
        Function to Display ASCII dice. accepts an array or a single number 

    .PARAMETERS
        $DiceRoll
            This in the array of numbers 1 - 6 that will displayed on the Dice.
        $Color
            This is the color of the dice to be displayed. write-host Forground colors text or 0-15.
            Default is White.

    .EXAMPLE
        Display-Roll 4, 5 Green
        Display-Roll 4, 5 1
       output:
         -------    -------   
        | 0   0 |  | 0   0 |  
        |       |  |   0   |  
        | 0   0 |  | 0   0 |  
         -------    -------   

#>
    param(
        [array]$DiceRoll, 
        $color = "White"
    )
    $dice = @{
        1 = " ------- ", "|       |", "|   O   |", "|       |", " ------- "
        2 = " ------- ", "| O     |", "|       |", "|     O |", " ------- "
        3 = " ------- ", "| O     |", "|   O   |", "|     O |", " ------- "
        4 = " ------- ", "| O   O |", "|       |", "| O   O |", " ------- "
        5 = " ------- ", "| O   O |", "|   O   |", "| O   O |", " ------- "
        6 = " ------- ", "| O   O |", "| O   O |", "| O   O |", " ------- "
    }    

    $linearray = @()
    $buildline = ""

    #Displays all dice in a single row. 
    for($i=0;$i -lt 5;$i++){
        foreach($number in $DiceRoll){
            $buildline += $dice.$number[$i] + "  "
        }
        write-host -ForegroundColor $color "$buildline"
        $buildline = ""
    }
}

function Get-DiceRoll{
<#
    .DESCRIPTION
        Rolls a dice to specification and returns results in an array

    .PARAMETERS
        Quantity    : The number of Die to roll default 1
        Sides       : The number of sides on the die. Default 6
        Custom   : Array of Custom Values for each side of the die. CustomMap[0] would go on 1
        Minimum  : Sets the minumvalue of a side. for dice that start at different values. 

    .EXAMPLES
        Get-DiceRoll > 3
        get-DiceRoll -quantity 3 -custom "L","O","R","O","C","O"    This would be a Left right center game roll
        get-DiceRoll -Quantity 3    #This is a Cee-Lo roll.
#>
    Param(
        $Quantity    = 1,
        $sides       = 6,
        $Minimum     = 1,
        $Custom   = $null
    )
    $result = @()
    
    if($CustomMap -eq $null){
        For ($i=1; $i -le $Quantity; $i++) {
            $result += Get-Random -Minimum $Minimum -Maximum ($sides+$Minimum)
        }
    }
    Else{
        For ($i=1; $i -le $Quantity; $i++) {
            $result += Get-Random -InputObject $Custom
        }
    }

    return $result
}

function play{
clear
"KID"
display-roll (Get-DiceRoll 3) magenta

"DAD"
display-roll (Get-DiceRoll 3) cyan

#"ANDREW"
#display-roll (Get-DiceRoll 3) RED
}


while ($true){
play
pause
}
