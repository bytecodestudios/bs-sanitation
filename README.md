# Sanitation Group Job

A FiveM sanitation job resource built for party-based work flow with a Snappy Phone style job system integration.

## Overview

This resource provides a legal trash collection job where a party leader can request work, rent a sanitation vehicle, collect trash from a designated zone, and return the vehicle for payment. The resource is designed to work with party/job registration systems and can be extended through shared configuration.

## Features

- Party-based job assignment and task tracking
- Vehicle rental and return flow for sanitation work
- Trash collection in configured job zones
- Dynamic payout and optional reward drops
- Optional XP integration
- Framework and inventory abstraction support

## Requirements

- `ox_lib`
- A supported party/job resource such as `snappy-phone` or `cad-groupsystem`
- A compatible framework setup for your server
- Optional integrations for vehicle keys, job XP, and ped spawning depending on your environment

## Main Configuration

The primary job settings are stored in:

- `shared/job.lua`
- `shared/party.lua`

These files control zones, vehicle model handling, payout ranges, party size, job metadata, and spawn points.

## Typical Flow

1. Speak to the sanitation NPC.
2. Request the sanitation job from the party leader.
3. Rent the trash vehicle.
4. Drive to the assigned pickup zone.
5. Collect the required trash bags.
6. Return to the HQ and collect payment.

## Notes

This resource is intended to be used as a job module within a larger server ecosystem. Keep the shared config aligned with your framework, inventory, and party system so the job behaves correctly in production.

