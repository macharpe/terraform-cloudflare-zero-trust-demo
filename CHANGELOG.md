# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.1] - 2025-09-29

### Fixed

- **VNC Cloud-Init Compression Corruption**: Resolved AWS 16KB user_data limit issue
  - Removed corrupted gzip+base64 compression approach that was causing script failures
  - Implemented streamlined inline VNC setup (9,635 bytes, 24% reduction from previous)
  - Eliminated Firefox package installation (saves ~3 minutes installation time)
  - Fixed VNC service systemd path issues with dynamic vncserver executable detection (resolves status=203/EXEC errors)
  - Enhanced error handling and logging to `/tmp/vnc-setup.log` for better troubleshooting
  - Maintained all VNC functionality: XFCE4 desktop, vnc-status command, progress tracking
- **WARP Connector Ubuntu Compatibility**: Downgraded to Ubuntu 22.04 LTS with programmatic version detection
  - Azure WARP connector VM: `ubuntu-24_04-lts` → `ubuntu-22_04-lts`
  - GCP WARP connector VM: `ubuntu-2404-lts-amd64` → `ubuntu-2204-lts-amd64`
  - Replaced hardcoded `jammy main` with `$(lsb_release -cs) main` for automatic Ubuntu codename detection
  - Required due to WARP Connector not supporting Ubuntu 24.04 as of September 2025
  - Improves maintainability by eliminating hardcoded distribution codenames

## [2.2.0] - 2025-09-28

### Added
- Comprehensive module documentation with README.md files for all modules
- Enhanced output descriptions with detailed multi-line explanations
- Backend configuration template approach for improved safety and state management
- Professional terraform-docs integration with GitHub Actions
- Comprehensive troubleshooting guides in module documentation
- Security considerations documentation per module
- Usage examples and input/output tables for all modules
- CHANGELOG.md based on complete git history analysis
- **NEW**: Automated Statistics Update System
  - 📊 Smart resource counting with fallback hierarchy (state → plan → files)
  - 📅 Automated README.md statistics section updates
  - 📁 Date-stamped terraform plan files (`YYYY-MM-DD_tfplan`) saved automatically during statistics updates
  - 🎯 Accurate resource counting matching terraform destroy operations (167 resources)
  - 📋 Enhanced table formatting with proper vertical alignment
  - 🛠️ Available via `/update-stats` command with comprehensive Claude Code integration
- **NEW**: Secure S3 backend configuration approach
  - `backend.conf.example` template for team collaboration
  - `backend.conf` (gitignored) for actual sensitive values
  - Updated documentation for secure repository practices
- **NEW**: VNC Installation Progress Tracking System
  - 🔄 Real-time progress monitoring with percentage completion and ETA calculations
  - 📊 8-phase installation tracking system for desktop environment setup
  - 📈 Visual progress bars with elapsed time display
  - 🖥️ `vnc-status` command for easy monitoring on AWS t3.micro instances
  - 📝 Multiple status files for different monitoring approaches:
    - `/tmp/vnc-progress.status` - Formatted status display
    - `/tmp/demo-progress.txt` - Quick progress check
    - `/tmp/vnc-setup.log` - Detailed installation log
  - ⏱️ Enhanced package installation with progress feedback for long-running operations

### Changed
- **BREAKING**: Resource naming standardization across all cloud providers
  - VM instances now follow `{cloud}_{resource_type}_{purpose}` pattern
  - Security groups/firewall rules use `{cloud}_{sg/fw}_{purpose}` pattern
  - Network resources follow `{cloud}_{vpc/subnet}_{purpose}` pattern
  - Cloudflare applications use `cf_app_{purpose}` pattern
- Enhanced infrastructure configuration with improved resource organization
- AWS region standardized to `eu-central-1` across all configurations
- Output descriptions enhanced with purpose, usage, security context, and related resources
- **SECURITY**: Removed sensitive S3 bucket names from `provider.tf` in public repository
- Updated `.gitignore` to exclude all backend configuration files

