#Hello! This is Telegram Command Bot v1.00

param( 	
	[Parameter(Mandatory=$True)]
	[string]$name, 
	
	[Parameter(Mandatory=$False)]
	[string]$short_name, 
	
	[Parameter(Mandatory=$True)]
	[Int]$number, 
	
	[Parameter(Mandatory=$True)]
	[string]$token )

#start parameters
$my_handler_id = $name
$my_handler_id_short = $short_name
$handler_number = $number
$bot_token = $token

#constant with bot tokens and administrator`s chat_id
$glfm_chat_id = "237604323"

$tasks_hash = @{Процессы=1; Службы=2; Пользователи=3}
$group_tasks_hash = @{sync=1; Синхронизация=1}
$tasks_hash_process = @{память=1; завершить=2; все=3}
$tasks_hash_services = @{отключить=1; включить=2}
$tasks_hash_users = @{список=1; заблокировать=2}

#example URL`s for use
#$URL_check = "https://api.telegram.org/bot$bot_token/getUpdates?&timeout=$ChatTimeout&limit=1"
#$URL_clear = "https://api.telegram.org/bot$bot_token/getUpdates?offset=$UpdateId"
#$URL_send_text = "https://api.telegram.org/bot$bot_token/sendMessage"
#$URL_send_sticker = "https://api.telegram.org/bot$bot_token/sendSticker"


#timeouts
$script:ChatTimeout = 10
$script:SleepTimeout = 10
$script:StartTimeout = ([DateTimeOffset](Get-Date)).ToUnixTimeSeconds()+10

#Flags
$script:AllFlag = $False

#update_id start from zero
$UpdateId = 0

#stickers file_id
$sticker_GTFO = "CAADBAAD9wADq2_uB9vyrtN1i-8QAg"

$counter_times = 0

#Function for check new message
function check {

$script:counter_times = ++$counter_times

$URL_check = "https://api.telegram.org/bot$bot_token/getUpdates?&timeout=$ChatTimeout&limit=1"
	
$Request = Invoke-WebRequest -Uri $URL_check -Method Get
$content = ConvertFrom-Json $Request

#errors info
$content.error_code
$content.description

#payload
$result = $content.result
$message = $result.message
$from = $message.from
$chat = $message.chat
$document = $message.document
$sticker = $message.sticker
$sticker_id = $sticker.file_id

$UpdateId = $result.update_id + 1

If ($content.ok -eq $True -and  $result.update_id -ne $null) {read} 
ElseIf ($content.ok -eq $False) {fix_error}

#ElseIf ($counter_times -eq 10000) {send_text -chat_id $glfm_chat_id -text "Мне никто не пишет((("}
#ElseIf ($counter_times -eq 20000) {send_text -chat_id $glfm_chat_id -text "Ты меня не любишь, не звони мне больше!"}

}

#Function for parse text message
function read {

$t = $message.text -split " "
$handler_name = $t[0]

#check handler_name		
If ($handler_name -eq $my_handler_id -or $handler_name -eq $my_handler_id_short) {

		$sw = $t[1]
		$sw = $tasks_hash.$sw
		
	switch ($sw) 
		{ 
        1 {process} 
        2 {services} 
        3 {users}
        default {send_text -chat_id $chat.id -text "Wrong command. Try again!"
		clear_message}
		}
		$script:counter_times = 0
}

#check group message
ElseIF ($handler_name -eq "All") {
		
	IF ($F -eq $False) {
		$script:F = $True
		
		$sw = $t[1]
		$sw = $group_tasks_hash.$sw
		
	switch ($sw) 
		{ 
        1 {sync_time}
        default {send_text -chat_id $chat.id -text "Wrong command. Try again!"
		clear_message}
		}
		
		$Unix_time = ([DateTimeOffset](Get-Date)).ToUnixTimeSeconds()
		$Dif = $unix_time - $message.date		
		If ($Dif -ge $SleepTimeout) {clear_message}
	
	$script:counter_times = 0
	}
	
	Else {return}
	
	}
		
Else {

		$Unix_time = ([DateTimeOffset](Get-Date)).ToUnixTimeSeconds()
		$Dif = $unix_time - $message.date

	$info = "Bot $t[0] not responding. Try again later."
	If ($Dif -ge $SleepTimeout) {send_text -chat_id $chat.id -text $info
	clear_message}

	}

}

