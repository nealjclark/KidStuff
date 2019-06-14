 

for($i=0;$i-lt10;$i++){
    $Number.$i
}

function Get-MathQuestion {
    param (
        [string]$Equation,
        [int]$color = 11,
        [switch]$AdditionOnly,
        [Switch]$SubtractionOnly,
        [switch]$DiceMode
    )
    [int]$correct = 0
    $DisplayNumbers = @{
        0 = "  ___   ", " / _ \  ", "| | | | ","| | | | ","| |_| | "," \___/  "
        1 = " __  ","/_ | "," | | "," | | "," | | "," |_| "
        2 = " ___   ","|__ \  ","   ) | ","  / /  "," / /_  ","|____| "
        3 = " ____   ","|___ \  ","  __) | "," |__ <  "," ___) | ","|____/  "
        4 = " _  _    ","| || |   ","| || |_  ","|__   _| ","   | |   ","   |_|   "
        5 = " _____  ","| ____| ","| |__   ","|___ \  "," ___) | ","|____/  "
        6 = "   __   ","  / /   "," / /_   ","| '_ \  ","| (_) | "," \___/  "
        7 = " ______  ","|____  | ","    / /  ","   / /   ","  / /    "," /_/     "
        8 = "  ___   "," / _ \  ","| (_) | "," > _ <  ","| (_) | "," \___/  "
        9 = "  ___   "," / _ \  ","| (_) | "," \__, | ","   / /  ","  /_/   "
        e = "          ","  ______  "," |______| ","  ______  "," |______| ","          "
        p = "        ","   _    "," _| |_  ","|_   _| ","  |_|   ","        "
        n = "           ","           ","   ______  ","  |______| ","           ","           "
    }
   
    $dice = @{
        0 = "  ___   ", " / _ \  ", "| | | | ","| | | | ","| |_| | "," \___/  "
        1 = "         "," ------- ", "|       |", "|   O   |", "|       |", " ------- "
        2 = "         "," ------- ", "| O     |", "|       |", "|     O |", " ------- "
        3 = "         "," ------- ", "| O     |", "|   O   |", "|     O |", " ------- "
        4 = "         "," ------- ", "| O   O |", "|       |", "| O   O |", " ------- "
        5 = "         "," ------- ", "| O   O |", "|   O   |", "| O   O |", " ------- "
        6 = "         "," ------- ", "| O   O |", "| O   O |", "| O   O |", " ------- "
        7 = " ______  ","|____  | ","    / /  ","   / /   ","  / /    "," /_/     "
        8 = "  ___   "," / _ \  ","| (_) | "," > _ <  ","| (_) | "," \___/  "
        9 = "  ___   "," / _ \  ","| (_) | "," \__, | ","   / /  ","  /_/   "
        e = "          ","  ______  "," |______| ","  ______  "," |______| ","          "
        p = "         ","    _    ","  _| |_  "," |_   _| ","   |_|   ","         "
        n = "          ","            ","   ______  ","  |______| ","           ","           "
    }   
    if(!$Equation){
        if($DiceMode){
            $number1 = Get-Random -Minimum 1 -Maximum 7
            $number2 = Get-Random -Minimum 1 -Maximum 7
        }
        Else{
            $number1 = Get-Random -Maximum 10
            $number2 = Get-Random -Maximum 10
        }

        # Assign operator
        if($AdditionOnly){
            $operator = 0
        }
        elseif($SubtractionOnly){
            $operator = 1
        }
        Else{
            $operator = Get-Random -Maximum 2            
        }

        #Create string of problem.
        if($operator -eq 0){
            # 0 = Addition +
            $Equation = ""+$number1+ "+" + $number2 + "=" + ($number1+$number2)
        }
        elseif($operator -eq 1){
            # 1 = Addition -
            if($number1 -ge $number2){
                $Equation = ""+$number1+ "-" + $number2 + "=" + ($number1-$number2)
            }
            elseif($number1 -lt $number2){
                $Equation = ""+$number2+ "-" + $number1 + "=" + ($number2-$number1)
            }
        }
    }#Close Equasion Builder

    $buildline = ""
    $Problem, $Solution = $Equation.split("=")
    $DisplayProblem = [char[]]($Problem.Replace("+","p").Replace("-","n"))
    $AnswerDisplay  = [char[]]($Equation.Replace("+","p").Replace("-","n").Replace("=","e"))

    if($DiceMode){
        for($i=0;$i-lt6;$i++){
            foreach($char in $DisplayProblem){
                $parse = ""
                $parse += $char
                $buildline += ($dice.($dice.keys | Where-Object {$_ -eq $parse}))[$i]
            }
            write-host -ForegroundColor $color "$buildline"
            $buildline = ""
        }
    
        $Guess = Read-Host "What is the Answer?"
        if($Guess -like $Solution){
            $color = 10
            Write-Host -ForegroundColor $color "YOU ARE CORRECT!!"
            $correct = 1
        }
        else{
            $color = 12
            Write-Host -ForegroundColor $color "The correct answer is: $Solution"
        }
        
        for($i=0;$i-lt6;$i++){
            foreach($char in $AnswerDisplay){
                $parse = ""
                $parse += $char
                if([int]$solution -lt 10){
                    $buildline += ($dice.($dice.keys | Where-Object {$_ -eq $parse}))[$i]
                }
                else{
                    $buildline += ($DisplayNumbers.($DisplayNumbers.keys | Where-Object {$_ -eq $parse}))[$i]

                }
            }
            write-host -ForegroundColor $color "$buildline"
            $buildline = ""
        }
        write-host "..."
        Start-Sleep -s 2

    }
    else{
        for($i=0;$i-lt6;$i++){
            foreach($char in $DisplayProblem){
                $parse = ""
                $parse += $char
                $buildline += ($DisplayNumbers.($DisplayNumbers.keys | Where-Object {$_ -eq $parse}))[$i]
            }
            write-host -ForegroundColor $color "$buildline"
            $buildline = ""
        }
    
        $Guess = Read-Host "What is the Answer?"
        if($Guess -like $Solution){
            $color = 10
            Write-Host -ForegroundColor $color "YOU ARE CORRECT!!"
            $correct = 1
        }
        else{
            $color = 12
            Write-Host -ForegroundColor $color "The correct answer is: $Solution"
        }
        
        for($i=0;$i-lt6;$i++){
            foreach($char in $AnswerDisplay){
                $parse = ""
                $parse += $char
                $buildline += ($DisplayNumbers.($DisplayNumbers.keys | Where-Object {$_ -eq $parse}))[$i]
            }
            write-host -ForegroundColor $color "$buildline"
            $buildline = ""
        }
        write-host "..."
        Start-Sleep -s 2
    }
    return $correct
}
$TotalScore = 0
$Questions = 1
do {
    $mode = Get-Random -Maximum 2
    if($mode -eq 0){
        $Grade = Get-MathQuestion -AdditionOnly
    }
    else{
        $Grade = Get-MathQuestion -AdditionOnly -DiceMode
    }
    $TotalScore += $Grade
    $Questions++
} until ($Questions -gt 10)

Write-Host -ForegroundColor Magenta "-----------!!!!!GREAT JOB!!!!-----------"
Write-Host                        "`n           You Got " -NoNewline
Write-Host -ForegroundColor Green "$TotalScore" -NoNewline
Write-Host " Correct!`n`n`n"
Pause