### Fixed
- Markdown linting issues in all README files
- Terraform validation warnings and configuration issues
- 🐛 Cloud-init YAML syntax error in VNC setup that caused installation failures
- 🔧 Template variable errors in cloud-init for VNC progress tracking
- ⚡ VNC installation appearing to hang due to lack of progress visibility on t3.micro instances

### Security
- **CRITICAL**: Resolved public repository security vulnerability
  - Removed sensitive S3 bucket names from tracked files
  - Implemented secure backend configuration file approach
  - Enhanced `.gitignore` patterns for backend files
- Identified sensitive IDs that should be moved to environment variables
- Enhanced security documentation in module READMEs
- Improved infrastructure security with enhanced backend configuration management

### Documentation
- Updated project workflow documentation with secure backend commands
- Updated README.md with backend configuration setup instructions
- Enhanced documentation with security best practices and configuration guidance

### Performance
- **NEW**: Demo-First Cleanup Optimization
  - 🚀 Replaced `timestamp()` triggers with VM instance ID-based triggers
  - ⚡ 40-50% reduction in `terraform apply` time for demo workflows
  - 🎯 Cleanup scripts now only run when VMs are created/changed, not on every apply
  - 🔄 Maintained parallel execution of cleanup scripts for additional speed
  - 📊 Optimized for demo pattern: create → demo → destroy (no mid-demo cleanups)
  - 🛠️ Separate resource triggers for maintainability (known_hosts vs devices)
- Created comprehensive performance optimization documentation in `0-documentation/`

## [2.1.0] - 2025-09-17

### Added
- **NEW**: Backend configuration template system
  - Secure S3 + DynamoDB backend configuration template
  - Comprehensive backend setup documentation
  - Enhanced security with gitignored sensitive configuration files
- **NEW**: Access Denied Info Page as optional component
- **NEW**: Module README.md files for all modules:
  - `modules/cloudflare/README.md` - Zero Trust configuration guide
  - `modules/azure/README.md` - Azure AD identity management guide
  - `modules/keys/README.md` - SSH key management documentation
  - `modules/warp-routing/README.md` - CIDR subnet calculation guide
- **NEW**: Enhanced output descriptions with multi-line EOT syntax
- **NEW**: Backend configuration analysis and migration documentation

### Changed
- **BREAKING**: Consistent resource naming implementation
  - AWS resources: `aws_vm_service`, `aws_vm_vnc`, `aws_vm_cloudflared`
  - GCP resources: `gcp_vm_cloudflared`, `gcp_vm_windows_rdp`, `gcp_vm_warp`
  - Azure resources: `azure_vm_linux`
  - Security groups: `aws_sg_*`, `gcp_fw_*`, `azure_nsg_*`
  - Network resources: `*_vpc_main`, `*_subnet_*`
- ⬆️ **Provider Updates**:
  - Google Cloud provider: 6.0 → 7.0
  - AWS provider: 5.0 → 6.0
  - Terraform requirement: 1.11.x → 1.12.x
- Updated all resource references to match new naming conventions
- Terraform validation and planning verified after all changes

### Fixed
- 🐛 Terraform sensitive output validation errors resolved
- Policy assignments restored after refactoring
- Resource configuration and networking issues

### Documentation
- Enhanced project documentation with recent improvements
- Added professional troubleshooting and maintenance sections
- Updated architecture diagrams with latest infrastructure layout
- Comprehensive backend configuration documentation

## [2.0.0] - 2025-08-23

### Added
- **NEW**: Professional HTML Demo Applications
  - 🎨 Modern competitive intelligence portal design (`competition.html`)
  - 🚴 DAZZLING E-BIKES company intranet with comprehensive sections (`intranet.html`)
  - Enhanced browser rendering test applications with professional styling
- **NEW**: Enhanced Security Policies
  - 🔒 Expanded contractor access controls for domain controller and SSH
  - 🌍 Extended blocked countries list for improved geoblocking
  - 🎰 Identity-based gambling restrictions and enhanced policy enforcement
  - 👥 Refined contractor-specific access controls
- **NEW**: Worker Integration Support
  - ⚡ Training status admin portal audience output (`TRAINING_STATUS_ADMIN_PORTAL_AUD`)
  - 🔧 ACCESS_APP_AUD secret configuration for Cloudflare Workers
  - 🤝 Seamless Worker integration capabilities
