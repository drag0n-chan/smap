#!/bin/bash

SCRIPTPATH="/usr/share/nmap/scripts"

# --help support
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: $0 <target-ip OR file>"
  echo "Run interactive Nmap toolkit. Must be run as root (sudo)."
  echo "Saves scan results in ./scans/ folder with multi-format output."
  echo "Features:"
  echo " - Multiple scan types (SYN, UDP, Xmas, Null, FIN, ACK, Vulnerability, Aggressive, etc.)"
  echo " - NSE scripts manual and category selection"
  echo " - Custom port flags"
  echo " - Batch mode for multiple targets"
  echo " - Live output with tee saving"
  echo " - Colorized viewing of past scans (requires ccze)"
  echo " - Interactive browsing of past scans (requires fzf)"
  echo " - Ctrl+C trap for clean exit"
  echo " - Optional zip of scan results"
  echo " - Dependency checks for required tools"
  echo ""
  exit 0
fi

# Trap Ctrl+C for cleanup
trap 'echo -e "\n🛑 Interrupted by user. Exiting cleanly."; exit 1' INT

# Dependency check function
check_dep() {
  if command -v "$1" &>/dev/null; then
    echo "✅ $1: Installed"
  else
    echo "❌ $1: Missing"
  fi
}

# Dependency summary
echo "🔍 Checking tool dependencies..."
check_dep nmap
check_dep fzf
check_dep ccze
check_dep zip
echo ""

# Check root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run as root or with sudo."
  exit 1
fi

# Usage check
if [[ -z "$1" ]]; then
  echo "Usage: $0 <target-ip OR file-with-targets>"
  echo "Try '$0 --help' for more info."
  exit 1
fi

colorize() {
  if command -v ccze &>/dev/null; then
    ccze -A
  else
    cat
  fi
}

run_scan() {
  local desc="$1"
  local cmd="$2"
  local baseoutfile="$3"

  echo -e "\n🚀 Running: $desc"
  echo "Output folder: $EXPORT_DIR"
  echo "Command: $cmd $PORTFLAG $TARGET -oN $EXPORT_DIR/${baseoutfile}.txt -oX $EXPORT_DIR/${baseoutfile}.xml -oG $EXPORT_DIR/${baseoutfile}.gnmap"

  # Run nmap, save 3 formats, tee output for live display + saving raw text log
  eval "$cmd $PORTFLAG $TARGET -oN $EXPORT_DIR/${baseoutfile}.txt -oX $EXPORT_DIR/${baseoutfile}.xml -oG $EXPORT_DIR/${baseoutfile}.gnmap | tee $EXPORT_DIR/${baseoutfile}_live.log"

  echo "✅ Done: ${baseoutfile}.txt (and .xml, .gnmap, live.log)"
}

