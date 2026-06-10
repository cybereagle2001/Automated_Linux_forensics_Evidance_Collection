# Linux Live Response Triage Collection Script

**Author:** cybereagle2001  
**Version:** 1.0.0  
**Last Updated:** 2026  
**License:** Proprietary / All Rights Reserved (See Copyright Notice)

---

## ⚖️ Copyright Notice
```text
Copyright (c) 2026 cybereagle2001. All Rights Reserved.

This script and its accompanying documentation are the intellectual property of cybereagle2001. 
Unauthorized copying, modification, distribution, or commercial use of this software, in whole 
or in part, without explicit written permission from the author is strictly prohibited.

This tool is provided "as is" for authorized digital forensics and incident response (DFIR) 
purposes only. The author assumes no liability for misuse, data loss, or system instability 
resulting from the use of this script.
```

---

## 📖 Overview
The **Linux Live Response Triage Collection Script** is a Bash-based forensic utility designed to rapidly collect volatile data, system state information, user activity artifacts, and key application logs from a live Linux environment. 

It is built in accordance with the **Order of Volatility (RFC 3227)**, prioritizing the most ephemeral data (e.g., running processes, network connections) before capturing less volatile data (e.g., disk-based logs). The script automatically packages the collected evidence into a compressed archive and generates a SHA-256 hash to establish a baseline for the chain of custody.

---

## 🛡️ Forensic Disclaimer & Warnings
> **⚠️ READ BEFORE USE:**  
> 1. **System Alteration:** Running *any* live response script inherently alters the system state (e.g., creating new processes, updating file access timestamps). This script is intended for **triage and anomaly detection**, not as a substitute for formal, court-admissible forensic memory/disk imaging.
> 2. **Compromised Hosts:** If you suspect the system is actively compromised with a rootkit, standard binaries (like `ps`, `netstat`, or `ls`) may be hooked or replaced. In such scenarios, execute statically compiled, trusted binaries from a read-only external medium, or use enterprise DFIR agents (e.g., Velociraptor).
> 3. **Authorization:** Only execute this script on systems where you have explicit, documented legal authority to perform forensic data collection.

---

## 📋 Prerequisites
- **Operating System:** Linux (Tested on Debian/Ubuntu and RHEL/CentOS derivatives).
- **Privileges:** `root` or `sudo` access is **mandatory** to read shadow files, all user histories, and system logs.
- **Disk Space:** Ensure the `/tmp` directory (or your modified target directory) has sufficient free space to hold the collected logs and the final `.tar.gz` archive.

---

## 🚀 Usage Instructions

1. **Download or Create the Script:**  
   Save the script to your target machine as `triage_collect.sh`.

2. **Set Executable Permissions:**  
   ```bash
   chmod +x triage_collect.sh
   ```

3. **Execute with Root Privileges:**  
   ```bash
   sudo ./triage_collect.sh
   ```

4. **Monitor Output:**  
   The script will print real-time status updates as it progresses through the 5 collection phases.

---

## 📂 Output Structure
Upon successful execution, the script generates a compressed archive and a hash file in `/tmp/`. 

**Generated Files:**
- `forensic_triage_<HOSTNAME>_<TIMESTAMP>.tar.gz` (The evidence archive)
- `forensic_triage_<HOSTNAME>_<TIMESTAMP>.tar.gz.sha256` (Integrity hash)

**Internal Archive Structure:**
```text
forensic_triage_<HOSTNAME>_<TIMESTAMP>/
├── volatile/           # RFC 3227 high-priority data (ps, ss, lsof, dmesg, w, who)
├── system_info/        # OS details, mount points, users, groups, SUID/SGID binaries, crontabs
├── user_activity/      # .bash_history, SSH authorized_keys/known_hosts, last/lastb logins
└── logs/               # auth.log, secure, syslog, messages, vsftpd, apache2, nginx, sudo logs
```

---

## 🔐 Post-Collection & Chain of Custody

To maintain the integrity of the collected evidence, follow these steps immediately after collection:

1. **Secure Transfer:**  
   Use a secure, encrypted channel (e.g., `scp`, `sftp`, or an encrypted USB drive) to transfer the `.tar.gz` and `.sha256` files to a dedicated, isolated forensic workstation.
   ```bash
   scp /tmp/forensic_triage_*.tar.gz* user@forensic-workstation:/path/to/evidence/
   ```

2. **Verify Integrity:**  
   Upon receipt, immediately verify that the file has not been altered during transit by checking the SHA-256 hash:
   ```bash
   sha256sum -c forensic_triage_<HOSTNAME>_<TIMESTAMP>.tar.gz.sha256
   ```
   *Expected Output:* `forensic_triage_<HOSTNAME>_<TIMESTAMP>.tar.gz: OK`

3. **Secure Erasure (Optional but Recommended):**  
   Once the archive is safely secured and verified on the forensic workstation, securely wipe the temporary files from the target host to prevent leaving forensic artifacts behind:
   ```bash
   shred -u /tmp/forensic_triage_*.tar.gz*
   ```
## 📬 Contact & Support
For inquiries, authorized feature requests, or professional DFIR consulting, please contact:  
**cybereagle2001**  
*linkeidn : * https://www.linkedin.com/in/oussama-ben-hadj-dahman-0547a61b3/