function send_text {

param( [string]$chat_id, [string]$text )

$URL_send_text = "https://api.telegram.org/bot$bot_token/sendMessage"

$payload = @{
    "chat_id" = $chat_id;
    "text" = $text;
#    "parse_mode" = $markdown_mode;
#    "disable_web_page_preview" = $preview_mode;
}

Invoke-WebRequest `
	-Method Post `
	-Uri $URL_send_text `
	-ContentType "application/json;charset=utf-8" `
	-Body (ConvertTo-Json -Compress -InputObject $payload)
}

function send_sticker {

param( [string]$chat_id, [string]$sticker_id )

$URL_send_sticker = "https://api.telegram.org/bot$bot_token/sendSticker"

$payload = @{
    "chat_id" = $chat_id;
    "sticker" = $sticker_id;
}

Invoke-WebRequest `
	-Method Post `
	-Uri $URL_send_sticker `
	-ContentType "application/json;charset=utf-8" `
	-Body (ConvertTo-Json -Compress -InputObject $payload)
}

function fix_error {
		
		$info = "$my_handler_id"+"$content.error_code"+"$content.description"
		send_text -chat_id $glfm_chat_id -text $info
		
} 

function wait {

param( $next_start )

$Unix_time = ([DateTimeOffset](Get-Date)).ToUnixTimeSeconds()
$Dif = $next_start - $unix_time

sleep $Dif

return
} 

function clear_message {

$URL_clear = "https://api.telegram.org/bot$bot_token/getUpdates?offset=$UpdateId"
$Request = Invoke-WebRequest -Uri $URL_clear -Method Get
$UpdateId = 0

}

<#function download_file {

} 
#>

<#function upload_file {


}
#>

function sync_time {

$N = [int]::Parse($t[2])
If ($t[3] -ne $null){$script:ChatTimeout = [int]::Parse($t[3])}
$date_sync = $message.date + 10
$script:StartTimeout = $handler_number*($ChatTimeout+2)+$date_sync
$script:SleepTimeout = $N*($ChatTimeout+2)

} 

function process {
If ($t[2] -ne $null) {
		$sw = $t[2]
		$sw = $tasks_hash_process.$sw
	switch ($sw) 
		{ 
        1 {$info = (Get-Process | Sort-Object WS -Descending | Select-Object -First 10 | fl Name, Id, CPU, WS | Out-String)
			send_text -chat_id $chat.id -text $info} 
        2 { if ($t[3] -ne $null) { $info = (Stop-Process -id $t[3] -force)
			send_text -chat_id $chat.id -text $info}
			Else {send_text -chat_id $chat.id -text "Wrong command. Need process ID!"}}			
        3 { Get-Process | Sort-Object Name | ft ID, Name, WS, PM | Out-File C:\All_Process.txt
			send_file -chat_id $chat.id -file $info
			Remove-Item -Path C:\All_Process.txt -Force } 
        default {send_text -chat_id $chat.id -text "Wrong command. Try again!"}
		}
		}
Else {$info = (Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | fl Name, Id, CPU, WS | Out-String)
send_text -chat_id $chat.id -text $info}

clear_message
}

function services {

If ($t[2] -ne $null -and $t[3] -ne $null) {
		$sw = $t[2]
		$sw = $tasks_hash_services.$sw
	switch ($sw) 
		{ 
        1 {$info = (Set-Service $t[3] -StartupType Disabled -PassThru | Stop-Service -PassThru)
			send_text -chat_id $chat.id -text $info} 
        2 {$info = (Set-Service $t[3] -StartupType Disabled -PassThru | Stop-Service -PassThru)
			send_text -chat_id $chat.id -text $info} 
		default {send_text -chat_id $chat.id -text "Wrong command. Try again!"}
		}
		}
Else {
	Get-Service | Sort-Object Name | ft Name,DisplayName,Status | Out-File C:\All_Services.txt
	send_file -chat_id $chat.id -file $info
	Remove-Item -Path C:\All_Services.txt -Force
}
		
clear_message
}

function users {

If ($t[2] -ne $null) {
		$sw = $t[2]
		$sw = $tasks_hash_users.$sw
	switch ($sw) 
		{ 
        1 {$info = (Get-WmiObject Win32_UserAccount | fl Name, FullName, Caption, AccountType | Out-String -Width 48)
			send_text -chat_id $chat.id -text $info} 
#       2 {block_user}  
        default {send_text -chat_id $chat.id -text "Wrong command. Try again!"}
		}
		}

clear_message
}

do
{
If ($counter_times -ge 2) {$script:F = $False}
wait -next_start $StartTimeout
check
$script:StartTimeout = $SleepTimeout+$StartTimeout
}
while ( 1 -eq 1 )
