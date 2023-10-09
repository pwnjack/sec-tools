## SysDig: Multi-Host Reconnaissance Tool

SysDig is a powerful tool for conducting reconnaissance on multiple hosts. It offers features such as encryption for secure data transfer and optional keyword search capabilities.

### Features

- **Multi-Host Reconnaissance**: Easily target and gather information from multiple hosts.
- **Encryption**: Keep sensitive data secure with robust encryption.
- **Keyword Search**: Optionally, perform in-depth searches for specific keywords.

### Getting Started

1. Clone the repository.
2. Open `sysdig.sh` in your preferred text editor.
3. Adjust the following variables to suit your needs:

   - `hosts`: List of target hosts.
   - `ssh_key`: Path to your SSH key file.
   - `log_file`: Path for recording script events.

4. Save the file.

### Configuration

When you run the script, you will be prompted for the following information:

- **Cipher Key**: Enter your encryption key.
- **Confirm Cipher Key**: Confirm your encryption key.
- **Server Information**: Provide the server details in the format `user@your_server:/path/to/save/`.
- **Initiate Keyword Search?**: Answer with `true` or `false` to enable or disable keyword search.
- **Keyword for Search**: If enabled, enter the keyword.

### Usage

- Execute the script.
- Observe the script in action.
- Retrieve your gathered information securely.
