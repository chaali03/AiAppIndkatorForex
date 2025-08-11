#!/usr/bin/env python3
"""
ADVANCED CRYPTO AI - AUTOMATIC PYTHON ENVIRONMENT SETUP
Automatically installs Python, pip, and all required dependencies for the AI system
Supports Windows, Linux, and macOS with intelligent detection and installation
"""

import os
import sys
import subprocess
import platform
import urllib.request
import tempfile
import shutil
import json
from pathlib import Path

class PythonEnvironmentSetup:
    def __init__(self):
        self.system = platform.system().lower()
        self.architecture = platform.machine().lower()
        self.python_version = "3.9.16"  # Stable version compatible with TensorFlow
        self.project_root = Path(__file__).parent.parent
        self.ai_root = Path(__file__).parent
        self.venv_path = self.ai_root / "venv"
        self.python_installer_url = self.get_python_installer_url()
        
    def get_python_installer_url(self):
        """Get appropriate Python installer URL based on system and architecture"""
        if self.system == "windows":
            if "64" in self.architecture or "amd64" in self.architecture:
                return f"https://www.python.org/ftp/python/{self.python_version}/python-{self.python_version}-amd64.exe"
            else:
                return f"https://www.python.org/ftp/python/{self.python_version}/python-{self.python_version}.exe"
        elif self.system == "darwin":  # macOS
            return f"https://www.python.org/ftp/python/{self.python_version}/python-{self.python_version}-macos11.pkg"
        else:  # Linux - will use package manager
            return None
    
    def log(self, message, level="INFO"):
        """Enhanced logging with timestamps and levels"""
        import datetime
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")
        
        # Also write to log file
        log_file = self.ai_root / "setup.log"
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] [{level}] {message}\n")
    
    def check_python_installed(self):
        """Check if Python is installed and get version"""
        try:
            result = subprocess.run([sys.executable, "--version"], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                version = result.stdout.strip()
                self.log(f"Python found: {version}")
                return True, version
        except FileNotFoundError:
            pass
        
        # Try alternative python commands
        for cmd in ["python3", "python", "py"]:
            try:
                result = subprocess.run([cmd, "--version"], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    version = result.stdout.strip()
                    self.log(f"Python found with '{cmd}': {version}")
                    return True, version
            except FileNotFoundError:
                continue
        
        return False, None
    
    def install_python_windows(self):
        """Install Python on Windows"""
        self.log("Installing Python on Windows...")
        
        temp_dir = tempfile.mkdtemp()
        installer_path = os.path.join(temp_dir, "python_installer.exe")
        
        try:
            self.log("Downloading Python installer...")
            urllib.request.urlretrieve(self.python_installer_url, installer_path)
            
            self.log("Running Python installer...")
            # Silent installation with all features
            cmd = [
                installer_path,
                "/quiet",
                "InstallAllUsers=1",
                "PrependPath=1",
                "Include_test=0",
                "Include_launcher=1",
                "Include_dev=1",
                "Include_debug=0",
                "Include_symbols=0"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                self.log("Python installed successfully!")
                return True
            else:
                self.log(f"Python installation failed: {result.stderr}", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"Error installing Python: {str(e)}", "ERROR")
            return False
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
    
    def install_python_linux(self):
        """Install Python on Linux using package manager"""
        self.log("Installing Python on Linux...")
        
        # Try different package managers
        package_managers = [
            (["apt-get", "update"], ["apt-get", "install", "-y", "python3", "python3-pip", "python3-venv"]),
            (["yum", "check-update"], ["yum", "install", "-y", "python3", "python3-pip"]),
            (["dnf", "check-update"], ["dnf", "install", "-y", "python3", "python3-pip"]),
            (["pacman", "-Sy"], ["pacman", "-S", "--noconfirm", "python", "python-pip"])
        ]
        
        for update_cmd, install_cmd in package_managers:
            try:
                # Try update first
                subprocess.run(update_cmd, capture_output=True, check=False)
                
                # Try installation
                result = subprocess.run(install_cmd, capture_output=True, text=True)
                if result.returncode == 0:
                    self.log("Python installed successfully!")
                    return True
            except FileNotFoundError:
                continue
        
        self.log("Could not install Python automatically. Please install manually.", "ERROR")
        return False
    
    def install_python_macos(self):
        """Install Python on macOS"""
        self.log("Installing Python on macOS...")
        
        # Try Homebrew first
        try:
            subprocess.run(["brew", "--version"], capture_output=True, check=True)
            result = subprocess.run(["brew", "install", "python@3.9"], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                self.log("Python installed successfully via Homebrew!")
                return True
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass
        
        # Fall back to official installer
        temp_dir = tempfile.mkdtemp()
        installer_path = os.path.join(temp_dir, "python_installer.pkg")
        
        try:
            self.log("Downloading Python installer...")
            urllib.request.urlretrieve(self.python_installer_url, installer_path)
            
            self.log("Running Python installer...")
            result = subprocess.run(["installer", "-pkg", installer_path, "-target", "/"], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                self.log("Python installed successfully!")
                return True
            else:
                self.log(f"Python installation failed: {result.stderr}", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"Error installing Python: {str(e)}", "ERROR")
            return False
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
    
    def create_virtual_environment(self):
        """Create virtual environment for the project"""
        self.log("Creating virtual environment...")
        
        try:
            # Remove existing venv if it exists
            if self.venv_path.exists():
                shutil.rmtree(self.venv_path)
            
            # Create new virtual environment
            result = subprocess.run([sys.executable, "-m", "venv", str(self.venv_path)], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log("Virtual environment created successfully!")
                return True
            else:
                self.log(f"Failed to create virtual environment: {result.stderr}", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"Error creating virtual environment: {str(e)}", "ERROR")
            return False
    
    def get_venv_python(self):
        """Get path to Python in virtual environment"""
        if self.system == "windows":
            return self.venv_path / "Scripts" / "python.exe"
        else:
            return self.venv_path / "bin" / "python"
    
    def get_venv_pip(self):
        """Get path to pip in virtual environment"""
        if self.system == "windows":
            return self.venv_path / "Scripts" / "pip.exe"
        else:
            return self.venv_path / "bin" / "pip"
    
    def install_dependencies(self):
        """Install all required Python dependencies"""
        self.log("Installing Python dependencies...")
        
        requirements_file = self.ai_root / "requirements.txt"
        if not requirements_file.exists():
            self.log("requirements.txt not found!", "ERROR")
            return False
        
        pip_path = self.get_venv_pip()
        
        try:
            # Upgrade pip first
            self.log("Upgrading pip...")
            subprocess.run([str(pip_path), "install", "--upgrade", "pip"], 
                          capture_output=True, check=True)
            
            # Install wheel for binary packages
            subprocess.run([str(pip_path), "install", "wheel"], 
                          capture_output=True, check=True)
            
            # Install requirements
            self.log("Installing dependencies from requirements.txt...")
            result = subprocess.run([
                str(pip_path), "install", "-r", str(requirements_file)
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log("All dependencies installed successfully!")
                return True
            else:
                self.log(f"Failed to install dependencies: {result.stderr}", "ERROR")
                
                # Try installing problematic packages individually
                self.log("Attempting to install packages individually...")
                return self.install_packages_individually()
                
        except Exception as e:
            self.log(f"Error installing dependencies: {str(e)}", "ERROR")
            return False
    
    def install_packages_individually(self):
        """Install packages one by one, skipping failures"""
        packages = [
            "tensorflow>=2.10.0",
            "numpy>=1.21.0",
            "pandas>=1.4.0",
            "scikit-learn>=1.1.0",
            "opencv-python>=4.6.0",
            "Pillow>=9.0.0",
            "matplotlib>=3.5.0",
            "seaborn>=0.11.0",
            "scipy>=1.8.0",
            "tqdm>=4.64.0",
            "joblib>=1.1.0",
            "ta>=0.10.0"
        ]
        
        pip_path = self.get_venv_pip()
        success_count = 0
        
        for package in packages:
            try:
                self.log(f"Installing {package}...")
                result = subprocess.run([
                    str(pip_path), "install", package
                ], capture_output=True, text=True, timeout=300)
                
                if result.returncode == 0:
                    success_count += 1
                    self.log(f"✓ {package} installed successfully")
                else:
                    self.log(f"✗ Failed to install {package}: {result.stderr}", "WARNING")
                    
            except subprocess.TimeoutExpired:
                self.log(f"✗ Timeout installing {package}", "WARNING")
            except Exception as e:
                self.log(f"✗ Error installing {package}: {str(e)}", "WARNING")
        
        self.log(f"Installed {success_count}/{len(packages)} packages successfully")
        return success_count > len(packages) // 2  # Success if more than half installed
    
    def verify_installation(self):
        """Verify that the installation is working correctly"""
        self.log("Verifying installation...")
        
        python_path = self.get_venv_python()
        
        test_script = """
import sys
import tensorflow as tf
import numpy as np
import pandas as pd
import cv2
import matplotlib
import ta
print("All critical packages imported successfully!")
print(f"TensorFlow version: {tf.__version__}")
print(f"NumPy version: {np.__version__}")
print(f"Pandas version: {pd.__version__}")
print(f"OpenCV version: {cv2.__version__}")
"""
        
        try:
            result = subprocess.run([
                str(python_path), "-c", test_script
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                self.log("✓ Installation verification successful!")
                self.log(result.stdout)
                return True
            else:
                self.log(f"✗ Installation verification failed: {result.stderr}", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"Error during verification: {str(e)}", "ERROR")
            return False
    
    def create_startup_scripts(self):
        """Create startup scripts for the AI system"""
        self.log("Creating startup scripts...")
        
        # Create Windows batch script
        if self.system == "windows":
            batch_script = self.ai_root / "start_ai_system.bat"
            with open(batch_script, "w") as f:
                f.write(f"""@echo off
echo Starting Advanced Crypto AI System...
cd /d "{self.ai_root}"
"{self.get_venv_python()}" ai_server.py
pause
""")
            self.log(f"Created Windows startup script: {batch_script}")
        
        # Create Unix shell script
        shell_script = self.ai_root / "start_ai_system.sh"
        with open(shell_script, "w") as f:
            f.write(f"""#!/bin/bash
echo "Starting Advanced Crypto AI System..."
cd "{self.ai_root}"
"{self.get_venv_python()}" ai_server.py
""")
        
        # Make shell script executable
        if self.system != "windows":
            os.chmod(shell_script, 0o755)
        
        self.log(f"Created Unix startup script: {shell_script}")
        
        # Create Python startup script
        startup_py = self.ai_root / "start_ai.py"
        with open(startup_py, "w") as f:
            f.write(f'''#!/usr/bin/env python3
"""
AI System Startup Script
Automatically starts the AI server with proper environment
"""
import subprocess
import sys
from pathlib import Path

def main():
    ai_root = Path(__file__).parent
    venv_python = ai_root / "venv" / {"Scripts" if sys.platform == "win32" else "bin"} / {"python.exe" if sys.platform == "win32" else "python"}
    ai_server = ai_root / "ai_server.py"
    
    print("🚀 Starting Advanced Crypto AI System...")
    
    try:
        subprocess.run([str(venv_python), str(ai_server)], cwd=ai_root)
    except KeyboardInterrupt:
        print("\\n🛑 AI System stopped by user")
    except Exception as e:
        print(f"❌ Error starting AI system: {{e}}")
        sys.exit(1)

if __name__ == "__main__":
    main()
''')
        
        self.log(f"Created Python startup script: {startup_py}")
        
        return True
    
    def create_config_file(self):
        """Create configuration file for the AI system"""
        config = {
            "python_path": str(self.get_venv_python()),
            "ai_root": str(self.ai_root),
            "venv_path": str(self.venv_path),
            "system": self.system,
            "setup_completed": True,
            "setup_timestamp": str(__import__("datetime").datetime.now()),
            "server_port": 8888,
            "server_host": "localhost",
            "auto_start": True
        }
        
        config_file = self.ai_root / "config.json"
        with open(config_file, "w") as f:
            json.dump(config, f, indent=2)
        
        self.log(f"Created configuration file: {config_file}")
        return True
    
    def setup(self):
        """Main setup method that orchestrates the entire process"""
        self.log("🚀 Starting Advanced Crypto AI Environment Setup...")
        self.log(f"System: {self.system} ({self.architecture})")
        self.log(f"Project root: {self.project_root}")
        self.log(f"AI root: {self.ai_root}")
        
        # Check if Python is already installed
        python_installed, version = self.check_python_installed()
        
        if not python_installed:
            self.log("Python not found. Installing Python...")
            
            if self.system == "windows":
                if not self.install_python_windows():
                    return False
            elif self.system == "linux":
                if not self.install_python_linux():
                    return False
            elif self.system == "darwin":
                if not self.install_python_macos():
                    return False
            else:
                self.log(f"Unsupported system: {self.system}", "ERROR")
                return False
        else:
            self.log("Python is already installed")
        
        # Create virtual environment
        if not self.create_virtual_environment():
            return False
        
        # Install dependencies
        if not self.install_dependencies():
            return False
        
        # Verify installation
        if not self.verify_installation():
            return False
        
        # Create startup scripts
        if not self.create_startup_scripts():
            return False
        
        # Create configuration file
        if not self.create_config_file():
            return False
        
        self.log("🎉 Advanced Crypto AI Environment Setup Completed Successfully!")
        self.log("📋 Next steps:")
        self.log("   1. Run 'python train_advanced_model.py' to train the AI model")
        self.log("   2. Run 'python ai_server.py' to start the AI server")
        self.log("   3. Launch your Android app to connect to the AI system")
        
        return True

def main():
    setup = PythonEnvironmentSetup()
    
    try:
        success = setup.setup()
        if success:
            print("\n✅ Setup completed successfully!")
            sys.exit(0)
        else:
            print("\n❌ Setup failed!")
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n🛑 Setup interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Unexpected error during setup: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
