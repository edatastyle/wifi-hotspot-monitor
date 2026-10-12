# Contributing to Wi-Fi Hotspot Monitor

Thank you for your interest in contributing to **Wi-Fi Hotspot Monitor**! Contributions are welcome, including bug fixes, feature requests, documentation improvements, security enhancements, and code contributions.

Please review these guidelines before contributing.

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Development Setup](#development-setup)
- [Code Guidelines](#code-guidelines)
- [Testing](#testing)
- [Pull Requests](#pull-requests)
- [Security and Privacy](#security-and-privacy)
- [Community Guidelines](#community-guidelines)
- [License](#license)

## Ways to Contribute

You can contribute by:

- Fixing bugs and improving existing functionality.
- Enhancing hotspot management and connected-device monitoring.
- Improving device access control and website filtering.
- Improving the dashboard, API, and user experience.
- Strengthening authentication, validation, and system security.
- Improving installation instructions and documentation.
- Testing compatibility with Linux distributions and Wi-Fi adapters.

For significant changes, please open an issue first to discuss your proposed solution.

## Reporting Bugs

Before reporting a bug, check the [existing issues](https://github.com/edatastyle/wifi-hotspot-monitor/issues) to avoid duplicates.

Include the following information in your report:

- A clear description of the problem.
- Steps to reproduce the issue.
- Expected and actual behavior.
- Linux distribution and version.
- Relevant PHP, Python, and dependency versions.
- Wi-Fi adapter details, if relevant.
- Error messages or sanitized logs.

Useful diagnostic commands include:

```bash
nmcli device status
nmcli connection show --active
iw list | grep -A8 "Supported interface modes"
php -v
python3 --version
```

Remove passwords, access tokens, and other sensitive information before sharing logs.

## Suggesting Features

Feature requests should explain:

1. The problem the feature would solve.
2. Your proposed solution.
3. The expected benefits.
4. Any relevant alternatives or implementation details.
5. Potential security, privacy, and compatibility considerations.

Keep proposals focused on improving the reliability, usability, and security of Wi-Fi Hotspot Monitor.

## Development Setup

### Prerequisites

Depending on the component being modified, you may need:

- Linux with NetworkManager.
- Git.
- PHP CLI.
- Python 3.
- Wi-Fi hardware that supports access point mode.
- Networking utilities such as `nmcli`, `iw`, `iptables`, and `dnsmasq`.
- Appropriate permissions for networking integration tests.

### Clone the Repository

```bash
git clone https://github.com/edatastyle/wifi-hotspot-monitor.git
cd wifi-hotspot-monitor
```

Read the [README.md](README.md) for project-specific installation and configuration instructions.

**Important:** Installation scripts may install packages or modify network configuration. Review scripts before execution and use a dedicated test environment whenever possible.

### Create a Branch

Create a separate branch for your changes:

```bash
git checkout -b fix/short-description
```

Examples:

```bash
git checkout -b fix/hotspot-startup
git checkout -b feature/device-management
git checkout -b docs/installation-guide
```

## Code Guidelines

### General

- Keep changes focused and easy to review.
- Follow the existing project structure and coding conventions.
- Use descriptive names and add comments where they improve clarity.
- Avoid unnecessary dependencies and unrelated refactoring.
- Update documentation when behavior or configuration changes.
- Do not commit generated files, private configuration, credentials, or logs containing sensitive information.

### PHP

- Validate and sanitize user input.
- Escape output appropriately to prevent cross-site scripting (XSS).
- Use parameterized database queries where applicable.
- Check authentication and authorization for protected actions and API endpoints.
- Handle errors without exposing sensitive system information.

### Python

- Follow [PEP 8](https://peps.python.org/pep-0008/) where practical.
- Use clear function and variable names.
- Handle exceptions appropriately.
- Validate external input and check subprocess results.
- Avoid unsafe command construction, especially when handling untrusted input.

### Shell Scripts

- Quote variables appropriately.
- Check command exit statuses and handle failures.
- Validate input before using it in system commands.
- Avoid destructive operations without safeguards.
- Preserve existing system configuration unless changes are necessary.
- Provide clear error messages.

### Frontend and API

- Keep the interface responsive and accessible.
- Validate API input on the server.
- Return appropriate HTTP status codes and predictable responses.
- Protect state-changing requests against unauthorized access and CSRF where applicable.
- Avoid exposing sensitive device or system information to unauthorized users.

## Testing

Before submitting changes, run the relevant checks and verify that existing functionality remains intact.

Depending on your changes, test:

- Installation and configuration.
- Hotspot startup, shutdown, and restart.
- Network connectivity.
- Connected-device detection.
- Device access-control operations.
- Website filtering and DNS logging.
- Dashboard authentication and API authorization.
- Error handling and invalid input.

### PHP Syntax

```bash
find hotspot-manager -name '*.php' -print0 |
  xargs -0 -r -n1 php -l
```

### Python Syntax

```bash
python3 -m py_compile hotspot-manager/agent/hsagent.py
```

### Shell Syntax

Run the following checks for the scripts you modify:

```bash
bash -n setup.sh
bash -n hotspot-manager/run.sh
```

For additional shell scripts, run `bash -n` against their actual paths.

These commands are examples; adjust paths to match the current repository structure and the files you changed.

If you cannot test a change on real hardware, explain which checks were completed and which remain untested.

## Pull Requests

When your changes are ready:

1. Review your changes and remove unrelated modifications.
2. Check that no credentials or sensitive information are included.
3. Run the relevant tests.
4. Update documentation when necessary.
5. Commit your changes with a descriptive message.
6. Open a pull request against the repository's `main` branch.

Example:

```bash
git add .
git commit -m "Fix hotspot startup handling"
git push origin fix/hotspot-startup
```

Include the following in your pull request:

- **Summary:** What changed and why.
- **Related issue:** Link to an existing issue, if applicable.
- **Implementation:** Important technical details.
- **Testing:** Checks performed and their results.
- **Compatibility:** Any configuration changes or potential regressions.
- **Screenshots:** For relevant dashboard or interface changes.

Keep pull requests focused and explain any significant design decisions. Maintainers may request revisions before accepting a contribution.

## Security and Privacy

Because this project interacts with network interfaces, DNS filtering, firewall rules, connected devices, and potentially privileged operations, security must be considered in every contribution.

- Use the software only on networks you own or are authorized to administer.
- Respect user consent when monitoring or filtering network activity.
- Collect only the data necessary for the intended functionality.
- Never hardcode credentials or weaken authentication.
- Apply the principle of least privilege.
- Avoid logging passwords, tokens, or other secrets.
- Do not introduce covert monitoring or unauthorized traffic interception.

**Do not report exploitable vulnerabilities publicly.** Use the repository's available private security reporting options or contact the maintainer through an established private channel.

Include the affected component, potential impact, reproduction steps, and possible mitigation when reporting a vulnerability.

## Community Guidelines

Please help maintain a respectful and collaborative environment.

- Be professional and constructive.
- Welcome contributors of different experience levels.
- Focus feedback on the code and ideas, not individuals.
- Accept constructive feedback.
- Avoid harassment, personal attacks, spam, and unrelated discussions.

## License

By contributing to this project, you agree that your contributions will be distributed under the terms of the project's existing [MIT License](LICENSE), where applicable.

Thank you for helping improve Wi-Fi Hotspot Monitor!

**Repository:** https://github.com/edatastyle/wifi-hotspot-monitor