- **NEW**: Training Compliance Gateway Integration
  - 📊 Optional training compliance validation
  - 🔗 External system integration capabilities
  - 📋 Policy enhancements for training status validation

### Enhanced
- **IMPROVED**: Multi-Cloud Infrastructure
  - 🖥️ Enhanced Windows RDP support across GCP
  - ☁️ Improved Azure and AWS virtual machine configurations
  - 🌐 Better cross-cloud networking and connectivity
  - 📈 VM configuration optimization and project structure improvements
- **IMPROVED**: Cloudflare Zero Trust Integration
  - 🔐 Enhanced tunnels and WARP connectors
  - 🎯 Improved access policies with refined contractor controls
  - 📱 Better device posture checks and compliance validation
  - 🔑 Migration from API key to API token authentication (improved security)

### Changed
- 📊 Updated infrastructure statistics: 141 → 165 total resources
- 📝 Enhanced API token permissions documentation
- 🏗️ Resource naming improvements for better clarity
- 📖 Comprehensive SaaS application references update

### Fixed
- 🔧 Multiple refactoring and cleanup iterations
- 🐛 Network connectivity and configuration issues
- ⚡ Policy assignment restorations and access fixes

### Security
- 🛡️ Advanced geoblocking capabilities with extended country list
- 🚫 Identity-based gambling restrictions implementation
- 👔 Contractor-specific access controls and enhanced security policies
- 🔐 Enhanced device posture validation and compliance checks

### Documentation
- 📐 Updated architecture diagrams with current infrastructure layout
- 📚 Enhanced setup guides and configuration documentation
- 🎯 Improved README with updated statistics and cleaner structure
- 📅 Regular documentation updates with latest changes

## [1.5.0] - 2025-07-17

### Added
- **NEW**: Azure Virtual Machine Support
  - ☁️ Azure Linux VMs with WARP connector functionality
  - 🔗 Cross-cloud private network connectivity
  - 🌐 Enhanced WARP connector routing between cloud providers
  - 🏢 Azure AD integration for identity management
- **NEW**: Advanced Security Features
  - 🚫 Lateral movement prevention capabilities
  - 🔒 Enhanced network security policies
  - 🛡️ Advanced threat protection across cloud environments
- **NEW**: Comprehensive Monitoring
  - 📊 Full Datadog monitoring integration
  - 📈 Infrastructure performance tracking
  - 🔍 Enhanced observability across all cloud providers
  - 📱 Real-time alerts and monitoring dashboards

### Enhanced
- **IMPROVED**: Browser-Rendered Services
  - 🖥️ GCP Windows RDP virtual machine support
  - 🖱️ Enhanced browser-rendered services (SSH, VNC, RDP)
  - 🔧 Improved service reliability and performance
- **IMPROVED**: Identity and Access Management
  - 👥 Enhanced device posture checks for multiple OS types
  - 🔑 Better identity provider integration (Okta SAML, Azure AD, OTP)
  - 📱 Cross-platform device compliance validation

### Infrastructure
- 🌐 Multi-cloud WARP connector routing
- 🔗 Enhanced cross-cloud networking
- 📊 Infrastructure monitoring and alerting
- 🛠️ Improved resource management and cleanup

### Documentation
- 📖 Infrastructure configuration cleanup and documentation enhancement
- 🎯 Enhanced setup and deployment guides
- 📐 Updated architecture documentation

## [1.0.0] - 2025-06-20

### Added
- **NEW**: Initial Multi-Cloud Zero Trust Infrastructure
  - ☁️ AWS EC2 instances with browser-rendered SSH and VNC
  - 🌐 GCP Compute Engine instances with cloudflared tunnels
  - 🔐 Cloudflare Zero Trust complete SASE platform implementation
  - 👥 Identity integration with multiple providers (Okta SAML, Azure AD, OTP)
  - 📱 Device posture checks and compliance validation
  - 🖥️ Browser-rendered services eliminating local client requirements