scan_target() {
  TARGET=$1
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  EXPORT_DIR="scans/${TARGET}_${TIMESTAMP}"
  mkdir -p "$EXPORT_DIR"
  echo "📁 Results folder: $EXPORT_DIR"

  # Ask for port flag
  read -p "🛠️ Do you want a custom port flag (e.g., -p 22,80 or --top-ports 100)? (y/n): " use_ports
  if [[ "$use_ports" == "y" || "$use_ports" == "Y" ]]; then
    read -p "🎯 Enter full port flag: " PORTFLAG
  else
    PORTFLAG=""
  fi

  echo -e "\n--- Choose your scan ---"
  echo " 1. SYN Scan (-sS -sV -v --reason --open -T4)"
  echo " 2. UDP Scan (-sU -sV -v --reason --open -T4)"
  echo " 3. Xmas Scan (-sX -v --reason --open -T4)"
  echo " 4. Null Scan (-sN -v --reason --open -T4)"
  echo " 5. FIN Scan (-sF -v --reason --open -T4)"
  echo " 6. ACK Scan (-sA -v --reason --open -T4)"
  echo " 7. Full Recon (-A -v --reason --open -T4)"
  echo " 8. Stealth + Decoy + MAC Spoof (-sX -D 192.168.1.100,192.168.1.101,ME --spoof-mac Apple -v --reason --open -T2)"
  echo " 9. Vulnerability Scan (--script vuln -sV -v --reason --open -T4)"
  echo "10. Full TCP Port Scan (-sS -sV -O -p- -v --reason --open -T4)"
  echo "11. OS & Service Detection (-O -sV -v --reason --open -T4)"
  echo "12. NSE Script Scan (manual)"
  echo "13. NSE Script Scan (by category)"
  echo "14. Auto HTTP Recon (http-* scripts on common ports)"
  echo "15. Default NSE + Version + Verbose (-sC -sV -v -T4)"
  echo "16. Ping scan only (-sn -v --reason)"
  echo "17. Quick scan (-T4 -F -v --reason --open)"
  echo "18. Comprehensive Full Scan (TCP+UDP+Scripts+OS+Version)"
  echo "19. Aggressive Scan (-A -T4 -v --reason)"
  echo "20. Scan All TCP Ports (-p- -v --reason -T4)"
  echo "21. Scan All UDP Ports (-sU -p- -v --reason -T4)"
  echo "22. Browse past scans (interactive)"
  echo "23. Exit"
  read -p "Enter choice (1-23): " choice

  case $choice in
    1) run_scan "SYN Scan" "nmap -sS -sV -v --reason --open -T4 -Pn" "syn_scan" ;;
    2) run_scan "UDP Scan" "nmap -sU -sV -v --reason --open -T4 -Pn" "udp_scan" ;;
    3) run_scan "Xmas Scan" "nmap -sX -v --reason --open -T4 -Pn" "xmas_scan" ;;
    4) run_scan "Null Scan" "nmap -sN -v --reason --open -T4 -Pn" "null_scan" ;;
    5) run_scan "FIN Scan" "nmap -sF -v --reason --open -T4 -Pn" "fin_scan" ;;
    6) run_scan "ACK Scan" "nmap -sA -v --reason --open -T4 -Pn" "ack_scan" ;;
    7) run_scan "Full Recon" "nmap -A -v --reason --open -T4 -Pn" "full_recon" ;;
    8) run_scan "Stealth + Decoy + MAC Spoof" "nmap -sX -D 192.168.1.100,192.168.1.101,ME --spoof-mac Apple -v --reason --open -T2 -Pn" "stealth_bypass" ;;
    9) run_scan "Vuln Scan" "nmap -sV --script vuln -v --reason --open -T4 -Pn" "vuln_scan" ;;
    10) run_scan "Full TCP Port Scan" "nmap -sS -sV -O -p- -v --reason --open -T4 -Pn" "full_tcp_scan" ;;
    11) run_scan "OS & Service Detection" "nmap -O -sV -v --reason --open -T4 -Pn" "os_service" ;;
    12)
      ls $SCRIPTPATH | less
      read -p "Enter comma-separated script names: " scriptnames
      [[ -z "$scriptnames" ]] && echo "No script selected." && exit 1
      SAFE_NAME=$(echo "$scriptnames" | sed 's/[^a-zA-Z0-9]/_/g')
      run_scan "NSE Manual: $scriptnames" "nmap --script=$scriptnames -v --reason --open -T4 -Pn" "nse_${SAFE_NAME}"
      ;;
    13)
      echo "Categories: auth, brute, default, discovery, dos, exploit, external, fuzzer, http, intrusive, malware, safe, version, vuln"
      read -p "Enter category: " category
      grep -l "categories.*$category" $SCRIPTPATH/*.nse | xargs -n1 basename | sort | less
      read -p "Enter scripts from this category: " cat_scripts
      [[ -z "$cat_scripts" ]] && echo "No script selected." && exit 1
      SAFE_NAME=$(echo "$cat_scripts" | sed 's/[^a-zA-Z0-9]/_/g')
      run_scan "Category scripts: $cat_scripts" "nmap --script=$cat_scripts -v --reason --open -T4 -Pn" "cat_${SAFE_NAME}"
      ;;
    14)
      run_scan "Auto HTTP Recon" "nmap -sV -Pn -p 80,443,8080,8000,8443 --script 'http-*' -v --reason --open -T4" "http_recon"
      ;;
    15)
      run_scan "Default NSE + Version + Verbose" "nmap -sC -sV -v --reason --open -T4 -Pn" "default_nse_verbose"
      ;;
    16)
      run_scan "Ping Scan Only" "nmap -sn -v --reason -Pn" "ping_scan"
      ;;
    17)
      run_scan "Quick Scan" "nmap -T4 -F -v --reason --open -Pn" "quick_scan"
      ;;
    18)
      run_scan "Comprehensive Full Scan" "nmap -sS -sU -sV -O --script=default,vuln -p- -v --reason --open -T4 -Pn" "comprehensive_full"
      ;;
    19)
      run_scan "Aggressive Scan" "nmap -A -T4 -v --reason -Pn" "aggressive_scan"
      ;;
    20)
      run_scan "Scan All TCP Ports" "nmap -p- -v --reason -T4 -Pn" "all_tcp_ports"
      ;;
    21)
      run_scan "Scan All UDP Ports" "nmap -sU -p- -v --reason -T4 -Pn" "all_udp_ports"
      ;;
    22)
      if ! command -v fzf &>/dev/null; then
        echo "fzf not found! Please install fzf for interactive browsing."
        return
      fi
      echo "📂 Browsing scans directory..."
      FILE=$(find scans/ -type f -name "*.txt" | fzf --preview 'head -40 {}' --preview-window=down:10)
      if [[ -n "$FILE" ]]; then
        echo "Opening $FILE with less (colorized if available)..."
        cat "$FILE" | colorize | less -R
      else
        echo "No file selected."
      fi
      ;;
    23)
      echo "👋 Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice."
      ;;
  esac

  # Summary after scan
  echo -e "\n📄 Summary for target $TARGET:"
  echo "Target: $TARGET"
  echo "Scan Time: $TIMESTAMP"
  echo "Files:"
  ls "$EXPORT_DIR" | grep -v "_live.log" | grep -v summary.txt
  echo ""

  # Save summary file
  echo -e "Target: $TARGET\nScan Time: $TIMESTAMP\nFiles:" > "$EXPORT_DIR/summary.txt"
  ls "$EXPORT_DIR" | grep -v summary.txt >> "$EXPORT_DIR/summary.txt"

  # Optional zip archive prompt
  read -p "📦 Zip results folder? (y/n): " zipit
  if [[ "$zipit" =~ ^[Yy]$ ]]; then
    if command -v zip &>/dev/null; then
      zip -r "${EXPORT_DIR}.zip" "$EXPORT_DIR"
      echo "✅ Results zipped as ${EXPORT_DIR}.zip"
    else
      echo "❌ zip command not found, cannot create archive."
    fi
  fi

  echo "✅ Scan completed. Summary saved at $EXPORT_DIR/summary.txt"
}

# Main execution logic
if [[ -f "$1"  ]]; then
  echo "📂 Batch mode: Scanning targets from file $1"
  while read -r target; do
    [[ -z "$target" ]] && continue
    scan_target "$target"
  done < "$1"
else
  scan_target "$1"
fi

