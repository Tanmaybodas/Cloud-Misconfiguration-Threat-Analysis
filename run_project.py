#!/usr/bin/env python3
"""
Cloud Misconfiguration PBL - Project Runner
============================================
Double-click this file or run: python run_project.py
"""

import subprocess
import sys
import os
import time
from pathlib import Path

# Colors for terminal output
class Colors:
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header():
    print(f"\n{Colors.CYAN}{Colors.BOLD}")
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║  Cloud Misconfiguration PBL - Project Runner                   ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print(f"{Colors.END}\n")

def print_error(message):
    print(f"{Colors.RED}✗ ERROR: {message}{Colors.END}\n")

def print_success(message):
    print(f"{Colors.GREEN}✓ {message}{Colors.END}\n")

def print_step(step_num, description):
    print(f"{Colors.YELLOW}{'━' * 64}{Colors.END}")
    print(f"{Colors.YELLOW}  STEP {step_num} - {description}{Colors.END}")
    print(f"{Colors.YELLOW}{'━' * 64}{Colors.END}\n")

def check_docker():
    """Check if Docker is running"""
    try:
        result = subprocess.run(
            ["docker", "ps"],
            capture_output=True,
            timeout=5
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False

def get_venv_python():
    """Get the path to the Python executable in the venv"""
    venv_path = Path(__file__).parent / ".venv"
    if sys.platform == "win32":
        python_exe = venv_path / "Scripts" / "python.exe"
    else:
        python_exe = venv_path / "bin" / "python"
    
    if python_exe.exists():
        return str(python_exe)
    
    # Fallback to system python
    return sys.executable

def run_step(step_num, script_name, description, args=None):
    """Run a single project step"""
    print_step(step_num, description)
    
    script_path = Path(__file__).parent / "scripts" / script_name
    if not script_path.exists():
        print_error(f"Script not found: {script_path}")
        return False
    
    try:
        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(script_path)]
        if args:
            cmd.extend(args)
        
        result = subprocess.run(cmd, cwd=Path(__file__).parent)
        
        if result.returncode == 0:
            print_success(f"Step {step_num} completed successfully!")
            return True
        else:
            print_error(f"Step {step_num} failed with exit code {result.returncode}")
            return False
    except Exception as e:
        print_error(f"Failed to run step {step_num}: {str(e)}")
        return False

def main():
    print_header()
    
    # Check Docker
    print(f"{Colors.YELLOW}Checking Docker...{Colors.END}")
    if not check_docker():
        print_error("Docker is NOT running!")
        print(f"{Colors.YELLOW}To start Docker Desktop:{Colors.END}")
        print("  1. Click the Start Menu (Windows key)")
        print("  2. Type: Docker Desktop")
        print("  3. Press Enter")
        print("  4. Wait 30-60 seconds for it to fully load")
        print("  5. Look for Docker icon in your system tray (bottom right)")
        print("  6. Then run this script again\n")
        input(f"{Colors.YELLOW}Press Enter to exit...{Colors.END}")
        return False
    
    print_success("Docker is running!")
    time.sleep(1)
    
    # Run all steps
    steps = [
        (0, "00_check_prereqs.ps1", "Check Prerequisites"),
        (1, "01_start_localstack.ps1", "Start LocalStack", ["-Detached"]),
        (2, "02_create_before_state.ps1", "Create Secure Baseline"),
        (3, "03_introduce_misconfigs.ps1", "Introduce Misconfigurations"),
        (4, "04_run_scanners.ps1", "Run Security Scanners"),
        (5, "05_harden.ps1", "Apply Hardening Fixes"),
        (6, "06_export_diagram_assets.ps1", "Export Architecture Diagrams"),
    ]
    
    all_passed = True
    
    for step in steps:
        step_num = step[0]
        script_name = step[1]
        description = step[2]
        args = step[3] if len(step) > 3 else None
        
        # Wait before step 2 for LocalStack to be ready
        if step_num == 2:
            print(f"{Colors.YELLOW}Waiting 5 seconds for LocalStack to be ready...{Colors.END}\n")
            time.sleep(5)
        
        if not run_step(step_num, script_name, description, args):
            all_passed = False
            break
    
    # Final message
    print("\n")
    if all_passed:
        print(f"{Colors.GREEN}{Colors.BOLD}")
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║  ✓ Project execution complete!                                 ║")
        print("║  Check evidence/ and docs/ folders for results                 ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print(f"{Colors.END}\n")
    else:
        print(f"{Colors.RED}{Colors.BOLD}")
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║  ✗ Project execution stopped due to errors                     ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print(f"{Colors.END}\n")
    
    input(f"{Colors.YELLOW}Press Enter to exit...{Colors.END}")
    return all_passed

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Execution cancelled by user{Colors.END}\n")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        input(f"{Colors.YELLOW}Press Enter to exit...{Colors.END}")
        sys.exit(1)
