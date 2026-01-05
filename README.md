# Admin-Commands
Truthordeys roblox admin commands
# Roblox Admin Command & Global Announcement System

This repository contains a secure, server-side admin system designed for Roblox experiences. It provides controlled admin commands and a cross-server global announcement feature using Roblox services.

## Overview

The system ensures that all administrative actions are executed on the server, with strict permission checks and input validation to prevent abuse or exploitation. It also includes a global admin-only announcement command that synchronizes messages across all live servers of the same experience.

## Admin Permissions

Admins are defined using a username-based allowlist. All admin checks are performed server-side, and usernames are normalized to ensure consistent validation.

Only approved admins are able to:
- Execute moderation commands
- Modify player statistics
- Send global announcements across servers

## Admin Commands

The system listens for secure RemoteEvent calls and supports the following commands:

- Kick  
  Removes a target player from the server with an admin-defined reason.

- GiveTrophies  
  Safely adds trophies to a player’s leaderstats value with overflow protection.

- SetCoins  
  Sets a player’s coin value using sanitized numeric input.

- SetWinStreak  
  Updates a player’s win streak value with server-side validation.

All numeric inputs are sanitized to prevent invalid values, overflows, or negative numbers.

## Global Admin Announcement System

Admins can send announcements using a chat-based command:

/global <message>

This feature uses Roblox MessagingService to broadcast messages across all active servers of the same experience.

Key protections include:
- Message filtering using TextService
- Message length limits
- Per-admin cooldowns
- Duplicate message prevention using unique identifiers

Announcements are delivered instantly to the originating server and propagated safely to other servers.

## Security and Validation

The system includes multiple layers of safety:
- Server-authoritative logic only
- Admin verification before every action
- Text filtering for all broadcast messages
- Rate limiting to prevent spam
- Duplicate message detection across servers
- Integer sanitization to prevent invalid stat manipulation

## Required Setup

The following instances must exist in ReplicatedStorage:
- AdminCommand (RemoteEvent)
- GlobalAnnouncementEvent (RemoteEvent)

Leaderstats values must exist on the target player for stat-based commands to function.

## Architecture Notes

The script is intended to run inside ServerScriptService.  
It is modular and can be extended with additional admin commands or moderation features without altering the core security model.

## Use Case

This system is suitable for competitive or live-service Roblox games that require:
- Reliable moderation tools
- Cross-server admin communication
- Secure stat manipulation
- Exploit-resistant server logic
