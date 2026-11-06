#!/usr/bin/env bash
# Shared settings for the DNA ML platform scripts.
# Change the group names here if the identity team used a different naming convention.

export DNA_LOCATION="${DNA_LOCATION:-southafricanorth}"

# Entra security group display names (requested from the identity team, see docs/identity-team-request.md)
export DNA_GROUP_NAME_PLATFORM_ADMINS="${DNA_GROUP_NAME_PLATFORM_ADMINS:-sg-dna-platform-admins}"
export DNA_GROUP_NAME_DATA_ENGINEERS="${DNA_GROUP_NAME_DATA_ENGINEERS:-sg-dna-data-engineers}"
export DNA_GROUP_NAME_DATA_SCIENTISTS="${DNA_GROUP_NAME_DATA_SCIENTISTS:-sg-dna-data-scientists}"
export DNA_GROUP_NAME_ML_ENGINEERS="${DNA_GROUP_NAME_ML_ENGINEERS:-sg-dna-ml-engineers}"
export DNA_GROUP_NAME_GENAI_DEVELOPERS="${DNA_GROUP_NAME_GENAI_DEVELOPERS:-sg-dna-genai-developers}"
export DNA_GROUP_NAME_VIEWERS="${DNA_GROUP_NAME_VIEWERS:-sg-dna-viewers}"