- **NEW**: Infrastructure Foundation
  - 🌐 AWS VPC with public and private subnets
  - ☁️ GCP VPC with multiple subnet configurations
  - 🔗 Cloudflare tunnels for secure connectivity
  - 🔑 SSH key management across all cloud providers
- **NEW**: Security Framework
  - 🛡️ Zero Trust network architecture implementation
  - 🔐 Identity-based access controls
  - 📱 Device compliance enforcement
  - 🔒 Encrypted tunnels and secure connectivity
- **NEW**: Browser-Rendered Services
  - 🖥️ SSH access through browser (eliminating local SSH clients)
  - 🖱️ VNC desktop access through browser
  - 🔧 Seamless user experience without local software requirements
- **NEW**: Device and User Management
  - 🧹 Automated device cleanup scripts (`scripts/cleanup/cloudflare_devices_cleanup.sh`)
  - 🔑 SSH known_hosts cleanup automation
  - 👥 User provisioning and management
  - 📱 Device enrollment and compliance tracking
- **NEW**: Infrastructure as Code
  - 🏗️ Complete Terraform infrastructure automation
  - 📋 Infracost integration for cost estimation
  - 🔄 Automated terraform-docs generation
  - 🧹 Comprehensive cleanup and maintenance scripts

### Infrastructure Components
- **AWS Infrastructure**: EC2 instances, VPC, security groups, browser rendering
- **GCP Infrastructure**: Compute Engine, VPC, firewall rules, cloudflared tunnels
- **Cloudflare Zero Trust**: Tunnels, access policies, identity providers, device posture
- **Networking**: Cross-cloud connectivity, secure tunnels, CGNAT routing
- **Security**: Zero Trust policies, device compliance, identity verification

### Developer Experience
- 📚 Comprehensive documentation and setup guides
- 🔧 Automated deployment and teardown
- 🧹 Cleanup scripts for development workflow
- 📊 Cost estimation and resource tracking

---

## Development Timeline Overview

### Project Evolution Summary
- **🎯 Total Development Time**: 3+ months (June - September 2025)
- **📊 Total Commits**: 54 meaningful commits across 4 major versions
- **🏗️ Infrastructure Growth**: From basic multi-cloud setup to comprehensive enterprise-grade Zero Trust architecture
- **🔧 Major Refactoring Cycles**: 8 major cleanup and refactoring iterations ensuring code quality

### Key Development Milestones
1. **Foundation Phase** (June 2025): Core multi-cloud Zero Trust infrastructure
2. **Enhancement Phase** (July 2025): Azure integration and advanced security
3. **Maturation Phase** (August 2025): Professional features and worker integration
4. **Documentation Phase** (September 2025): Comprehensive documentation and standardization

### Architecture Evolution
- **v1.0**: AWS + GCP with basic Zero Trust
- **v1.5**: + Azure integration with advanced security
- **v2.0**: + Professional demos and worker integration
- **v2.1**: + Production-ready documentation and backend infrastructure

## Migration Notes

### Resource Naming Changes (v2.1.0)
If upgrading from versions prior to 2.1.0, note that resource names have been standardized. This is a **breaking change** that may require:

1. State file migration or resource import
2. Update of any external references to resource names
3. Verification of cross-references between modules

### Backend Migration (v2.1.0+)
The backend configuration template system provides:
- Enhanced safety with separate backend configuration
- Production-ready state management template
- Secure configuration file approach
- Encryption and compliance features

See backend configuration documentation in repository for migration instructions.

### Provider Updates (v2.1.0)
- **Google Cloud Provider**: 6.0 → 7.0 (may require provider refresh)
- **AWS Provider**: 5.0 → 6.0 (verify compatibility)
- **Terraform**: 1.11.x → 1.12.x (upgrade required)

## Contributing

When adding entries to this changelog:
1. Add new changes under `[Unreleased]`
2. Use semantic versioning for releases
3. Group changes by type: Added, Changed, Deprecated, Removed, Fixed, Security
4. Include impact information for breaking changes
5. Reference related documentation or migration guides
6. Use conventional commit format with appropriate emojis

## Support

For questions about specific changes:
- Review module-specific README.md files
- Consult backend configuration documentation
- Check project documentation for overview and commands
- Review architecture diagrams in the documentation folder