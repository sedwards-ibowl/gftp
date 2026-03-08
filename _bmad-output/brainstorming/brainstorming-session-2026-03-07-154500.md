---
stepsCompleted: [1, 2]
inputDocuments: []
session_topic: 'Implementation of SMB/CIFS protocol support using native macOS libraries (AppKit/Foundation/NetFS/etc.)'
session_goals: 'Discovery of connection and authentication APIs; Mapping of filesystem operation APIs (read/write/list/delete) to gFTP''s protocol structure; Ensuring zero regressions through seamless framework integration.'
selected_approach: 'AI-Recommended Techniques'
techniques_used: ['Constraint Mapping', 'Morphological Analysis', 'Trait Transfer']
ideas_generated: []
context_file: ''
---

# Brainstorming Session Results

**Facilitator:** Sedwards
**Date:** 2026-03-07

## Session Overview

**Topic:** Implementation of SMB/CIFS protocol support using native macOS libraries (AppKit/Foundation/NetFS/etc.)
**Goals:** Discovery of connection and authentication APIs; Mapping of filesystem operation APIs (read/write/list/delete) to gFTP's protocol structure; Ensuring zero regressions through seamless framework integration.

### Session Setup

We are focusing on adding native Windows/Samba (CIFS/SMB) support to gFTP on macOS. The goal is to identify the correct macOS APIs for authentication and bi-directional transfers while maintaining the integrity of the existing gFTP framework.

## Technique Selection

**Approach:** AI-Recommended Techniques
**Analysis Context:** Implementation of SMB/CIFS protocol support using native macOS libraries (AppKit/Foundation/NetFS/etc.) with focus on Discovery of connection and authentication APIs; Mapping of filesystem operation APIs (read/write/list/delete) to gFTP's protocol structure; Ensuring zero regressions through seamless framework integration.

**Recommended Techniques:**

- **Constraint Mapping (deep):** Mapping out strict technical requirements (macOS native, C/ObjC integration, zero regressions) to ensure "safe" API territories.
- **Morphological Analysis (deep):** Systematically mapping gFTP's protocol requirements (Auth, Connect, List, Read, Write) to specific macOS API options (NetFS, NSURL, SMBClient.framework, etc.).
- **Trait Transfer (structured):** Borrowing attributes from existing gFTP protocols (FTP, SSH) to ensure the new SMB implementation feels "gFTP-native".

**AI Rationale:** This sequence moves from defining boundaries (Constraint Mapping) to broad exploration (Morphological Analysis) and finally to architectural alignment (Trait Transfer), ensuring a robust and consistent implementation strategy.

## Technique Execution Results

**Constraint Mapping (deep):**

- **Interactive Focus:** Mapping "Hard Rules" for gFTP protocol modernization vs. legacy maintenance.
- **Key Breakthroughs:** 
    - Decided on a "Plugin Isolation Layer" to firewall the new SMB protocol from legacy UI/GDK deprecations.
    - Identified that gFTP's stability is high, but maintainability is the primary risk (API Rot).
    - Selected **Option 1 (System-Managed/NetFS Mount Path)** as the preferred architectural direction for transparent macOS integration.

### Captured Ideas

**[Category #1]**: Protocol Isolation Layer
_Concept_: Create a strict C-API boundary for the SMB protocol that wraps all Objective-C and macOS native calls. This allows the SMB protocol to act as a standalone module (a "black box") that can be plugged into the legacy gFTP core.
_Novelty_: Establishes a template for future protocols, ensuring macOS and Linux ports can share a common interface while using native backends.

**[Category #1]**: API Rot Mitigation (Firewalling)
_Concept_: Decouple the protocol logic entirely from the UI's deprecated GDK/GTK state. The protocol should only communicate through a "skinny" C-interface that returns raw data and lets the legacy UI layer handle display.
_Novelty_: Transforms the protocol into a "pure data provider," immune to future UI-level breakage during GTK modernization.

**[Category #2]**: The "Identity-Aware" Bridge
_Concept_: Utilize `NSURLCredential` and `NSURLCredentialStorage` to bridge g_ftp's raw user/password strings into the macOS Keychain-aware ecosystem.
_Novelty_: Lets macOS handle the NTLM/Kerberos negotiation for various hosts (AD, Samba, Windows) while gFTP remains a simple "key provider."

**[Category #2]**: NetFS "Transparent Mount" Strategy
_Concept_: Use the `NetFS` framework (`NetFSMountURLSync`) to mount SMB shares at the OS level. gFTP then treats the "remote" connection as a specialized local filesystem view on the mount point.
_Novelty_: Provides the most robust, "zero regression" path by letting the macOS kernel manage the complex SMB state, while gFTP focuses on the dual-pane UI.

## Overall Creative Journey

We've successfully pivoted from a "how do we fix gFTP's legacy code" discussion into a "how do we build a modern future-proof protocol bridge" strategy. The decision to use the NetFS mount path provides the highest probability of success with minimal technical debt.

### Refined Execution Plan (Final)

1.  **Protocol Layer**: Implement the protocol as an Objective-C wrapper that acts as a standalone "Plugin" to gFTP.
2.  **Connection Logic**: Use `NetFSMountURLSync` with the `openOptions` dictionary for username/password.
3.  **UI Feedback**: Display a "Connecting..." dialog during the mount attempt.
4.  **Timeout Policy**: Implement a 10-second watchdog timer for the mount call to prevent permanent UI hangs.
5.  **Data Operations**: Once mounted, use `NSFileManager` and `NSURL` APIs to perform file operations on the local mount point, effectively mapping "Remote SMB" to a "Specialized Localfs" view.

